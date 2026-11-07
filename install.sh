#!/usr/bin/env bash
# Sets up a Mac or a Linux box (such as a UBVM) from this repo.
# Safe to run again: it skips what is already done.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf '\n==> %s\n' "$*"; }

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    echo "  backed up existing $dest"
  fi
  ln -sfn "$src" "$dest"
  echo "  $dest -> $src"
}

clone_once() {
  [[ -d "$2" ]] || git clone --depth 1 "https://github.com/$1" "$2"
}

# --------------------------------------------------------------------------
# Tools: Homebrew on the Mac, standalone downloads on Linux (no sudo needed)
# --------------------------------------------------------------------------
mac_tools() {
  step "Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      echo "Homebrew is not installed. It needs admin rights once:"
      echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      echo "Then run ./install.sh again."
      exit 1
    fi
  fi
  brew bundle --file "$DOTFILES/Brewfile"
}

BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"

# GitHub allows 60 API calls an hour without a token, and a shared VM IP runs out
# fast (curl: 403). With GITHUB_TOKEN set, or gh logged in, the limit is 5000.
gh_api() {
  local token="${GITHUB_TOKEN:-}"
  [[ -z "$token" ]] && command -v gh >/dev/null 2>&1 && token="$(gh auth token 2>/dev/null || true)"
  if [[ -n "$token" ]]; then
    curl -fsSL -H "Authorization: Bearer $token" "https://api.github.com/$1"
  else
    curl -fsSL "https://api.github.com/$1"
  fi
}

asset_url() {
  local json
  if ! json="$(gh_api "repos/$1/releases/latest")"; then
    echo "  GitHub API refused $1 (rate limit?), set GITHUB_TOKEN and run again" >&2
    return 0
  fi
  grep -o '"browser_download_url": *"[^"]*"' <<<"$json" | cut -d'"' -f4 \
    | grep -iE "$2" | head -1 || true
}

# Downloads go under ~/.cache, not /tmp: /tmp is small or full on some VMs.
# The whole folder is removed when the script ends, even on failure.
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-install"
rm -rf "$WORK" && mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

download() {
  local url="$1" dir
  dir="$(mktemp -d "$WORK/dl.XXXXXX")"
  if ! curl -fsSL "$url" -o "$dir/pkg"; then
    echo "  download failed: $url (is the disk full? try: df -h ~)" >&2
    return 1
  fi
  mkdir -p "$dir/x"
  case "$url" in
    *.zip)    unzip -q "$dir/pkg" -d "$dir/x" ;;
    *.tar.gz) tar -xzf "$dir/pkg" -C "$dir/x" ;;
    *.gz)     gunzip -c "$dir/pkg" > "$dir/x/$(basename "${url%.gz}")" ;;
  esac
  echo "$dir/x"
}

# linux_tool NAME REPO PATTERN... takes the first pattern that matches a download
linux_tool() {
  local name="$1" repo="$2" url="" dir found pattern
  shift 2
  for pattern in "$@"; do
    url="$(asset_url "$repo" "$pattern")"
    [[ -n "$url" ]] && break
  done
  if [[ -z "$url" ]]; then
    echo "  $name: no download matched on $repo, skipped"
    return 0
  fi
  dir="$(download "$url")"
  found="$(find "$dir" -type f \( -name "$name" -o -name "$name.*stripped" \) | head -1)"
  install -m 755 "$found" "$BIN/$name"
  echo "  $name  $({ "$BIN/$name" --version || "$BIN/$name" -V; } 2>/dev/null | head -1)"
}

linux_nvim() {
  local url dir
  for repo in neovim/neovim neovim/neovim-releases; do
    url="$(asset_url "$repo" "nvim-linux-?($NV_ARCH|64)\.tar\.gz$")"
    [[ -n "$url" ]] || continue
    dir="$(download "$url")"
    rm -rf "$OPT/nvim" && mkdir -p "$OPT" && mv "$dir"/*/ "$OPT/nvim"
    ln -sfn "$OPT/nvim/bin/nvim" "$BIN/nvim"
    if "$BIN/nvim" --version >/dev/null 2>&1; then
      echo "  nvim  $("$BIN/nvim" --version | head -1)  (from $repo)"
      return 0
    fi
    echo "  nvim from $repo does not run here, trying the next build"
  done
  echo "  nvim: no build runs on this machine"
}

linux_kubectl() {
  local version
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" || { echo "  kubectl: version check failed, skipped"; return 0; }
  # Download beside it and swap: writing over a kubectl that is running fails (curl: 23).
  if curl -fsSL -o "$BIN/kubectl.new" "https://dl.k8s.io/release/$version/bin/linux/$GO_ARCH/kubectl"; then
    chmod 755 "$BIN/kubectl.new" && mv -f "$BIN/kubectl.new" "$BIN/kubectl"
    echo "  kubectl  $version"
  else
    rm -f "$BIN/kubectl.new"; echo "  kubectl: download failed, kept the old one (df -h ~ ?)"
  fi
}

# yq ships a bare binary named yq_linux_<arch>, not a yq inside an archive
linux_yq() {
  local url
  url="$(asset_url mikefarah/yq "/yq_linux_$GO_ARCH$")"
  [[ -n "$url" ]] || { echo "  yq: no download matched, skipped"; return 0; }
  curl -fsSL "$url" -o "$BIN/yq.new" && chmod 755 "$BIN/yq.new" && mv -f "$BIN/yq.new" "$BIN/yq" \
    || { rm -f "$BIN/yq.new"; echo "  yq: download failed"; return 0; }
  echo "  yq  $("$BIN/yq" --version 2>/dev/null)"
}

linux_helm() {
  local tag dir
  # Read the whole reply first: grep -m1 on a live curl pipe closes it early,
  # curl fails with "Failed writing body", and pipefail stops the script.
  local json
  json="$(gh_api repos/helm/helm/releases/latest)" || { echo "  helm: GitHub API refused, skipped"; return 0; }
  tag="$(grep -m1 '"tag_name"' <<<"$json" | cut -d'"' -f4)"
  dir="$(download "https://get.helm.sh/helm-$tag-linux-$GO_ARCH.tar.gz")"
  install -m 755 "$dir/linux-$GO_ARCH/helm" "$BIN/helm"
  echo "  helm  $tag"
}

# Frees space: leftovers of old runs, and the extras when FULL is not set.
cleanup() {
  step "Clean up"
  find /tmp -maxdepth 1 -name 'tmp.*' -user "$(id -un)" -exec rm -rf {} + 2>/dev/null || true
  if [[ "${FULL:-0}" != 1 ]]; then
    rm -f "$BIN"/{yazi,ya,gh,stern,lazydocker}
  fi
  rm -rf "$HOME/.cache/pip" "$HOME/.npm/_cacache" "$HOME/.cache/go-build"
  echo "  free in home: $(df -h "$HOME" | awk 'NR==2 {print $4}'), in /tmp: $(df -h /tmp | awk 'NR==2 {print $4}')"
  echo "  biggest folders in home:"
  du -sh "$HOME"/.[!.]* "$HOME"/* 2>/dev/null | sort -rh | head -5 | sed 's/^/    /'
}

linux_tools() {
  cleanup
  step "Tools into ~/.local/bin"
  mkdir -p "$BIN"
  export PATH="$BIN:$PATH"
  case "$(uname -m)" in
    x86_64)        GO_ARCH=amd64; RUST_ARCH=x86_64;  LG_ARCH=x86_64; NV_ARCH=x86_64 ;;
    aarch64|arm64) GO_ARCH=arm64; RUST_ARCH=aarch64; LG_ARCH=arm64;  NV_ARCH=arm64 ;;
    *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
  esac
  # musl builds carry their own C library, so they run on old glibc (Rocky 8 has 2.28)
  local musl="$RUST_ARCH-unknown-linux-musl" gnu="$RUST_ARCH-unknown-linux-gnu"
  linux_nvim
  linux_tool lazygit jesseduffield/lazygit "_linux_$LG_ARCH\.tar\.gz$"
  linux_tool fzf     junegunn/fzf          "linux_$GO_ARCH\.tar\.gz$"
  linux_tool fd      sharkdp/fd            "$musl\.tar\.gz$"       "$gnu\.tar\.gz$"
  linux_tool bat     sharkdp/bat           "$musl\.tar\.gz$"       "$gnu\.tar\.gz$"
  linux_tool rg      BurntSushi/ripgrep    "$musl\.tar\.gz$"       "$gnu\.tar\.gz$"
  linux_tool tmux    mjakob-gh/build-static-tmux "tmux\.linux-$GO_ARCH\.stripped\.gz$"

  # kubernetes
  linux_tool k9s     derailed/k9s          "k9s_linux_$GO_ARCH\.tar\.gz$"
  linux_tool kubectx ahmetb/kubectx        "kubectx_.*_linux_$LG_ARCH\.tar\.gz$"
  linux_tool kubens  ahmetb/kubectx        "kubens_.*_linux_$LG_ARCH\.tar\.gz$"
  linux_tool lfk     janosmiko/lfk         "lfk_.*_linux_$GO_ARCH\.tar\.gz$"
  linux_tool kubeconform yannh/kubeconform "kubeconform-linux-$GO_ARCH\.tar\.gz$"
  linux_tool kubectl-neat itaysk/kubectl-neat "kubectl-neat_linux_$GO_ARCH\.tar\.gz$"
  linux_yq
  linux_kubectl
  linux_helm

  # agent helpers: rtk shrinks command output before the agent reads it
  linux_tool rtk     rtk-ai/rtk            "/rtk-$musl\.tar\.gz$"  "/rtk-$gnu\.tar\.gz$"

  # Extras, only with FULL=1 ./install.sh (they need about 150 MB more)
  if [[ "${FULL:-0}" == 1 ]]; then
    linux_tool yazi  sxyazi/yazi  "yazi-$musl\.zip$"  "yazi-$gnu\.zip$"
    linux_tool gh    cli/cli      "linux_$GO_ARCH\.tar\.gz$"
    linux_tool stern stern/stern  "stern_.*_linux_$GO_ARCH\.tar\.gz$"
    linux_tool lazydocker jesseduffield/lazydocker "lazydocker_.*_linux_$LG_ARCH\.tar\.gz$"
  fi

  step "zsh"
  if ! command -v zsh >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null; then
      sudo dnf install -y zsh 2>/dev/null || sudo apt-get install -y zsh
    else
      echo "  no sudo: installing a standalone zsh into ~/.local"
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" \
        -- -d "$HOME/.local" -e no -q
    fi
  fi
  echo "  $(zsh --version)"
  if ! grep -q ">>> dotfiles: start zsh" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'BASHRC'
# >>> dotfiles: start zsh >>>
if [[ $- == *i* ]] && [ -z "$ZSH_VERSION" ]; then
  for z in "$(command -v zsh)" "$HOME/.local/bin/zsh"; do [ -x "$z" ] && exec "$z"; done
fi
# <<< dotfiles: start zsh <<<
BASHRC
    echo "  interactive bash now hands over to zsh"
  fi
}

if [[ "${1:-}" == clean ]]; then
  cleanup
  exit 0
fi

case "$(uname -s)" in
  Darwin) mac_tools ;;
  Linux)  linux_tools ;;
  *) echo "Unsupported system: $(uname -s)"; exit 1 ;;
esac

# --------------------------------------------------------------------------
step "Linking configs"
# --------------------------------------------------------------------------
link "$DOTFILES/zsh/zshrc"      "$HOME/.zshrc"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES/nvim"           "$HOME/.config/nvim"
link "$DOTFILES/git/gitconfig"  "$HOME/.gitconfig"
link "$DOTFILES/git/ignore"     "$HOME/.config/git/ignore"
link "$DOTFILES/k9s/aliases.yaml" "$HOME/.config/k9s/aliases.yaml"
link "$DOTFILES/k9s/plugins.yaml" "$HOME/.config/k9s/plugins.yaml"
# opencode: rules, agents, slash commands and skills. The model and provider
# settings (opencode.json) are left to the machine's own setup.
for f in AGENTS.md tui.json agents commands skills plugins; do
  link "$DOTFILES/opencode/$f" "$HOME/.config/opencode/$f"
done

# Cursor: rtk hook, MCP servers and the same skills as opencode.
# User rules live in Cursor's settings, not on disk (see README).
# mcp.json is only linked with WITH_MCP=1, same as Serena below.
link "$DOTFILES/cursor/hooks.json" "$HOME/.cursor/hooks.json"
[[ "${WITH_MCP:-0}" == 1 ]] && link "$DOTFILES/cursor/mcp.json" "$HOME/.cursor/mcp.json"
link "$DOTFILES/opencode/skills" "$HOME/.cursor/skills"

# --------------------------------------------------------------------------
step "Serena (code search MCP for opencode)"
# --------------------------------------------------------------------------
# Serena reads code by symbol through the language servers, so the agent reads
# one function instead of a whole file. It installs through uv.
# MCP servers are off until they are allowed: run with WITH_MCP=1 to install it.
if [[ "${WITH_MCP:-0}" != 1 ]]; then
  echo "  skipped (WITH_MCP=1 ./install.sh to install)"
elif ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN" INSTALLER_NO_MODIFY_PATH=1 sh \
    || echo "  uv install failed, Serena skipped"
fi
if [[ "${WITH_MCP:-0}" == 1 ]] && command -v uv >/dev/null 2>&1 && ! command -v serena >/dev/null 2>&1; then
  uv tool install -p 3.13 serena-agent || echo "  Serena install failed, opencode runs without it"
fi
command -v serena >/dev/null 2>&1 && echo "  serena  $(serena --version 2>/dev/null | head -1)"

# --------------------------------------------------------------------------
step "yaegi (Go REPL)"
# --------------------------------------------------------------------------
# Try Go types and snippets line by line, by hand or by the agent through opencode-pty.
if command -v go >/dev/null 2>&1 && ! command -v yaegi >/dev/null 2>&1; then
  go install github.com/traefik/yaegi/cmd/yaegi@latest || echo "  yaegi install failed"
fi
command -v yaegi >/dev/null 2>&1 && echo "  yaegi installed" || true

# --------------------------------------------------------------------------
step "oh-my-zsh and its plugins"
# --------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone_once zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_once zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_once zsh-users/zsh-completions         "$ZSH_CUSTOM/plugins/zsh-completions"
clone_once romkatv/powerlevel10k              "$ZSH_CUSTOM/themes/powerlevel10k"
# your saved prompt look, once zsh/p10k.zsh has been committed
[[ -f "$DOTFILES/zsh/p10k.zsh" ]] && link "$DOTFILES/zsh/p10k.zsh" "$HOME/.p10k.zsh"

# --------------------------------------------------------------------------
step "tmux plugins"
# --------------------------------------------------------------------------
for plugin in tpm tmux-resurrect tmux-continuum; do
  clone_once "tmux-plugins/$plugin" "$HOME/.config/tmux/plugins/$plugin"
done

# --------------------------------------------------------------------------
step "Machine-only files"
# --------------------------------------------------------------------------
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  read -rp "  Git name for this machine: " git_name
  read -rp "  Git email for this machine: " git_email
  printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$HOME/.gitconfig.local"
  echo "  wrote ~/.gitconfig.local"
fi
if [[ ! -f "$HOME/.secrets.zsh" ]]; then
  printf '# API keys and tokens go here, e.g.\n# export SOME_API_KEY=...\n' > "$HOME/.secrets.zsh"
  chmod 600 "$HOME/.secrets.zsh"
  echo "  created ~/.secrets.zsh (not in the repo)"
fi

step "Done"
echo "Open a new terminal tab. The first time you run nvim, LazyVim installs its plugins."

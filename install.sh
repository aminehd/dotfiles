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

asset_url() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 \
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
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$BIN/kubectl" "https://dl.k8s.io/release/$version/bin/linux/$GO_ARCH/kubectl"
  chmod 755 "$BIN/kubectl"
  echo "  kubectl  $version"
}

linux_helm() {
  local tag dir
  # Read the whole reply first: grep -m1 on a live curl pipe closes it early,
  # curl fails with "Failed writing body", and pipefail stops the script.
  local json
  json="$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest)"
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
  linux_kubectl
  linux_helm

  # opencode: only when missing, it is about 150 MB
  if ! command -v opencode >/dev/null 2>&1; then
    local oc_arch=x64; [[ "$GO_ARCH" == arm64 ]] && oc_arch=arm64
    linux_tool opencode anomalyco/opencode "opencode-linux-$oc_arch-musl\.tar\.gz$" "opencode-linux-$oc_arch\.tar\.gz$"
  fi
  # Go language server, so opencode and nvim see compile errors
  if command -v go >/dev/null 2>&1 && ! command -v gopls >/dev/null 2>&1; then
    GOBIN="$BIN" go install golang.org/x/tools/gopls@latest && echo "  gopls installed"
  fi

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
link "$DOTFILES/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
link "$DOTFILES/opencode/tui.json"      "$HOME/.config/opencode/tui.json"
link "$DOTFILES/opencode/AGENTS.md"     "$HOME/.config/opencode/AGENTS.md"
link "$DOTFILES/opencode/skills"        "$HOME/.config/opencode/skills"

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

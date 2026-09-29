#!/usr/bin/env bash
# Sets up a Mac from this repo. Safe to run again: it skips what is already done.
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
step "Homebrew"
# --------------------------------------------------------------------------
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

# --------------------------------------------------------------------------
step "oh-my-zsh and its plugins"
# --------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone_once zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_once zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_once zsh-users/zsh-completions         "$ZSH_CUSTOM/plugins/zsh-completions"

# --------------------------------------------------------------------------
step "Linking configs"
# --------------------------------------------------------------------------
link "$DOTFILES/zsh/zshrc"      "$HOME/.zshrc"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES/nvim"           "$HOME/.config/nvim"
link "$DOTFILES/git/gitconfig"  "$HOME/.gitconfig"
link "$DOTFILES/git/ignore"     "$HOME/.config/git/ignore"

# --------------------------------------------------------------------------
step "tmux plugins"
# --------------------------------------------------------------------------
clone_once tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins" || true

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

# dotfiles

My terminal setup: zsh with oh-my-zsh, tmux, Neovim (LazyVim), lazygit, fzf,
yazi and friends. Built for macOS on Apple Silicon.

## Install

```sh
git clone https://github.com/aminehd/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The script installs everything in the `Brewfile`, sets up oh-my-zsh and its
plugins, symlinks the configs into place (backing up anything already there),
and installs the tmux plugins. Running it again is safe.

Homebrew needs admin rights once. If it is missing, the script prints the
command and stops.

## What goes where

| repo | linked to |
| --- | --- |
| `zsh/zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `nvim/` | `~/.config/nvim` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |

## Never committed

- `~/.secrets.zsh`: API keys and tokens
- `~/.gitconfig.local`: name and email for this machine
- `~/.zshrc.local`: anything specific to one machine

## Shortcuts

| | |
| --- | --- |
| `lg` | lazygit |
| `vi`, `vim` | nvim |
| `vf` | fuzzy-find a file and open it in nvim |
| `vt` | nvim with the file tree open |
| `y` | yazi, and cd to where you quit |
| `Ctrl-R` | fuzzy history search (fzf) |

Not included: terminal font and colours.

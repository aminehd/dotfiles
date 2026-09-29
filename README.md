# dotfiles

My terminal setup: zsh with oh-my-zsh, tmux, Neovim (LazyVim), lazygit, fzf,
yazi and friends. One installer for the Mac and for Linux dev VMs (UBVM,
Rocky Linux 8).

## Install

```sh
git clone https://github.com/aminehd/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The script installs everything in the `Brewfile`, sets up oh-my-zsh and its
plugins, symlinks the configs into place (backing up anything already there),
and installs the tmux plugins. Running it again is safe.

**On the Mac** it uses Homebrew, which needs admin rights once. If Homebrew is
missing, the script prints the command and stops.

**On Linux** it needs no sudo. Every tool is downloaded into `~/.local/bin`
(Neovim into `~/.local/opt/nvim`), because the distro versions on Rocky 8 are
too old: tmux there is 2.7 and this config needs 3.2 or newer.

- Rust tools (fd, bat, ripgrep, yazi) use their musl builds, which run on old
  glibc. Rocky 8 has glibc 2.28.
- Neovim's main build needs glibc 2.34, so when it will not start the script
  switches to the `neovim-releases` build, which needs 2.17.
- tmux comes from `mjakob-gh/build-static-tmux`, a static build.
- If zsh is missing and there is no sudo, a standalone zsh is installed into
  `~/.local` with `romkatv/zsh-bin`, and interactive bash hands over to it.

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

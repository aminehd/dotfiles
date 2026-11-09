# dotfiles

My terminal setup: zsh with oh-my-zsh, tmux, Neovim (LazyVim), lazygit, fzf,
yazi and friends. One installer for the Mac and for Linux dev VMs (UBVM,
Rocky Linux 8).

## Install

One command, on the Mac or a Linux dev VM:

```sh
git clone git@github.com:aminehd/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
```

The repo is private, so git asks for a login: username `aminehd`, and for the
password a GitHub token (Settings, Developer settings, Personal access tokens,
Fine-grained: access to this repo only, Contents read-only).

The script installs the tools, sets up oh-my-zsh and its plugins, symlinks the
configs into place (backing up anything already there), and installs the tmux
plugins. Running it again is safe.

**On the Mac** it uses Homebrew, which needs admin rights once. If Homebrew is
missing, the script prints the command and stops.

**On Linux** it installs the core tools only: nvim, lazygit, fzf, fd, bat,
ripgrep, tmux, kubectl, helm, k9s, kubectx, kubens and lfk. For the extras
(yazi, gh, stern, lazydocker, about 150 MB more), run `FULL=1 ./install.sh`.

Low on disk? `./install.sh clean` removes leftovers of old runs, the extras,
and the pip/npm/go caches, then shows free space and the five biggest folders
in your home. A normal Linux run does this clean up first.

It needs no sudo. Every tool is downloaded into `~/.local/bin`
(Neovim into `~/.local/opt/nvim`), because the distro versions on Rocky 8 are
too old: tmux there is 2.7 and this config needs 3.2 or newer.

- Rust tools (fd, bat, ripgrep, and yazi with FULL=1) use their musl builds, which run on old
  glibc. Rocky 8 has glibc 2.28.
- Neovim's main build needs glibc 2.34, so when it will not start the script
  switches to the `neovim-releases` build, which needs 2.17.
- tmux comes from `mjakob-gh/build-static-tmux`, a static build.
- If zsh is missing and there is no sudo, a standalone zsh is installed into
  `~/.local` with `romkatv/zsh-bin`, and interactive bash hands over to it.

## Treesitter on old glibc (Rocky 8)

LazyVim's treesitter needs the `tree-sitter` CLI 0.26.1 or newer to build
language parsers. Without it, Go files get no `]a` / `]f` / `]c` jumps (next
parameter / function / class), and `]a` falls back to Neovim's `:next`.

The prebuilt Linux binaries need glibc 2.39, and Rocky 8 has 2.28. LazyVim's
fallback, a Mason download, fails with `GLIBC_2.35 not found`.

**One command does all of it:**

```sh
~/dotfiles/fix-treesitter.sh
```

It removes the Mason copy, builds the CLI with cargo, checks PATH, installs the
Go parser and checks that it loads. Safe to run again.

By hand, build it on the VM so it links against the VM's own glibc. No sudo
needed; GCC 8.5 is enough:

```sh
# Rust toolchain into ~/.cargo (about 2 minutes)
curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source ~/.cargo/env

# build tree-sitter (about 5 minutes); temp files in ~/.cache because /tmp is small on VMs
mkdir -p ~/.cache/tmp
TMPDIR=~/.cache/tmp cargo install --locked tree-sitter-cli

tree-sitter --version      # 0.26.x or newer
```

Then in nvim: `:TSInstall go`, restart, open a `.go` file and press `]`. The
`a` line should say "Next Parameter Start". Until then, `g]a` / `g[a`
(mini.ai) jump between arguments without treesitter.

On a machine with glibc 2.39 or newer, the prebuilt binary is enough:

```sh
curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
  | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter
```

Check with `ldd --version | head -1`.

## PlantUML diagrams in nvim

```sh
~/dotfiles/setup-plantuml.sh
```

Installs `plantuml` into `~/.local/bin` (the native build where glibc is 2.34 or
newer, otherwise the Java build plus a Java 21 runtime in `~/.local/opt`) and
iTerm2's `imgcat`. Diagrams render on the machine itself, never through a
plantuml server. No graphviz needed: the built-in smetana layout is used when
`dot` is missing.

| in nvim | does |
| --- | --- |
| save a `.puml` | writes `<name>.png` next to it |
| `<space>Pv` | shows the diagram under the cursor (a `.puml` file, or a ```` ```plantuml ```` block in markdown) in a new tmux window; any key closes it |
| `<space>Pt` | the same diagram as text in a split (sequence diagrams only) |

The image is an iTerm2 inline image, so tmux needs `allow-passthrough on`
(tmux.conf sets it; run `tmux source ~/.config/tmux/tmux.conf` once).

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
| `y` | yazi, and cd to where you quit (FULL=1 on Linux) |
| `Ctrl-R` | fuzzy history search (fzf) |
| `ga`, `gA`, `gc`, `gst`, `gp`... | git aliases from `zsh/git.zsh` (same names as oh-my-zsh, work without it) |

Not included: terminal font and colours.

## opencode

`opencode/` is linked into `~/.config/opencode/` (the model settings stay with the machine's own setup):

- `AGENTS.md`: how to work with me, loaded in every session
- `config.json`: turns on LSP (gopls, yaml, bash...) so opencode sees compile errors. Loaded through
  `OPENCODE_CONFIG` in zshrc and merged on top of the machine's own `opencode.json`
  It also asks before kubectl apply/delete/edit/scale/patch, helm install/upgrade/uninstall and
  git push. Two MCP servers are set up but off (`"enabled": false`) until MCP is allowed:
  context7 (current library docs) and Serena (reads code by symbol). `WITH_MCP=1 ./install.sh`
  installs Serena and links Cursor's mcp.json
- npm plugins in config.json: `@tarquinen/opencode-dcp` drops old tool output from the context,
  `opencode-pty` lets the agent drive a REPL (`yaegi` for Go, `python3 -i`)
- `tui.json`: tokyonight theme (matches nvim), smooth scrolling, thin cursor. Needs 24-bit colour:
  zshrc and tmux.conf set `COLORTERM=truecolor`, because ssh does not pass it to the VM.
  `ctrl+x b` hides or shows the right sidebar
- agents (Tab to switch): `k8s` read-only cluster investigator, `teach` explains top-down,
  `review` reviews the diff, `explore` fast read-only search subagent (set a cheap `model:` in it)
- plugins: `rtk.ts` sends shell commands through rtk, so the agent reads short output
- commands: `/kstatus`, `/kwhy <kind>/<name> -n <ns>`, `/kwho ...`, `/explain <thing>`,
  `/chart <path>`, `/review`, `/commit`, `/quiz [thing]`
- skills: k8s-inspect, trace-k8s-object, read-helm-chart, read-k8s-controller, deploy-verify,
  debug-systematically, tdd, explain-top-down, git-commit, verify-before-done, uml-render, whole-then-build
- `config.json` has no model names on purpose. Set a fast model in the machine's own `opencode.json`:
  `small_model` and `agent.explore.model`
- The `ask` rules are listed twice, with and without `rtk `, because the rtk plugin rewrites the command
  before the rule is checked
- `uml-render` draws a class diagram to `~/uml/<name>.puml` and renders the PNG on this machine. Its `render.sh`
  prints the exact failing line so the agent can fix it, and uses smetana when graphviz is missing

## Cursor

`cursor/` is linked into `~/.cursor/`. It shares the skills and the rules with opencode:

- `hooks.json`: sends shell commands through rtk, like the opencode plugin
- `mcp.json`: the same context7 and Serena MCP servers, linked only with `WITH_MCP=1`
- `~/.cursor/skills` links to `opencode/skills`, Cursor reads the same SKILL.md format
- `cursorignore`: copy it to a repo as `.cursorignore`, or paste it into
  Settings → Indexing & Docs → Global Cursor Ignore. It keeps vendor, build output, lock files
  and big generated YAML out of the agent's context
- User rules are not files in Cursor. Paste `opencode/AGENTS.md` into Settings → Rules → User Rules

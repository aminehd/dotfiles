#!/usr/bin/env bash
# Makes treesitter work on Linux VMs with an old glibc (Rocky 8 has 2.28), so Go
# files get ]a / ]f / ]c (next parameter / function / class).
#
# LazyVim needs the tree-sitter CLI (0.26.1 or newer) to build parsers. When it
# is missing, LazyVim downloads one with Mason, and that binary needs glibc 2.35
# ("GLIBC_2.35 not found"). This script removes that copy and builds the CLI
# with cargo instead, so it links against the VM's own glibc.
#
#   ./fix-treesitter.sh
#
# No sudo. Safe to run again: steps that are already done are skipped.
set -euo pipefail

MIN_VERSION=0.26.1
MASON="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason"
CARGO_BIN="$HOME/.cargo/bin"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m  %s\n' "$*"; }
warn() { printf '    \033[33m!!\033[0m  %s\n' "$*"; }
die()  { printf '    \033[31mfail\033[0m  %s\n' "$*"; exit 1; }

# version of a tree-sitter binary, empty if it does not run
ts_version() { "$1" --version 2>/dev/null | awk '{print $2}'; }
# true if $1 >= $2
version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

say "glibc"
ok "$(ldd --version | head -1)"

say "Remove broken tree-sitter binaries"
if [[ -e "$MASON/packages/tree-sitter-cli" || -e "$MASON/bin/tree-sitter" ]]; then
  rm -rf "$MASON/packages/tree-sitter-cli" "$MASON/bin/tree-sitter"
  ok "removed the Mason copy (it needs a newer glibc)"
else
  ok "no Mason copy"
fi
# a prebuilt download dropped into ~/.local/bin fails the same way
if [[ -e "$HOME/.local/bin/tree-sitter" && -z "$(ts_version "$HOME/.local/bin/tree-sitter")" ]]; then
  mv "$HOME/.local/bin/tree-sitter" "$HOME/.local/bin/tree-sitter.broken"
  ok "moved ~/.local/bin/tree-sitter aside (it does not run here)"
fi

say "tree-sitter CLI (cargo build)"
export PATH="$CARGO_BIN:$PATH"
have="$( [[ -x "$CARGO_BIN/tree-sitter" ]] && ts_version "$CARGO_BIN/tree-sitter" || true )"
if [[ -n "$have" ]] && version_ge "$have" "$MIN_VERSION"; then
  ok "tree-sitter $have already built"
else
  if [[ ! -x "$CARGO_BIN/cargo" ]]; then
    ok "installing the Rust toolchain into ~/.cargo (about 2 minutes)"
    # --no-modify-path: zshrc in this repo already adds ~/.cargo/bin
    curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
  fi
  ok "building tree-sitter (about 5 minutes)"
  # /tmp is small on VMs
  mkdir -p "$HOME/.cache/tmp"
  TMPDIR="$HOME/.cache/tmp" cargo install --locked tree-sitter-cli
  have="$(ts_version "$CARGO_BIN/tree-sitter")"
  [[ -n "$have" ]] || die "tree-sitter was built but does not run"
  ok "tree-sitter $have"
fi
version_ge "$have" "$MIN_VERSION" || die "tree-sitter $have is older than $MIN_VERSION"

say "PATH"
if [[ "$(command -v tree-sitter)" == "$CARGO_BIN/tree-sitter" ]]; then
  ok "tree-sitter resolves to ~/.cargo/bin"
else
  warn "first tree-sitter on PATH is $(command -v tree-sitter); ~/.cargo/bin should come first"
fi
if ! grep -q '.cargo/bin' "$HOME/.zshrc" 2>/dev/null; then
  warn "~/.zshrc does not add ~/.cargo/bin; pull the latest dotfiles"
fi

say "Go parser"
nvim --headless "+Lazy! load nvim-treesitter" \
  "+lua require('nvim-treesitter').install({ 'go' }):wait(300000)" +qa 2>&1 | tail -3 || true

check="$(nvim --headless "+Lazy! load nvim-treesitter nvim-treesitter-textobjects" \
  "+lua io.stdout:write(tostring(pcall(vim.treesitter.language.add, 'go')), ' ', tostring(vim.treesitter.query.get('go', 'textobjects') ~= nil))" \
  +qa 2>/dev/null)"
case "$check" in
  "true true") ok "Go parser loads and has textobjects" ;;
  "true "*)    die "Go parser loads but textobjects queries are missing; run :Lazy sync in nvim" ;;
  *)           die "Go parser does not load; open nvim and run :TSInstall go, then :messages" ;;
esac

say "Done"
echo "    Open a new shell, open a .go file in nvim and press ]  (the a line should say Next Parameter Start)."

#!/usr/bin/env bash
# Installs the agent harnesses and links the shared setup into each one.
# Run by ../install.sh, or on its own. Safe to run again.
#
#   agent/AGENTS.md   how to work with me      -> opencode, pi, omp
#   agent/skills/     shared SKILL.md folders  -> ~/.agents/skills (opencode, pi, omp) and Cursor
#   agent/opencode/   agents, commands, rtk plugin, permissions
#   agent/cursor/     rtk hook, MCP servers
#
# The model provider and the API key are NOT here. They are machine-only files
# (see agent/README.md, step 2), so nothing private ends up in this repo.
set -euo pipefail

AGENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------------------
step "Back up old opencode sessions"
# --------------------------------------------------------------------------
# opencode 1 keeps sessions in ~/.local/share/opencode. Copy them once before
# opencode 2 goes in, so nothing is lost even if 2 cannot open them.
DATA="$HOME/.local/share/opencode"
if [[ -d "$DATA" && ! -d "$DATA-v1-backup" ]] && have opencode \
   && [[ "$(opencode --version 2>/dev/null | tail -1)" == 1.* ]]; then
  cp -a "$DATA" "$DATA-v1-backup"
  echo "  copied to $DATA-v1-backup"
else
  echo "  nothing to do"
fi

# --------------------------------------------------------------------------
step "Harnesses"
# --------------------------------------------------------------------------
# Only installs what is missing. To upgrade one, run its line by hand.
if have opencode && [[ "$(opencode --version 2>/dev/null | tail -1)" == 1.* ]]; then
  echo "  opencode 1 found at $(command -v opencode): uninstall it first (README step 1), skipped"
elif ! have opencode; then
  curl -fsSL https://opencode.ai/v2/install | bash || echo "  opencode install failed"
fi
have pi    || curl -fsSL https://pi.dev/install.sh   | sh || echo "  pi install failed"
have omp   || curl -fsSL https://omp.sh/install      | sh || echo "  omp install failed"
have herdr || curl -fsSL https://herdr.dev/install.sh | sh || echo "  herdr install failed"

# pi has no subagents built in; this package adds scout, worker and reviewer.
if have pi && ! pi list 2>/dev/null | grep -q pi-subagents; then
  pi install npm:pi-subagents || echo "  pi-subagents install failed"
fi

for t in opencode pi omp herdr rtk; do
  have "$t" && echo "  $t  $("$t" --version 2>/dev/null | tail -1)" || echo "  $t  missing"
done

# --------------------------------------------------------------------------
step "Shared rules and skills"
# --------------------------------------------------------------------------
link "$AGENT/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
link "$AGENT/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
link "$AGENT/AGENTS.md" "$HOME/.omp/agent/AGENTS.md"

# One skills folder that opencode, pi and omp all read.
link "$AGENT/skills" "$HOME/.agents/skills"
link "$AGENT/skills" "$HOME/.cursor/skills"
# The old per-opencode link would load every skill twice.
if [[ -L "$HOME/.config/opencode/skills" ]]; then
  rm "$HOME/.config/opencode/skills" && echo "  removed old ~/.config/opencode/skills link"
fi

# --------------------------------------------------------------------------
step "opencode"
# --------------------------------------------------------------------------
# config.json (permissions, LSP, plugins) is loaded through OPENCODE_CONFIG in zshrc.
for f in tui.json agents commands plugins; do
  link "$AGENT/opencode/$f" "$HOME/.config/opencode/$f"
done

# --------------------------------------------------------------------------
step "Cursor"
# --------------------------------------------------------------------------
link "$AGENT/cursor/hooks.json" "$HOME/.cursor/hooks.json"
[[ "${WITH_MCP:-0}" == 1 ]] && link "$AGENT/cursor/mcp.json" "$HOME/.cursor/mcp.json"

# --------------------------------------------------------------------------
step "Provider check"
# --------------------------------------------------------------------------
[[ -f "$HOME/.config/opencode/opencode.jsonc" || -f "$HOME/.config/opencode/opencode.json" ]] \
  && echo "  opencode provider file: found" || echo "  opencode provider file: missing (README step 2)"
[[ -f "$HOME/.pi/agent/models.json" ]] \
  && echo "  pi models.json: found"         || echo "  pi models.json: missing (README step 2)"
[[ -f "$HOME/.omp/agent/models.yml" ]] \
  && echo "  omp models.yml: found"         || echo "  omp models.yml: missing (README step 2)"

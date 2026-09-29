# y: yazi file manager, and cd to wherever you quit it
y() {
  local tmp=$(mktemp)
  yazi "$@" --cwd-file="$tmp"
  local cwd=$(cat "$tmp")
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
  rm -f "$tmp"
}

# vf: fuzzy-find a file with a preview, open it in nvim
vf() {
  local file
  file=$(fd --type f --hidden --exclude .git 2>/dev/null \
    | fzf --preview 'bat --color=always --style=numbers {}' \
          --preview-window=right:60%:wrap \
          --height 90%)
  [[ -n "$file" ]] && nvim "$file"
}

# vt: open nvim with the file tree revealed
vt() {
  nvim "${1:-.}" -c "Neotree reveal"
}

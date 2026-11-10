#!/usr/bin/env bash
# Render one .puml to a PNG next to it, on this machine.
# Prints OK, or the exact failing line. Never leaves a picture of an error behind.
f="${1:-}"
[ -f "$f" ] || { echo "no such file: $f"; exit 2; }
command -v plantuml >/dev/null || { echo "plantuml not found: run setup-plantuml.sh from the dotfiles"; exit 3; }
head -1 "$f" | grep -q '^@startuml' || { echo "line 1 must be @startuml (no markdown fences)"; exit 2; }

layout=()
command -v dot >/dev/null || layout=(-Playout=smetana)   # smetana: no graphviz needed

png="${f%.*}.png"
# No -failfast2 here: it hides the line number the agent needs to fix the file.
out=$(plantuml -tpng "${layout[@]}" "$f" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
  rm -f "$png"
  echo "$out" | head -5
  line=$(echo "$out" | grep -oE 'line [0-9]+' | head -1 | cut -d' ' -f2)
  [ -n "$line" ] && { echo "--- line $line is:"; sed -n "${line}p" "$f"; }
  exit "$rc"
fi
echo "OK $png"

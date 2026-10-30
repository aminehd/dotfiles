#!/usr/bin/env bash
# Installs what nvim needs to draw PlantUML diagrams (nvim/lua/plugins/plantuml.lua):
#   plantuml   in ~/.local/bin, renders on this machine (no plantuml server, nothing is uploaded)
#   imgcat     iTerm2's image printer, used to show the PNG in a tmux window
#
#   ./setup-plantuml.sh            USE_JAR=1 ./setup-plantuml.sh  (skip the native build)
#
# Linux: the native build needs glibc 2.34. On older VMs (Rocky 8 has 2.28) it falls
# back to the Java build, and downloads a Java 21 runtime into ~/.local/opt if the
# installed java is older than 11. No sudo. Safe to run again.
set -euo pipefail

VERSION=1.2026.9
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
JAR_DIR="$HOME/.local/share/plantuml"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/setup-plantuml"
REL="https://github.com/plantuml/plantuml/releases/download/v$VERSION"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m  %s\n' "$*"; }
die()  { printf '    \033[31mfail\033[0m  %s\n' "$*"; exit 1; }

mkdir -p "$BIN" "$OPT" "$JAR_DIR"
rm -rf "$WORK" && mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT
export PATH="$BIN:$PATH"

# major version of a java binary, 0 if it does not run (1.8 counts as 8)
java_major() {
  local v
  v="$("$1" -version 2>&1 | awk -F'"' '/version/ {print $2; exit}')" || true
  [[ -z "$v" ]] && { echo 0; return; }
  [[ "$v" == 1.* ]] && v="${v#1.}"
  echo "${v%%.*}"
}

write_wrapper() {
  printf '#!/bin/sh\n# written by setup-plantuml.sh\nexec %s "$@"\n' "$1" > "$BIN/plantuml"
  chmod +x "$BIN/plantuml"
}

install_native() {
  say "PlantUML $VERSION (native build)"
  local arch; arch="$( [[ "$(uname -m)" == aarch64 ]] && echo arm64 || echo amd64 )"
  curl -fsSL -o "$WORK/n.zip" "$REL/native-plantuml-linux-$arch-$VERSION.zip"
  rm -rf "$OPT/plantuml" && mkdir -p "$OPT/plantuml"
  unzip -q "$WORK/n.zip" -d "$OPT/plantuml"
  # -version exits non-zero even when it works, so check what it prints
  [[ "$("$OPT/plantuml/plantuml" -version 2>/dev/null | head -1)" == *"$VERSION"* ]] || return 1
  write_wrapper "$OPT/plantuml/plantuml"
  ok "native build in ~/.local/opt/plantuml"
}

install_jar() {
  say "Java 11 or newer"
  local java=""
  if command -v java >/dev/null && (( $(java_major "$(command -v java)") >= 11 )); then
    java="$(command -v java)"
  elif [[ -x "$OPT/jre/bin/java" ]] && (( $(java_major "$OPT/jre/bin/java") >= 11 )); then
    java="$OPT/jre/bin/java"
  else
    ok "downloading a Java 21 runtime into ~/.local/opt/jre (about 50 MB)"
    local arch; arch="$( [[ "$(uname -m)" == aarch64 ]] && echo aarch64 || echo x64 )"
    curl -fsSL -o "$WORK/jre.tgz" \
      "https://api.adoptium.net/v3/binary/latest/21/ga/linux/$arch/jre/hotspot/normal/eclipse"
    rm -rf "$OPT/jre" && mkdir -p "$OPT/jre"
    tar -xzf "$WORK/jre.tgz" -C "$OPT/jre" --strip-components 1
    java="$OPT/jre/bin/java"
  fi
  ok "$("$java" -version 2>&1 | head -1)"

  say "PlantUML $VERSION (Java build)"
  curl -fsSL -o "$JAR_DIR/plantuml.jar" "$REL/plantuml-$VERSION.jar"
  write_wrapper "$java -Djava.awt.headless=true -jar $JAR_DIR/plantuml.jar"
  ok "~/.local/share/plantuml/plantuml.jar"
}

if [[ "$(uname)" == Darwin ]]; then
  say "PlantUML (Homebrew)"
  command -v plantuml >/dev/null || brew install plantuml
  ok "$(command -v plantuml)"
elif [[ "$(plantuml -version 2>/dev/null | head -1)" == *"$VERSION"* ]]; then
  say "PlantUML"
  ok "$VERSION already installed"
else
  if [[ "${USE_JAR:-0}" == 1 ]] || ! install_native; then
    install_jar
  fi
fi

say "imgcat"
if command -v imgcat >/dev/null; then
  ok "$(command -v imgcat)"
else
  curl -fsSL -o "$BIN/imgcat" https://iterm2.com/utilities/imgcat
  chmod +x "$BIN/imgcat"
  ok "~/.local/bin/imgcat"
fi

say "Test render"
layout=()
command -v dot >/dev/null || layout=(-Playout=smetana)   # smetana: no graphviz needed
printf '@startuml\nclass A\nclass B\nA --> B\n@enduml\n' \
  | plantuml -pipe -tpng "${layout[@]}" > "$WORK/test.png"
[[ "$(head -c 4 "$WORK/test.png" | tail -c 3)" == PNG ]] || die "plantuml did not write a PNG"
ok "plantuml writes PNGs"

say "Done"
echo "    In nvim: save a .puml to write its .png, <space>Pv to show it, <space>Pt for text."
echo "    tmux needs allow-passthrough (tmux 3.3+) for the image to show; tmux.conf sets it."

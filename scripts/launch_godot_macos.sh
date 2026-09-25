#!/bin/bash
set -euo pipefail

scene="${1:?A res:// scene path is required}"
shift

repo_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
project_dir="$repo_dir/source_pack_v4/experiments/terrace"

fail() {
  printf '%s\n' "$1" >&2
  if [ -t 0 ]; then
    read -r -p 'Press Return to close this window... ' _ || true
  fi
  exit 2
}

resolve_engine() {
  local candidate="$1"
  case "$candidate" in
    *.app) candidate="$candidate/Contents/MacOS/Godot" ;;
  esac
  if [ -f "$candidate" ] && [ -x "$candidate" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

if [ "$#" -gt 1 ]; then
  fail 'Usage: PLAY_*.command [Godot executable or .app path]'
fi

engine=''
if [ "$#" -eq 1 ]; then
  engine="$(resolve_engine "$1")" || fail "Godot executable was not found or is not executable: $1"
else
  for app in \
    /Applications/Godot_v4.7.2*.app \
    "$HOME"/Applications/Godot_v4.7.2*.app \
    "$HOME"/Downloads/Godot_v4.7.2*.app \
    /Applications/Godot.app \
    "$HOME"/Applications/Godot.app \
    "$HOME"/Downloads/Godot.app; do
    if engine="$(resolve_engine "$app")"; then
      break
    fi
  done
  if [ -z "$engine" ]; then
    for name in godot godot4; do
      if command -v "$name" >/dev/null 2>&1; then
        engine="$(command -v "$name")"
        break
      fi
    done
  fi
  [ -n "$engine" ] || fail 'Godot 4.7.2 was not found. Install Godot.app in Applications, add godot/godot4 to PATH, or pass its executable or .app path as the first argument.'
fi

[ -f "$project_dir/project.godot" ] || fail "Godot project was not found: $project_dir/project.godot"
exec "$engine" --path "$project_dir" "$scene" -- --test

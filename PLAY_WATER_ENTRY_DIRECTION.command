#!/bin/bash
set -e
script_dir="$(cd "$(dirname "$0")" && pwd -P)"
exec "$script_dir/scripts/launch_godot_macos.sh" res://maps/water_entry_direction.tscn "$@"

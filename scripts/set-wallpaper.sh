#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/Pictures/Wallpapers"
IMG_NAME="gruv abstract maze"

if ! command -v swww >/dev/null 2>&1; then
  echo "[ERROR] swww not found" >&2
  exit 1
fi

pgrep -x swww-daemon >/dev/null 2>&1 || swww-daemon &
sleep 0.3

img_path=$(find "$WALL_DIR" -maxdepth 1 -type f -iname "*${IMG_NAME}*" | head -n1)
if [[ -z "${img_path}" ]]; then
  echo "[ERROR] Wallpaper matching '${IMG_NAME}' not found in ${WALL_DIR}" >&2
  exit 1
fi

swww img "$img_path" --transition-type any --transition-duration 1

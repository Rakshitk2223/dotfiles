#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")"/.. && pwd)/Wallpapers"
DEST_DIR="$HOME/Pictures/Wallpapers"

mkdir -p "$DEST_DIR"
rsync -avh --delete "$SRC_DIR/" "$DEST_DIR/"

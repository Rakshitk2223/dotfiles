#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/uiriansan/SilentSDDM"
BRANCH="main"
WORKDIR=$(mktemp -d)

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] git is required" >&2
  exit 1
fi

if ! command -v sddm >/dev/null 2>&1; then
  echo "[WARN] sddm not found; installing theme anyway"
fi

cd "$WORKDIR"
git clone -b "$BRANCH" --depth=1 "$REPO_URL" SilentSDDM
cd SilentSDDM
chmod +x install.sh
./install.sh

echo "[INFO] SilentSDDM theme installed"

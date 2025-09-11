#!/bin/bash
# This script refreshes the font cache and applies system-wide themes.

set -euo pipefail

# --- Log functions ---
log_info() {
    echo "[INFO] $1"
}

# --- Main execution ---
main() {
    log_info "Refreshing font cache..."
    fc-cache -fv

    log_info "Theme and fonts will be applied by linking dotfiles."
}

main

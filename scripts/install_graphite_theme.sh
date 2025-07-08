#!/bin/bash
# This script installs the Graphite GTK theme from its GitHub repository.

set -euo pipefail

# --- Constants ---
THEME_REPO="https://github.com/vinceliuice/Graphite-gtk-theme.git"
TMP_DIR="/tmp/graphite-gtk-theme"

# --- Log functions ---
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

# --- Main execution ---
main() {
    if [ -d "$HOME/.themes/Graphite-Dark" ]; then
        log_info "Graphite GTK theme already installed."
        exit 0
    fi

    log_info "Cloning Graphite GTK theme repository..."
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
    git clone "$THEME_REPO" --depth=1 "$TMP_DIR"

    log_info "Running the theme installer..."
    cd "$TMP_DIR"
    ./install.sh --silent -c dark -t all
    
    log_info "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"

    log_info "Graphite GTK theme installed successfully."
}

main

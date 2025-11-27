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

log_error() {
    echo "[ERROR] $1" >&2
}

# --- Main execution ---
main() {
    # Check if already installed
    if [[ -d "$HOME/.themes/Graphite-Dark" ]]; then
        log_info "Graphite GTK theme already installed."
        exit 0
    fi

    log_info "Cloning Graphite GTK theme repository..."
    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
    
    if ! git clone "$THEME_REPO" --depth=1 "$TMP_DIR" 2>/dev/null; then
        log_error "Failed to clone Graphite theme repository"
        exit 1
    fi

    log_info "Running the theme installer..."
    cd "$TMP_DIR"
    
    # Install dark variant with all color options
    if ./install.sh -c dark -t all 2>/dev/null; then
        log_info "Graphite GTK theme installed successfully."
    else
        log_warn "Theme installer had some issues, but may have partially installed."
    fi
    
    log_info "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}

main

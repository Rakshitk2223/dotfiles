#!/bin/bash

set -euo pipefail

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
    exit 1
}

install_dotfiles() {
    log_info "Installing dotfiles to ~/.config..."
    local DOTFILES_SOURCE_DIR="$(dirname "$(dirname "$0")")/.config"
    local CONFIG_DEST_DIR="$HOME/.config"

    mkdir -p "$CONFIG_DEST_DIR"
    rsync -avh --exclude '.git' --exclude '.gitmodules' "$DOTFILES_SOURCE_DIR/" "$CONFIG_DEST_DIR/"
    find "$CONFIG_DEST_DIR/waybar/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    log_info "Dotfiles installed."
}

install_local_bin_scripts() {
    log_info "Installing local bin scripts to ~/.local/bin/scripts..."
    local SCRIPTS_SOURCE_DIR="$(dirname "$(dirname "$0")")/.local/bin/scripts"
    local LOCAL_BIN_DEST_DIR="$HOME/.local/bin/scripts"

    mkdir -p "$LOCAL_BIN_DEST_DIR"
    rsync -avh "$SCRIPTS_SOURCE_DIR/" "$LOCAL_BIN_DEST_DIR/"
    chmod +x "$LOCAL_BIN_DEST_DIR"/*.sh
    log_info "Local bin scripts installed and made executable."
}

install_home_dotfiles() {
    log_info "Installing .tmux.conf and .zshrc to $HOME..."
    local REPO_ROOT_DIR="$(dirname "$(dirname "$0")")"
    rsync -avh "$REPO_ROOT_DIR/.tmux.conf" "$HOME/"
    rsync -avh "$REPO_ROOT_DIR/.zshrc" "$HOME/"
    log_info ".tmux.conf and .zshrc installed."
}

main() {
    install_dotfiles
    install_local_bin_scripts
    install_home_dotfiles
}

main

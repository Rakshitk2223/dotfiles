#!/bin/bash
# Migration: 20250125_migrate_to_new_structure.sh
# Migrates from old script structure to new dotfiles- prefixed structure
#
# Changes:
# - Replaces ~/.local/bin/scripts/*.sh with ~/.local/bin/dotfiles-* commands
# - Updates ~/.config/hypr/keybinds.conf to use new script paths
# - Updates ~/.config/waybar/config to use new script paths
# - Installs new modular zsh config (default/zsh/*)
# - Installs lib/state.sh for state management
# - Cleans up old scripts (optional backup)

set -euo pipefail

# Get repo root (this script runs from migrations/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOG() { echo "[MIGRATION] $*"; }
WARN() { echo "[MIGRATION WARN] $*"; }

# Backup directory for old files
BACKUP_DIR="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%d_%H%M%S)"

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/"
        LOG "Backed up: $file"
    fi
}

# =============================================================================
# Step 1: Install new bin scripts
# =============================================================================
install_new_bin_scripts() {
    LOG "Installing new dotfiles-* scripts to ~/.local/bin..."
    
    local BIN_SOURCE="$REPO_ROOT/bin"
    local BIN_DEST="$HOME/.local/bin"
    
    mkdir -p "$BIN_DEST"
    
    for script in "$BIN_SOURCE"/dotfiles-*; do
        if [[ -f "$script" ]]; then
            local script_name
            script_name="$(basename "$script")"
            cp "$script" "$BIN_DEST/"
            chmod +x "$BIN_DEST/$script_name"
            LOG "Installed: $script_name"
        fi
    done
}

# =============================================================================
# Step 2: Install lib directory
# =============================================================================
install_lib() {
    LOG "Installing lib/ to ~/.local/bin/dotfiles/lib..."
    
    local LIB_SOURCE="$REPO_ROOT/lib"
    local LIB_DEST="$HOME/.local/bin/dotfiles/lib"
    
    # Skip if source and destination are the same (fresh install case)
    if [[ "$(realpath "$LIB_SOURCE" 2>/dev/null)" == "$(realpath "$LIB_DEST" 2>/dev/null)" ]]; then
        LOG "lib/ already in place (fresh install), skipping..."
        return 0
    fi
    
    mkdir -p "$LIB_DEST"
    
    if [[ -d "$LIB_SOURCE" ]]; then
        cp -r "$LIB_SOURCE"/* "$LIB_DEST/"
        LOG "Installed lib scripts"
    fi
}

# =============================================================================
# Step 3: Install default zsh configs
# =============================================================================
install_default_configs() {
    LOG "Installing default/zsh/ configs..."
    
    local DEFAULT_SOURCE="$REPO_ROOT/default"
    local DEFAULT_DEST="$HOME/.local/bin/dotfiles/default"
    
    # Skip if source and destination are the same (fresh install case)
    if [[ "$(realpath "$DEFAULT_SOURCE" 2>/dev/null)" == "$(realpath "$DEFAULT_DEST" 2>/dev/null)" ]]; then
        LOG "default/ already in place (fresh install), skipping..."
        return 0
    fi
    
    mkdir -p "$DEFAULT_DEST"
    
    if [[ -d "$DEFAULT_SOURCE" ]]; then
        cp -r "$DEFAULT_SOURCE"/* "$DEFAULT_DEST/"
        LOG "Installed default configs"
    fi
}

# =============================================================================
# Step 4: Update Hyprland keybinds.conf
# =============================================================================
update_hyprland_keybinds() {
    local KEYBINDS_FILE="$HOME/.config/hypr/keybinds.conf"
    
    if [[ ! -f "$KEYBINDS_FILE" ]]; then
        LOG "No keybinds.conf found, skipping..."
        return 0
    fi
    
    # Check if already migrated (new paths exist)
    if grep -q "dotfiles-screenshot" "$KEYBINDS_FILE" 2>/dev/null; then
        LOG "keybinds.conf already migrated, skipping..."
        return 0
    fi
    
    # Check if old paths exist
    if ! grep -q "\.local/bin/scripts/" "$KEYBINDS_FILE" 2>/dev/null; then
        LOG "No old script paths found in keybinds.conf, skipping..."
        return 0
    fi
    
    LOG "Updating keybinds.conf with new script paths..."
    backup_file "$KEYBINDS_FILE"
    
    # Replace old paths with new commands
    sed -i \
        -e 's|~/.local/bin/scripts/waybar-toggle.sh|dotfiles-waybar-toggle|g' \
        -e 's|\$HOME/.local/bin/scripts/waybar-toggle.sh|dotfiles-waybar-toggle|g' \
        -e 's|~/.local/bin/scripts/mic-toggle.sh|dotfiles-mic-toggle|g' \
        -e 's|\$HOME/.local/bin/scripts/mic-toggle.sh|dotfiles-mic-toggle|g' \
        -e 's|~/.local/bin/scripts/screenshot.sh|dotfiles-screenshot|g' \
        -e 's|\$HOME/.local/bin/scripts/screenshot.sh|dotfiles-screenshot|g' \
        "$KEYBINDS_FILE"
    
    LOG "Updated keybinds.conf"
}

# =============================================================================
# Step 5: Update Waybar config
# =============================================================================
update_waybar_config() {
    local WAYBAR_CONFIG="$HOME/.config/waybar/config"
    
    if [[ ! -f "$WAYBAR_CONFIG" ]]; then
        LOG "No waybar config found, skipping..."
        return 0
    fi
    
    # Check if already migrated
    if grep -q "dotfiles-mic-toggle" "$WAYBAR_CONFIG" 2>/dev/null; then
        LOG "waybar config already migrated, skipping..."
        return 0
    fi
    
    # Check if old paths exist
    if ! grep -q "\.local/bin/scripts/mic-toggle.sh" "$WAYBAR_CONFIG" 2>/dev/null; then
        LOG "No old script paths found in waybar config, skipping..."
        return 0
    fi
    
    LOG "Updating waybar config with new script paths..."
    backup_file "$WAYBAR_CONFIG"
    
    # Replace old paths with new commands
    sed -i \
        -e 's|~/.local/bin/scripts/mic-toggle.sh|dotfiles-mic-toggle|g' \
        -e 's|\$HOME/.local/bin/scripts/mic-toggle.sh|dotfiles-mic-toggle|g' \
        "$WAYBAR_CONFIG"
    
    LOG "Updated waybar config"
}

# =============================================================================
# Step 6: Update .zshrc to new modular format
# =============================================================================
update_zshrc() {
    local ZSHRC="$HOME/.zshrc"
    
    if [[ ! -f "$ZSHRC" ]]; then
        LOG "No .zshrc found, will install fresh copy..."
        cp "$REPO_ROOT/.zshrc" "$ZSHRC"
        return 0
    fi
    
    # Check if already using new modular format
    if grep -q "default/zsh/shell" "$ZSHRC" 2>/dev/null; then
        LOG ".zshrc already using modular format, skipping..."
        return 0
    fi
    
    LOG "Updating .zshrc to modular format..."
    backup_file "$ZSHRC"
    
    # Install new .zshrc (the old one is backed up)
    cp "$REPO_ROOT/.zshrc" "$ZSHRC"
    
    LOG "Updated .zshrc (old version backed up)"
}

# =============================================================================
# Step 7: Clean up old scripts (keep backups)
# =============================================================================
cleanup_old_scripts() {
    local OLD_SCRIPTS_DIR="$HOME/.local/bin/scripts"
    
    if [[ ! -d "$OLD_SCRIPTS_DIR" ]]; then
        LOG "No old scripts directory found, skipping cleanup..."
        return 0
    fi
    
    LOG "Cleaning up old scripts in ~/.local/bin/scripts/..."
    
    # List of old scripts that are now replaced
    local old_scripts=(
        "mic-toggle.sh"
        "screenshot.sh"
        "waybar-toggle.sh"
        "set-permissions.sh"
    )
    
    for script in "${old_scripts[@]}"; do
        local old_path="$OLD_SCRIPTS_DIR/$script"
        if [[ -f "$old_path" ]]; then
            backup_file "$old_path"
            rm "$old_path"
            LOG "Removed old script: $script"
        fi
    done
    
    # Remove directory if empty (except for other scripts user may have)
    if [[ -d "$OLD_SCRIPTS_DIR" ]] && [[ -z "$(ls -A "$OLD_SCRIPTS_DIR" 2>/dev/null)" ]]; then
        rmdir "$OLD_SCRIPTS_DIR"
        LOG "Removed empty scripts directory"
    fi
}

# =============================================================================
# Step 8: Initialize state directory
# =============================================================================
init_state() {
    LOG "Initializing state directory..."
    
    local STATE_DIR="$HOME/.local/state/dotfiles"
    
    mkdir -p "$STATE_DIR"
    # Note: migrations are tracked as files in $STATE_DIR/migrations/ directory
    # The lib/state.sh handles creating this directory structure
    
    LOG "State directory initialized"
}

# =============================================================================
# Main
# =============================================================================
main() {
    LOG "Starting migration to new dotfiles structure..."
    LOG "Backup directory: $BACKUP_DIR"
    echo ""
    
    init_state
    install_new_bin_scripts
    install_lib
    install_default_configs
    update_hyprland_keybinds
    update_waybar_config
    update_zshrc
    cleanup_old_scripts
    
    echo ""
    LOG "Migration complete!"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        LOG "Old files backed up to: $BACKUP_DIR"
    fi
    
    LOG "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

main

#!/bin/bash
# Migration: Hyprland Config Layering
# ====================================
# Migrates existing Hyprland config to the new layered structure:
#   - core/  : Default configs (updated by dotfiles)
#   - local/ : User customizations (never touched)
#
# This migration:
# 1. Creates core/ and local/ directories
# 2. Moves existing config files to core/
# 3. Updates hyprland.conf to use the layered structure
# 4. Creates example local/custom.conf

set -euo pipefail

HYPR_DIR="$HOME/.config/hypr"
CORE_DIR="$HYPR_DIR/core"
LOCAL_DIR="$HYPR_DIR/local"
BACKUP_DIR="${STATE_DIR:-$HOME/.local/state/dotfiles}/backups/migrations/20250526_hyprland_config_layering"

log_info() {
    echo "[MIGRATION] $1"
}

log_warn() {
    echo "[MIGRATION] WARNING: $1"
}

# Files that should be moved to core/
CORE_FILES=(
    "appearance.conf"
    "autostart.conf"
    "environment.conf"
    "input.conf"
    "keybinds.conf"
    "layout.conf"
    "programs.conf"
    "windowrules.conf"
)

# Files that stay at root level (hardware-specific)
ROOT_FILES=(
    "monitors.conf"
    "nvidia.conf"
    "hypridle.conf"
    "hyprlock.conf"
    "hyprland.conf"
)

main() {
    log_info "Starting Hyprland config layering migration..."
    
    # Check if Hyprland config exists
    if [[ ! -d "$HYPR_DIR" ]]; then
        log_info "No Hyprland config directory found, skipping migration"
        exit 0
    fi
    
    # Check if already migrated (core/ directory exists with files)
    if [[ -d "$CORE_DIR" ]] && [[ -n "$(ls -A "$CORE_DIR" 2>/dev/null)" ]]; then
        log_info "Config already uses layered structure, skipping migration"
        exit 0
    fi
    
    # Create backup
    log_info "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$HYPR_DIR" "$BACKUP_DIR/hypr_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Create directories
    log_info "Creating core/ and local/ directories..."
    mkdir -p "$CORE_DIR"
    mkdir -p "$LOCAL_DIR"
    
    # Move core files
    log_info "Moving config files to core/..."
    for file in "${CORE_FILES[@]}"; do
        if [[ -f "$HYPR_DIR/$file" ]]; then
            mv "$HYPR_DIR/$file" "$CORE_DIR/"
            log_info "  Moved $file to core/"
        fi
    done
    
    # Update hyprland.conf to use new structure
    log_info "Updating hyprland.conf..."
    if [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
        # Get the repo's hyprland.conf as template
        local REPO_ROOT="${REPO_ROOT:-$HOME/.local/bin/dotfiles}"
        if [[ -f "$REPO_ROOT/.config/hypr/hyprland.conf" ]]; then
            cp "$REPO_ROOT/.config/hypr/hyprland.conf" "$HYPR_DIR/hyprland.conf"
            log_info "  Updated hyprland.conf with layered structure"
        else
            log_warn "Could not find repo hyprland.conf template"
        fi
    fi
    
    # Create example local config
    if [[ ! -f "$LOCAL_DIR/custom.conf" ]]; then
        cat > "$LOCAL_DIR/custom.conf" << 'EOF'
# Hyprland Local Customizations
# =============================
# Add your personal Hyprland settings here.
# These settings override the core defaults and survive updates.
#
# You can also create these files to override specific configs:
#   programs.conf     - Override $terminal, $menu, $browser, etc.
#   keybinds.conf     - Add or override keybindings
#   appearance.conf   - Custom colors, borders, gaps, animations
#   autostart.conf    - Additional autostart applications
#   environment.conf  - Additional environment variables
#   input.conf        - Custom input device settings
#   layout.conf       - Custom layout settings
#   windowrules.conf  - Additional window rules
#
# Example overrides:
# $terminal = kitty
# $browser = firefox
#
# bind = $mainMod, P, exec, my-custom-script
EOF
        log_info "Created local/custom.conf"
    fi
    
    log_info "Migration complete!"
    log_info ""
    log_info "Your Hyprland config now uses a layered structure:"
    log_info "  ~/.config/hypr/core/   - Default configs (updated by dotfiles)"
    log_info "  ~/.config/hypr/local/  - Your customizations (never touched)"
    log_info ""
    log_info "To customize, create files in local/ that override core/ settings."
    log_info "Backup saved to: $BACKUP_DIR"
}

main "$@"

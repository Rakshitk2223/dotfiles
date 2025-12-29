#!/bin/bash
# Install dotfiles to the user's home directory
# This script copies config files, bin scripts, and shell configs

set -euo pipefail

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source state library
source "$REPO_ROOT/lib/state.sh"

# Source hooks library
source "$REPO_ROOT/lib/hooks.sh"

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
    exit 1
}

install_config_files() {
    log_info "Installing config files to ~/.config..."
    local CONFIG_SOURCE="$REPO_ROOT/.config"
    local CONFIG_DEST="$HOME/.config"

    mkdir -p "$CONFIG_DEST"
    rsync -avh --exclude '.git' --exclude '.gitmodules' "$CONFIG_SOURCE/" "$CONFIG_DEST/"
    
    # Make waybar scripts executable
    if [[ -d "$CONFIG_DEST/waybar/scripts" ]]; then
        find "$CONFIG_DEST/waybar/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    fi
    
    log_info "Config files installed."
}

install_bin_scripts() {
    log_info "Installing bin scripts to ~/.local/bin..."
    local BIN_SOURCE="$REPO_ROOT/bin"
    local BIN_DEST="$HOME/.local/bin"

    mkdir -p "$BIN_DEST"
    
    # Copy all dotfiles-* scripts from bin/
    for script in "$BIN_SOURCE"/dotfiles-*; do
        if [[ -f "$script" ]]; then
            cp "$script" "$BIN_DEST/"
            chmod +x "$BIN_DEST/$(basename "$script")"
        fi
    done
    
    log_info "Bin scripts installed and made executable."
}

install_home_dotfiles() {
    log_info "Installing .tmux.conf and .zshrc to $HOME..."
    rsync -avh "$REPO_ROOT/.tmux.conf" "$HOME/"
    rsync -avh "$REPO_ROOT/.zshrc" "$HOME/"
    log_info ".tmux.conf and .zshrc installed."
}

install_default_configs() {
    log_info "Installing default zsh configs..."
    local DEFAULT_SOURCE="$REPO_ROOT/default"
    local DEFAULT_DEST="$HOME/.local/bin/dotfiles/default"
    
    # Ensure the dotfiles directory structure exists
    mkdir -p "$DEFAULT_DEST"
    
    if [[ -d "$DEFAULT_SOURCE" ]]; then
        rsync -avh "$DEFAULT_SOURCE/" "$DEFAULT_DEST/"
        log_info "Default configs installed."
    fi
}

install_lib() {
    log_info "Installing lib scripts..."
    local LIB_SOURCE="$REPO_ROOT/lib"
    local LIB_DEST="$HOME/.local/bin/dotfiles/lib"
    
    mkdir -p "$LIB_DEST"
    
    if [[ -d "$LIB_SOURCE" ]]; then
        rsync -avh "$LIB_SOURCE/" "$LIB_DEST/"
        log_info "Lib scripts installed."
    fi
}

install_themes() {
    log_info "Installing themes..."
    local THEMES_SOURCE="$REPO_ROOT/themes"
    local THEMES_DEST="$HOME/.local/bin/dotfiles/themes"
    
    mkdir -p "$THEMES_DEST"
    
    if [[ -d "$THEMES_SOURCE" ]]; then
        rsync -avh "$THEMES_SOURCE/" "$THEMES_DEST/"
        log_info "Themes installed."
    fi
}

install_wallpapers() {
    log_info "Installing wallpapers..."
    local WALLPAPERS_SOURCE="$REPO_ROOT/Wallpapers"
    local WALLPAPERS_DEST="$HOME/.local/bin/dotfiles/Wallpapers"
    
    mkdir -p "$WALLPAPERS_DEST"
    
    if [[ -d "$WALLPAPERS_SOURCE" ]]; then
        rsync -avh "$WALLPAPERS_SOURCE/" "$WALLPAPERS_DEST/"
        log_info "Wallpapers installed."
    fi
}

setup_default_theme() {
    log_info "Setting up default theme..."
    local DOTFILES_DIR="$HOME/.local/bin/dotfiles"
    local THEMES_DIR="$DOTFILES_DIR/themes"
    local WALLPAPERS_DIR="$DOTFILES_DIR/Wallpapers"
    local CURRENT_WALLPAPER_LINK="$HOME/.cache/current_wallpaper"
    
    # Default wallpaper from custom folder
    local DEFAULT_WALLPAPER="$WALLPAPERS_DIR/custom/darek-zabrocki-ka-blockade-5c-darekzabrocki.jpg"
    
    # Only set default theme on fresh install (no current symlink)
    if [[ ! -L "$THEMES_DIR/current" ]]; then
        # Set wallpaper first
        mkdir -p "$HOME/.cache"
        
        if [[ -f "$DEFAULT_WALLPAPER" ]]; then
            ln -snf "$DEFAULT_WALLPAPER" "$CURRENT_WALLPAPER_LINK"
            log_info "Default wallpaper set: $(basename "$DEFAULT_WALLPAPER")"
            
            # Set wallpaper with swww if available and running in graphical session
            if command -v swww &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                if ! pgrep -x swww-daemon &>/dev/null; then
                    swww-daemon &
                    disown
                    sleep 0.5
                fi
                swww img "$DEFAULT_WALLPAPER" --transition-type fade --transition-duration 1 2>/dev/null || true
            fi
            
            # Generate wallpaper theme if wallust is available
            if command -v wallust &>/dev/null; then
                log_info "Generating theme from wallpaper..."
                if [[ -x "$DOTFILES_DIR/bin/dotfiles-theme-generate" ]]; then
                    "$DOTFILES_DIR/bin/dotfiles-theme-generate" 2>/dev/null || log_info "Theme generation skipped (will run on first login)"
                fi
            fi
            
            # Set wallpaper as the default theme
            if [[ -d "$THEMES_DIR/wallpaper" ]]; then
                ln -snf "$THEMES_DIR/wallpaper" "$THEMES_DIR/current"
                log_info "Default theme set to: wallpaper (generated from custom wallpaper)"
            elif [[ -d "$THEMES_DIR/tokyo-night" ]]; then
                # Fallback to tokyo-night if wallpaper theme doesn't exist
                ln -snf "$THEMES_DIR/tokyo-night" "$THEMES_DIR/current"
                log_info "Default theme set to: tokyo-night (fallback)"
            fi
        else
            # Fallback: use tokyo-night theme
            if [[ -d "$THEMES_DIR/tokyo-night" ]]; then
                ln -snf "$THEMES_DIR/tokyo-night" "$THEMES_DIR/current"
                log_info "Default theme set to: tokyo-night"
                
                # Set tokyo-night wallpaper
                local wallpaper
                wallpaper=$(find "$WALLPAPERS_DIR/tokyo-night" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort | head -1)
                if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
                    ln -snf "$wallpaper" "$CURRENT_WALLPAPER_LINK"
                    log_info "Default wallpaper set: $(basename "$wallpaper")"
                fi
            fi
        fi
    else
        log_info "Theme already configured, skipping default setup."
    fi
}

install_legacy_scripts() {
    # Keep legacy scripts for backwards compatibility during transition
    log_info "Installing legacy scripts to ~/.local/bin/scripts..."
    local SCRIPTS_SOURCE="$REPO_ROOT/.local/bin/scripts"
    local SCRIPTS_DEST="$HOME/.local/bin/scripts"

    if [[ -d "$SCRIPTS_SOURCE" ]]; then
        mkdir -p "$SCRIPTS_DEST"
        rsync -avh "$SCRIPTS_SOURCE/" "$SCRIPTS_DEST/"
        chmod +x "$SCRIPTS_DEST"/*.sh 2>/dev/null || true
        log_info "Legacy scripts installed."
    fi
}

setup_user_config_dirs() {
    log_info "Setting up user config directories..."
    local USER_CONFIG="$HOME/.config/dotfiles"
    
    # Create hook directories
    mkdir -p "$USER_CONFIG/hooks"
    mkdir -p "$USER_CONFIG/zsh"
    
    # Create example local config files if they don't exist
    if [[ ! -f "$USER_CONFIG/zsh/aliases.local" ]]; then
        cat > "$USER_CONFIG/zsh/aliases.local" << 'EOF'
# Add your personal aliases here
# These will be loaded after the default aliases
# Example:
# alias projects="cd ~/Projects"
EOF
        log_info "Created example aliases.local"
    fi
    
    if [[ ! -f "$USER_CONFIG/zsh/functions.local" ]]; then
        cat > "$USER_CONFIG/zsh/functions.local" << 'EOF'
# Add your personal functions here
# These will be loaded after the default functions
# Example:
# myfunc() {
#     echo "Hello from my custom function"
# }
EOF
        log_info "Created example functions.local"
    fi
    
    if [[ ! -f "$USER_CONFIG/zsh/shell.local" ]]; then
        cat > "$USER_CONFIG/zsh/shell.local" << 'EOF'
# Add your personal environment variables here
# These will be loaded after the default shell config
# Example:
# export MY_VAR="my value"
# export PATH="$HOME/my-tools/bin:$PATH"
EOF
        log_info "Created example shell.local"
    fi
    
    log_info "User config directories ready."
}

create_first_run_flag() {
    log_info "Creating first-run flag for GTK setup..."
    local STATE_DIR="$HOME/.local/state/dotfiles"
    mkdir -p "$STATE_DIR"
    touch "$STATE_DIR/first-run.mode"
    log_info "First-run flag created. GTK settings will be applied on first login."
}

setup_hypr_local_dir() {
    log_info "Setting up Hyprland local config directory..."
    local HYPR_LOCAL="$HOME/.config/hypr/local"
    local HYPR_DIR="$HOME/.config/hypr"
    
    # Create local directory for user overrides
    mkdir -p "$HYPR_LOCAL"
    
    # Detect NVIDIA GPU
    local has_nvidia=false
    if command -v lspci &>/dev/null; then
        if lspci | grep -qi "nvidia"; then
            has_nvidia=true
            log_info "NVIDIA GPU detected"
        fi
    fi
    
    # Detect ASUS laptop
    local is_asus=false
    if [[ -f /sys/class/dmi/id/sys_vendor ]]; then
        local vendor
        vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
        if [[ "$vendor" == *"ASUS"* ]] || [[ "$vendor" == *"ASUSTeK"* ]]; then
            is_asus=true
            log_info "ASUS laptop detected"
        fi
    fi
    
    # Create hardware-specific config files if they don't exist
    # These are machine-specific and sourced by hyprland.conf
    if [[ ! -f "$HYPR_DIR/monitors.conf" ]]; then
        cat > "$HYPR_DIR/monitors.conf" << 'EOF'
# Monitor Configuration
# =====================
# Configure your monitors here.
# Run 'hyprctl monitors' to see available monitors.
#
# Format: monitor = name, resolution@rate, position, scale
# Example:
# monitor = DP-1, 1920x1080@144, 0x0, 1
# monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1
#
# For automatic configuration:
monitor = , preferred, auto, 1
EOF
        log_info "Created monitors.conf template"
    fi
    
    if [[ ! -f "$HYPR_DIR/nvidia.conf" ]]; then
        if [[ "$has_nvidia" == "true" ]]; then
            # NVIDIA detected - create config with settings ENABLED
            cat > "$HYPR_DIR/nvidia.conf" << 'EOF'
# NVIDIA Configuration
# ====================
# NVIDIA GPU detected - settings enabled automatically

# Core NVIDIA environment variables
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = __GL_VRR_ALLOWED,1

# Use NVIDIA GBM backend (required for newer drivers)
env = GBM_BACKEND,nvidia-drm
env = NVD_BACKEND,direct

# Electron/Chromium apps Wayland support
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# Disable atomic mode setting (can help with some display issues)
env = WLR_DRM_NO_ATOMIC,1

# Hardware cursor fix for NVIDIA
cursor:no_hardware_cursors = true
EOF
            log_info "Created nvidia.conf with NVIDIA settings ENABLED"
        else
            # No NVIDIA - create template with settings commented
            cat > "$HYPR_DIR/nvidia.conf" << 'EOF'
# NVIDIA Configuration
# ====================
# Uncomment the following lines if you have an NVIDIA GPU:
#
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = __GL_VRR_ALLOWED,1
# env = GBM_BACKEND,nvidia-drm
# env = NVD_BACKEND,direct
# env = ELECTRON_OZONE_PLATFORM_HINT,auto
# env = WLR_DRM_NO_ATOMIC,1
#
# cursor:no_hardware_cursors = true
EOF
            log_info "Created nvidia.conf template (no NVIDIA detected)"
        fi
    fi
    
    # Create ASUS-specific config if ASUS laptop detected
    # Non-ASUS laptops will auto-detect GPU order
    if [[ ! -f "$HYPR_DIR/asus.conf" ]]; then
        if [[ "$is_asus" == "true" ]]; then
            # ASUS detected - create config with hardcoded DRM device order
            cat > "$HYPR_DIR/asus.conf" << 'EOF'
# ASUS-specific configuration
# ===========================
# ASUS laptop detected - hardcoded DRM device order for supergfxctl compatibility
# card0 = NVIDIA, card1 = AMD (typical ASUS ROG/TUF configuration)

env = AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1
EOF
            log_info "Created asus.conf with ASUS-specific settings"
        else
            # Non-ASUS - create empty file (Hyprland auto-detects GPU order)
            cat > "$HYPR_DIR/asus.conf" << 'EOF'
# ASUS-specific configuration
# ===========================
# This file is empty because no ASUS hardware was detected.
# Hyprland will auto-detect the GPU order.
# 
# If you have an ASUS laptop with supergfxctl, add:
# env = AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1
EOF
            log_info "Created empty asus.conf (non-ASUS system - GPU auto-detection enabled)"
        fi
    fi
    
    # Create empty placeholder files for all local configs
    # These are needed because Hyprland's source directive fails on missing files
    local local_configs=(
        "programs.conf"
        "keybinds.conf"
        "appearance.conf"
        "autostart.conf"
        "environment.conf"
        "input.conf"
        "layout.conf"
        "windowrules.conf"
    )
    
    for conf in "${local_configs[@]}"; do
        if [[ ! -f "$HYPR_LOCAL/$conf" ]]; then
            echo "# Local $conf - Add your overrides here" > "$HYPR_LOCAL/$conf"
        fi
    done
    
    # Create example custom.conf with documentation if it doesn't exist
    if [[ ! -f "$HYPR_LOCAL/custom.conf" ]]; then
        cat > "$HYPR_LOCAL/custom.conf" << 'EOF'
# Hyprland Local Customizations
# =============================
# Add your personal Hyprland settings here.
# These settings override the core defaults and survive updates.
#
# Available override files (already created as empty placeholders):
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
        log_info "Created example Hyprland local config"
    fi
    
    log_info "Hyprland local config directory ready."
}

main() {
    log_info "Starting dotfiles installation..."
    
    # Check if this is an upgrade (already installed)
    local is_upgrade=false
    if state_is_installed; then
        is_upgrade=true
        log_info "Existing installation detected, running as upgrade..."
    fi
    
    # Install lib first so migrations can use it
    install_lib
    
    # Run migrations if upgrading
    if $is_upgrade; then
        log_info "Checking for pending migrations..."
        migrations_run_all || {
            log_error "Migration failed, aborting installation"
        }
    fi
    
    install_config_files
    install_bin_scripts
    install_home_dotfiles
    install_default_configs
    install_legacy_scripts
    install_themes
    install_wallpapers
    setup_user_config_dirs
    setup_hypr_local_dir
    setup_default_theme
    
    # Create first-run flag for GTK settings (only on fresh install)
    if ! $is_upgrade; then
        create_first_run_flag
    fi
    
    # Record installation state
    log_info "Recording installation state..."
    state_record_install
    
    # Run post-install hook if it exists
    log_info "Running post-install hooks..."
    hook_run post-install || true
    
    log_info "Dotfiles installation complete!"
    log_info "Run 'dotfiles-version' to check installation status."
    log_info ""
    log_info "Customize your shell by editing files in ~/.config/dotfiles/zsh/"
    log_info "  - aliases.local    : Your custom aliases"
    log_info "  - functions.local  : Your custom functions"
    log_info "  - shell.local      : Your custom environment variables"
    log_info ""
    log_info "Customize Hyprland by creating files in ~/.config/hypr/local/"
    log_info "  - programs.conf    : Override default programs"
    log_info "  - keybinds.conf    : Add/override keybindings"
    log_info "  - custom.conf      : Any other settings"
    log_info ""
    log_info "Run 'dotfiles-refresh-config --help' for config management options."
}

main

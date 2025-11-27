#!/usr/bin/env bash
# Set default wallpaper on fresh install
set -euo pipefail

DOTFILES_DIR="$HOME/.local/bin/dotfiles"
WALLPAPERS_DIR="$DOTFILES_DIR/Wallpapers"
CURRENT_WALLPAPER_LINK="$HOME/.cache/current_wallpaper"

# Default wallpaper (custom folder, first zabrocki image)
DEFAULT_WALLPAPER="$WALLPAPERS_DIR/custom/darek-zabrocki-ka-blockade-5c-darekzabrocki.jpg"

# Source logging helpers if available
if [[ -f "$DOTFILES_DIR/scripts/helpers/logging.sh" ]]; then
    source "$DOTFILES_DIR/scripts/helpers/logging.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Check swww
if ! command -v swww &>/dev/null; then
    log_error "swww not found"
    exit 1
fi

# Start swww daemon if not running
if ! pgrep -x swww-daemon &>/dev/null; then
    swww-daemon &
    disown
    sleep 0.5
fi

# Check if wallpaper exists
if [[ ! -f "$DEFAULT_WALLPAPER" ]]; then
    log_error "Default wallpaper not found: $DEFAULT_WALLPAPER"
    exit 1
fi

# Set wallpaper
log_info "Setting wallpaper: $(basename "$DEFAULT_WALLPAPER")"
swww img "$DEFAULT_WALLPAPER" --transition-type fade --transition-duration 1

# Update symlink
ln -snf "$DEFAULT_WALLPAPER" "$CURRENT_WALLPAPER_LINK"

log_info "Wallpaper set successfully"

# Generate wallpaper theme if wallust is available
if command -v wallust &>/dev/null; then
    log_info "Generating theme from wallpaper..."
    if [[ -x "$DOTFILES_DIR/bin/dotfiles-theme-generate" ]]; then
        "$DOTFILES_DIR/bin/dotfiles-theme-generate" || log_warn "Theme generation failed"
    fi
fi

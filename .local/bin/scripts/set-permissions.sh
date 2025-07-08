#!/bin/bash
# Set permissions for various scripts in the dotfiles
# This script should be run at startup to ensure all scripts are executable

# Get the user's home directory
HOME_DIR="$HOME"

# Make hyprland scripts executable (now in .local/bin/scripts)
chmod +x "$HOME_DIR/.local/bin/scripts/mic-toggle.sh"
chmod +x "$HOME_DIR/.local/bin/scripts/screenshot.sh"  
chmod +x "$HOME_DIR/.local/bin/scripts/waybar-toggle.sh"
chmod +x "$HOME_DIR/.local/bin/scripts/set-permissions.sh"

# Make waybar scripts executable (these stay in waybar directory as they're waybar-specific)
chmod +x "$HOME_DIR/.config/waybar/scripts/microphone.sh"
chmod +x "$HOME_DIR/.config/waybar/scripts/updates.sh"

# Make any other utility scripts executable
chmod +x "$HOME_DIR/.local/bin/scripts"/*.sh 2>/dev/null || true
#!/bin/bash
# This script installs Hyprland and its recommended dependencies.

set -euo pipefail

# Install official Arch packages
echo "Installing official Arch packages..."
ARCH_PACKAGES=$(cat "$(dirname "$0")/arch_packages.txt")
sudo pacman -S --noconfirm --needed $ARCH_PACKAGES

# Install AUR packages using yay
echo "Installing AUR packages with yay..."
AUR_PACKAGES=$(cat "$(dirname "$0")/yay_packages.txt")
yay -S --noconfirm --needed $AUR_PACKAGES

if [ $? -eq 0 ]; then
    echo "Hyprland and dependencies installed successfully."
else
    echo "Error: Failed to install Hyprland and dependencies."
    exit 1
fi

#!/bin/bash
# This script installs the 'yay' AUR helper.

set -euo pipefail

# Check if yay is already installed
if command -v yay &> /dev/null; then
    echo "yay is already installed. Skipping installation."
    exit 0
fi

read -p "Do you want to install the 'yay' AUR helper? (y/N): " confirm_yay
if [[ "$confirm_yay" =~ ^[yY]$ ]]; then
    echo "Installing yay..."

    # Install git and base-devel if not present, required for building AUR packages
    echo "Ensuring git and base-devel are installed..."
    sudo pacman -S --noconfirm git base-devel

    # Create a temporary directory for building yay
    BUILD_DIR=$(mktemp -d)
    echo "Building yay in $BUILD_DIR"
    cd "$BUILD_DIR"

    # Clone yay repository
    git clone https://aur.archlinux.org/yay.git
    cd yay

    # Build and install yay
    # makepkg will prompt for sudo password if needed for installation
    makepkg -si --noconfirm

    # Clean up
    cd -
    rm -rf "$BUILD_DIR"

    if command -v yay &> /dev/null; then
        echo "yay installed successfully."
    else
        echo "Error: Failed to install yay."
        exit 1
    fi
else
    echo "Skipping yay installation."
    exit 0
fi

#!/bin/bash
# This script updates all system packages.

set -euo pipefail

read -p "Do you want to update system packages? (y/N): " confirm_update
if [[ "$confirm_update" =~ ^[yY]$ ]]; then
    echo "Updating system packages..."
    sudo pacman -Syu --noconfirm --needed
else
    echo "Skipping package update."
    exit 0
fi

if [ $? -eq 0 ]; then
    echo "System packages updated successfully."
else
    echo "Error: Failed to update system packages."
    exit 1
fi

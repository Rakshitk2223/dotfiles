#!/bin/bash
# This script installs Go and Rust programming languages from pacman.

set -euo pipefail

echo "Installing Go and Rust from official repositories..."

# Install Go and Rust via pacman
sudo pacman -S --noconfirm --needed go rust

if [ $? -eq 0 ]; then
    echo "Go and Rust installed successfully."
    
    # Display versions
    echo "Go version: $(go version)"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
else
    echo "Error: Failed to install Go and Rust."
    exit 1
fi
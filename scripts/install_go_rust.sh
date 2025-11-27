#!/bin/bash
# This script installs Go and Rust programming languages from pacman.

set -euo pipefail

# Check if both are already installed
go_installed=false
rust_installed=false

if command -v go &>/dev/null; then
    echo "Go is already installed. Version: $(go version)"
    go_installed=true
fi

if command -v rustc &>/dev/null; then
    echo "Rust is already installed. Version: $(rustc --version)"
    rust_installed=true
fi

# Exit if both are installed
if $go_installed && $rust_installed; then
    echo "Go and Rust are already installed. Skipping."
    exit 0
fi

# Build list of packages to install
packages=()
$go_installed || packages+=(go)
$rust_installed || packages+=(rust)

echo "Installing: ${packages[*]}..."

# Install via pacman with --needed flag
sudo pacman -S --noconfirm --needed "${packages[@]}"

if [ $? -eq 0 ]; then
    echo "Installation successful."
    
    # Display versions
    command -v go &>/dev/null && echo "Go version: $(go version)"
    command -v rustc &>/dev/null && echo "Rust version: $(rustc --version)"
    command -v cargo &>/dev/null && echo "Cargo version: $(cargo --version)"
else
    echo "Error: Failed to install packages."
    exit 1
fi
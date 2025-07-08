#!/bin/bash
# This script installs Node.js via nvm (Node Version Manager).

set -euo pipefail

echo "Installing Node.js via nvm..."

# Check if nvm is already installed
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "nvm is already installed. Loading nvm..."
    \. "$HOME/.nvm/nvm.sh"
else
    echo "Downloading and installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install nvm."
        exit 1
    fi
    
    # Load nvm for this session
    \. "$HOME/.nvm/nvm.sh"
fi

# Verify nvm is available
if ! command -v nvm &> /dev/null; then
    echo "Error: nvm command not found after installation."
    exit 1
fi

echo "Installing Node.js version 24..."
nvm install 24

if [ $? -eq 0 ]; then
    echo "Node.js installed successfully."
    
    # Set Node 24 as default
    nvm use 24
    nvm alias default 24
    
    # Display versions
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
else
    echo "Error: Failed to install Node.js."
    exit 1
fi
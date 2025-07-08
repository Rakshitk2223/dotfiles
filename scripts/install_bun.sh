#!/bin/bash
# This script installs Bun JavaScript runtime.

set -euo pipefail

echo "Installing Bun JavaScript runtime..."

# Check if bun is already installed
if command -v bun &> /dev/null; then
    echo "Bun is already installed. Version: $(bun --version)"
    exit 0
fi

echo "Downloading and installing Bun..."
echo "Downloading Bun installation script..."
curl -fsSL https://bun.sh/install -o /tmp/install_bun.sh

echo "Executing Bun installation script..."
bash /tmp/install_bun.sh

rm /tmp/install_bun.sh

if [ $? -ne 0 ]; then
    echo "Error: Failed to install Bun."
    exit 1
fi

# Add bun to PATH for current session if not already there
if [[ ":$PATH:" != *":$HOME/.bun/bin:"* ]]; then
    export PATH="$HOME/.bun/bin:$PATH"
fi

# Verify installation
if command -v bun &> /dev/null; then
    echo "Bun installed successfully."
    echo "Bun version: $(bun --version)"
else
    echo "Warning: Bun installed but not found in PATH. You may need to restart your shell or source your shell configuration."
    echo "Add this to your shell profile: export PATH=\"\$HOME/.bun/bin:\$PATH\""
fi
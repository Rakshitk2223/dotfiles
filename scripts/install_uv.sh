#!/bin/bash
# This script installs uv Python package installer.

set -euo pipefail

echo "Installing uv Python package installer..."

# Check if uv is already installed
if command -v uv &> /dev/null; then
    echo "uv is already installed. Version: $(uv --version)"
    exit 0
fi

echo "Downloading and installing uv..."
echo "Downloading uv installation script..."
curl -LsSf https://astral.sh/uv/install.sh -o /tmp/install_uv.sh

echo "Executing uv installation script..."
sh /tmp/install_uv.sh

rm /tmp/install_uv.sh

if [ $? -ne 0 ]; then
    echo "Error: Failed to install uv."
    exit 1
fi

# Add uv to PATH for current session if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify installation
if command -v uv &> /dev/null; then
    echo "uv installed successfully."
    echo "uv version: $(uv --version)"
else
    echo "Warning: uv installed but not found in PATH. You may need to restart your shell or source your shell configuration."
    echo "Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
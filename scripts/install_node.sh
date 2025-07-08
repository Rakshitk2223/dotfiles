#!/bin/bash
# This script installs Node.js via nvm (Node Version Manager).

set -euo pipefail

export NVM_DIR="$HOME/.nvm"

log_info() {
    echo "[INFO] $1"
}

# Ensure the nvm directory exists
mkdir -p "$NVM_DIR"

# Check if nvm is already installed
if [ -s "$NVM_DIR/nvm.sh" ]; then
    log_info "nvm is already installed. Sourcing it..."
else
    log_info "Downloading and installing nvm..."
    # Use the version from the official documentation
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

# Source nvm to make it available in this script session
# This is a critical step to prevent the script from hanging
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
else
    echo "[ERROR] nvm.sh not found after installation attempt."
    exit 1
fi

# Now, use nvm to install Node.js
log_info "Installing or verifying Node.js version 24..."
nvm install 24

# Set Node 24 as the default version
log_info "Setting Node.js v24 as default..."
nvm use 24
nvm alias default 24

log_info "Node.js installation complete."
log_info "Node version: $(node -v)"
log_info "npm version: $(npm -v)"

#!/bin/bash
# This script installs Go and Rust programming languages.
# Go: from pacman
# Rust: via rustup (official installer)

set -euo pipefail

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# Check if Go is installed
install_go() {
    if command -v go &>/dev/null; then
        log_info "Go is already installed. Version: $(go version)"
        return 0
    fi
    
    log_info "Installing Go..."
    if sudo pacman -S --noconfirm --needed go; then
        log_info "Go installed successfully."
        log_info "Go version: $(go version)"
    else
        log_error "Failed to install Go."
        return 1
    fi
}

# Check if Rust is installed (via rustup)
install_rust() {
    if command -v rustc &>/dev/null; then
        log_info "Rust is already installed. Version: $(rustc --version)"
        log_info "Cargo version: $(cargo --version)"
        return 0
    fi
    
    log_info "Installing Rust via rustup..."
    
    # Install rustup if not present
    if ! command -v rustup &>/dev/null; then
        # Download and run rustup installer (non-interactive)
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path; then
            log_info "Rustup installed successfully."
        else
            log_error "Failed to install rustup."
            return 1
        fi
        
        # Source cargo env for current session
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
        fi
    fi
    
    # Verify installation
    if command -v rustc &>/dev/null; then
        log_info "Rust installed successfully."
        log_info "Rust version: $(rustc --version)"
        log_info "Cargo version: $(cargo --version)"
    else
        log_warn "Rust installed but not in PATH. Add to your shell config:"
        log_warn '  source "$HOME/.cargo/env"'
    fi
}

# Main
main() {
    log_info "Installing Go and Rust..."
    
    install_go || log_warn "Go installation had issues"
    install_rust || log_warn "Rust installation had issues"
    
    log_info "Done!"
}

main
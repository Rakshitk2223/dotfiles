#!/bin/bash
# Install Docker and Docker Compose for container management
# This script installs Docker, enables the service, and configures user permissions

set -euo pipefail

# Source logging helpers if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/helpers/logging.sh" ]]; then
    source "$SCRIPT_DIR/helpers/logging.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root. Run as normal user."
    exit 1
fi

# Check if Docker is already installed
check_existing() {
    if command -v docker &>/dev/null; then
        local version
        version=$(docker --version 2>/dev/null || echo "unknown")
        log_warn "Docker is already installed: $version"
        
        read -rp "Do you want to reinstall/update? [y/N]: " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi
}

# Install Docker packages
install_packages() {
    log_info "Installing Docker packages..."
    
    local packages=(
        docker
        docker-compose
        docker-buildx
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    log_info "Packages installed successfully"
}

# Enable and start Docker service
enable_services() {
    log_info "Enabling and starting Docker service..."
    
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now containerd.service
    
    log_info "Services enabled and started"
}

# Configure user permissions
configure_user() {
    log_info "Adding user to docker group..."
    
    sudo usermod -aG docker "$USER"
    
    log_info "User '$USER' added to docker group"
}

# Verify installation
verify_installation() {
    log_info "Verifying Docker installation..."
    
    # Check Docker daemon status
    if systemctl is-active --quiet docker; then
        log_info "Docker daemon is running"
    else
        log_warn "Docker daemon is not running. May need reboot."
    fi
    
    # Show versions
    log_info "Docker version: $(docker --version 2>/dev/null || echo 'requires relogin')"
    log_info "Docker Compose version: $(docker compose version 2>/dev/null || echo 'requires relogin')"
}

# Show completion message
show_completion() {
    echo ""
    echo "========================================"
    echo "    Docker Installation Complete!"
    echo "========================================"
    echo ""
    echo "Installed components:"
    echo "  - docker (container runtime)"
    echo "  - docker-compose (multi-container orchestration)"
    echo "  - docker-buildx (extended build capabilities)"
    echo ""
    echo "IMPORTANT: You must log out and log back in"
    echo "(or reboot) for group changes to take effect."
    echo ""
    echo "After relogin, test with: docker run hello-world"
    echo ""
    echo "Useful commands:"
    echo "  docker ps              - List running containers"
    echo "  docker images          - List images"
    echo "  docker compose up -d   - Start compose services"
    echo ""
}

# Main
main() {
    log_info "Starting Docker installation..."
    
    check_existing
    install_packages
    enable_services
    configure_user
    verify_installation
    
    show_completion
}

main

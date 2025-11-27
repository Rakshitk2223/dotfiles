#!/bin/bash
# Install Virt-Manager with QEMU/KVM for virtualization
# This script installs and configures libvirt, QEMU, and virt-manager

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

# Check hardware virtualization support
check_virtualization() {
    log_info "Checking hardware virtualization support..."
    
    local virt_support
    virt_support=$(LC_ALL=C lscpu | grep -i "Virtualization" || echo "")
    
    if [[ -z "$virt_support" ]]; then
        log_error "Hardware virtualization not detected!"
        log_error "Please enable VT-x (Intel) or AMD-V (AMD) in your BIOS/UEFI settings."
        exit 1
    fi
    
    log_info "Virtualization support detected: $virt_support"
    
    # Check KVM modules
    if lsmod | grep -q kvm; then
        log_info "KVM modules loaded successfully"
    else
        log_warn "KVM modules not loaded. They will be loaded after reboot."
    fi
}

# Install required packages
install_packages() {
    log_info "Installing virtualization packages..."
    
    local packages=(
        libvirt
        virt-manager
        qemu-full
        dnsmasq
        dmidecode
        iptables-nft
        edk2-ovmf
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    log_info "Packages installed successfully"
}

# Enable and start services
enable_services() {
    log_info "Enabling and starting libvirt services..."
    
    sudo systemctl enable --now libvirtd.service
    sudo systemctl enable --now virtlogd.service
    
    log_info "Services enabled and started"
}

# Configure user permissions
configure_user() {
    log_info "Adding user to libvirt group..."
    
    sudo usermod -aG libvirt "$USER"
    
    log_info "User '$USER' added to libvirt group"
}

# Configure default network
configure_network() {
    log_info "Configuring default virtual network..."
    
    # Wait a moment for libvirtd to fully start
    sleep 2
    
    # Set default network to autostart
    sudo virsh net-autostart default 2>/dev/null || log_warn "Could not set network autostart (may already be set)"
    
    # Start default network if not running
    if ! sudo virsh net-list | grep -q "default.*active"; then
        sudo virsh net-start default 2>/dev/null || log_warn "Could not start default network (may need reboot)"
    fi
    
    log_info "Network configuration complete"
}

# Show completion message
show_completion() {
    echo ""
    echo "========================================"
    echo "  Virt-Manager Installation Complete!"
    echo "========================================"
    echo ""
    echo "Installed components:"
    echo "  - libvirt (virtualization API)"
    echo "  - QEMU/KVM (hypervisor)"
    echo "  - virt-manager (GUI)"
    echo "  - dnsmasq (virtual networking)"
    echo ""
    echo "IMPORTANT: You must log out and log back in"
    echo "(or reboot) for group changes to take effect."
    echo ""
    echo "After reboot, launch with: virt-manager"
    echo ""
}

# Main
main() {
    log_info "Starting Virt-Manager installation..."
    
    check_virtualization
    install_packages
    enable_services
    configure_user
    configure_network
    
    show_completion
}

main

#!/bin/bash
# Package installation module for dotfiles
# Handles pacman and AUR packages

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source helpers
source "$REPO_ROOT/scripts/helpers/logging.sh"
source "$REPO_ROOT/scripts/helpers/errors.sh"

# Package lists
ARCH_PACKAGES_FILE="$REPO_ROOT/scripts/arch_packages.txt"
AUR_PACKAGES_FILE="$REPO_ROOT/scripts/yay_packages.txt"

# Read packages from file, ignoring comments and empty lines
read_package_list() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep -vE '^\s*#|^\s*$' "$file" 2>/dev/null || true
    fi
}

# Check if package is installed (pacman)
is_installed() {
    pacman -Q "$1" &>/dev/null
}

# Check if AUR package is installed
is_aur_installed() {
    yay -Q "$1" &>/dev/null
}

# Install yay if not present
install_yay() {
    log_substep "Checking for yay..."
    
    if command -v yay &>/dev/null; then
        log_list_item "ok" "yay already installed"
        return 0
    fi
    
    log_info "Installing yay (AUR helper)..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    (
        cd "$temp_dir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    )
    
    rm -rf "$temp_dir"
    
    if command -v yay &>/dev/null; then
        log_list_item "ok" "yay installed successfully"
        return 0
    else
        log_list_item "fail" "yay installation failed"
        return 1
    fi
}

# Install Arch packages from list
install_arch_packages() {
    log_substep "Installing Arch packages..."
    
    if [[ ! -f "$ARCH_PACKAGES_FILE" ]]; then
        log_warn "Package list not found: $ARCH_PACKAGES_FILE"
        return 0
    fi
    
    local packages=()
    local installed=0
    local to_install=()
    
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        packages+=("$pkg")
        
        if is_installed "$pkg"; then
            ((installed++))
        else
            to_install+=("$pkg")
        fi
    done < <(read_package_list "$ARCH_PACKAGES_FILE")
    
    log_info "Packages: ${#packages[@]} total, $installed installed, ${#to_install[@]} to install"
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_list_item "ok" "All Arch packages already installed"
        return 0
    fi
    
    log_info "Installing: ${to_install[*]}"
    
    local failed=()
    for pkg in "${to_install[@]}"; do
        if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
            log_list_item "ok" "$pkg"
        else
            log_list_item "fail" "$pkg"
            failed+=("$pkg")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "Failed to install: ${failed[*]}"
        return 1
    fi
    
    log_list_item "ok" "All Arch packages installed"
    return 0
}

# Install AUR packages from list
install_aur_packages() {
    log_substep "Installing AUR packages..."
    
    if ! command -v yay &>/dev/null; then
        log_warn "yay not installed, skipping AUR packages"
        return 0
    fi
    
    if [[ ! -f "$AUR_PACKAGES_FILE" ]]; then
        log_warn "Package list not found: $AUR_PACKAGES_FILE"
        return 0
    fi
    
    local packages=()
    local installed=0
    local to_install=()
    
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        packages+=("$pkg")
        
        if is_aur_installed "$pkg"; then
            ((installed++))
        else
            to_install+=("$pkg")
        fi
    done < <(read_package_list "$AUR_PACKAGES_FILE")
    
    log_info "AUR packages: ${#packages[@]} total, $installed installed, ${#to_install[@]} to install"
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_list_item "ok" "All AUR packages already installed"
        return 0
    fi
    
    log_info "Installing: ${to_install[*]}"
    
    if yay -S --noconfirm --needed "${to_install[@]}"; then
        log_list_item "ok" "All AUR packages installed"
        return 0
    else
        log_warn "Some AUR packages may have failed"
        return 1
    fi
}

# Install hardware-specific packages
install_hardware_packages() {
    local nvidia="${1:-false}"
    local asus="${2:-false}"
    
    if [[ "$nvidia" == "true" ]]; then
        log_substep "Installing NVIDIA packages..."
        local nvidia_pkgs=(nvidia-dkms nvidia-utils nvidia-settings libva-nvidia-driver)
        
        if sudo pacman -S --noconfirm --needed "${nvidia_pkgs[@]}"; then
            log_list_item "ok" "NVIDIA packages installed"
        else
            log_list_item "fail" "NVIDIA packages failed"
        fi
    fi
    
    if [[ "$asus" == "true" ]]; then
        log_substep "Installing ASUS packages..."
        
        if command -v yay &>/dev/null; then
            if yay -S --noconfirm --needed asusctl supergfxctl; then
                log_list_item "ok" "ASUS packages installed"
            else
                log_list_item "fail" "ASUS packages failed"
            fi
        else
            log_warn "yay required for ASUS packages"
        fi
    fi
}

# System update
update_system() {
    log_substep "Updating system packages..."
    
    if sudo pacman -Syu --noconfirm; then
        log_list_item "ok" "System updated"
        return 0
    else
        log_warn "System update had issues"
        return 1
    fi
}

# Main package installation
run_package_install() {
    local skip_system_update="${1:-false}"
    local install_nvidia="${2:-false}"
    local install_asus="${3:-false}"
    
    log_step "Installing packages..."
    
    # System update
    if [[ "$skip_system_update" != "true" ]]; then
        update_system || true
    fi
    
    # Install yay first
    install_yay || log_warn "Could not install yay"
    
    # Install packages
    install_arch_packages || true
    install_aur_packages || true
    
    # Hardware-specific
    install_hardware_packages "$install_nvidia" "$install_asus"
    
    log_success "Package installation complete"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_package_install "$@"
fi

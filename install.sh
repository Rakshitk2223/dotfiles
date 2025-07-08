#!/bin/bash
# This script automates the installation of a complete Arch Linux environment.

set -euo pipefail

# --- Script paths ---
BASE_DIR=$(dirname "$0")
SCRIPTS_DIR="$BASE_DIR/scripts"
ARCH_PACKAGES_FILE="$SCRIPTS_DIR/arch_packages.txt"
YAY_PACKAGES_FILE="$SCRIPTS_DIR/yay_packages.txt"

# --- Log functions ---
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
    exit 1
}

# --- Helper functions ---
check_command() {
    command -v "$1" &> /dev/null
}

# --- Installation functions ---

run_update_packages() {
    log_info "Running package update script..."
    bash "$SCRIPTS_DIR/update_packages.sh"
}

run_install_yay() {
    log_info "Running yay installation script..."
    bash "$SCRIPTS_DIR/install_yay.sh"
}

run_install_hardware_specific_packages() {
    # ASUS-specific packages
    read -p "Do you have an ASUS laptop? (y/N): " confirm_asus
    if [[ "$confirm_asus" =~ ^[yY]$ ]]; then
        log_info "Installing ASUS-specific packages..."
        yay -S --noconfirm --needed asusctl supergfxctl
    else
        log_info "Skipping ASUS-specific packages."
    fi

    # NVIDIA-specific packages
    read -p "Do you have an NVIDIA GPU? (y/N): " confirm_nvidia
    if [[ "$confirm_nvidia" =~ ^[yY]$ ]]; then
        log_info "Installing NVIDIA-specific packages..."
        sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils nvidia-settings libva-nvidia-driver
    else
        log_info "Skipping NVIDIA-specific packages."
    fi
}


run_install_arch_packages() {
    log_info "Installing packages from official repositories..."
    
    if [ ! -f "$ARCH_PACKAGES_FILE" ]; then
        log_error "$ARCH_PACKAGES_FILE not found."
    fi

    # Filter out already installed packages
    mapfile -t packages < <(grep -vE '^\s*#|^\s*$' "$ARCH_PACKAGES_FILE")
    packages_to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            packages_to_install+=("$pkg")
        else
            log_info "Package '$pkg' is already installed. Skipping."
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "Installing the following Arch packages: ${packages_to_install[*]}"
        sudo pacman -S --noconfirm --needed "${packages_to_install[@]}"
    else
        log_info "All Arch packages are already installed."
    fi
}

run_install_yay_packages() {
    log_info "Installing AUR packages with yay..."

    if ! check_command yay; then
        log_error "yay is not installed. Please install it first."
    fi

    if [ ! -f "$YAY_PACKAGES_FILE" ]; then
        log_error "$YAY_PACKAGES_FILE not found."
    fi

    # Filter out already installed packages
    mapfile -t packages < <(grep -vE '^\s*#|^\s*$' "$YAY_PACKAGES_FILE")
    packages_to_install=()
    for pkg in "${packages[@]}"; do
        if ! yay -Q "$pkg" &> /dev/null; then
            packages_to_install+=("$pkg")
        else
            log_info "Package '$pkg' is already installed. Skipping."
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "Installing the following AUR packages: ${packages_to_install[*]}"
        yay -S --noconfirm --needed "${packages_to_install[@]}"
    else
        log_info "All AUR packages are already installed."
    fi
}

run_install_dev_tools() {
    log_info "Installing development tools..."
    bash "$SCRIPTS_DIR/install_go_rust.sh"
    bash "$SCRIPTS_DIR/install_bun.sh"
    bash "$SCRIPTS_DIR/install_node.sh"
    bash "$SCRIPTS_DIR/install_uv.sh"
}

run_install_dotfiles() {
    log_info "Running dotfiles installation script..."
    bash "$SCRIPTS_DIR/install_dotfiles.sh"
}

make_scripts_executable() {
    log_info "Making scripts executable..."
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
}

update_submodules() {
    log_info "Initializing and updating Git submodules..."
    git submodule update --init --recursive
}

# --- Main execution ---
execute_installation() {
    # Ask for the administrator password upfront and run a keep-alive
    # to update the sudo timestamp until the script has finished.
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    log_info "Starting the installation process..."

    update_submodules
    make_scripts_executable
    run_update_packages
    run_install_yay
    run_install_hardware_specific_packages
    run_install_arch_packages
    run_install_yay_packages
    run_install_dev_tools

    run_install_tpm
    run_install_ohmyzsh

    run_install_themes
    run_apply_themes

    run_enable_services

    run_install_dotfiles
}

# --- Main execution ---
main() {
    if execute_installation; then
        log_info "Installation complete! Please reboot your system for all changes to take effect."
    else
        log_error "Installation failed. Please review the logs above and try again."
    fi
}

run_enable_services() {
    log_info "Enabling and starting services..."
    bash "$SCRIPTS_DIR/enable-services.sh"
}


run_apply_themes() {
    log_info "Applying themes..."
    bash "$SCRIPTS_DIR/apply-theme.sh"
}

run_install_themes() {
    log_info "Installing themes..."
    bash "$SCRIPTS_DIR/install_graphite_theme.sh"
}


run_install_ohmyzsh() {
    log_info "Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh is already installed."
    else
        sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended
    fi
}


run_install_tpm() {
    log_info "Installing tmux plugin manager (tpm)..."
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "tpm is already installed."
    else
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    log_info "To apply the changes, run 'tmux source ~/.tmux.conf' inside a tmux session."
}


main

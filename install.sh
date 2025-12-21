#!/bin/bash
# Dotfiles Installation Script
# Installs a complete Arch Linux + Hyprland environment
#
# Usage:
#   ./install.sh              # Interactive install
#   ./install.sh --minimal    # Skip optional packages
#   ./install.sh --help       # Show help

set -euo pipefail

# Script paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Source helper modules
source "$SCRIPTS_DIR/helpers/logging.sh"
source "$SCRIPTS_DIR/helpers/errors.sh"
source "$SCRIPTS_DIR/helpers/presentation.sh"

# Source install modules
source "$SCRIPTS_DIR/install/preflight.sh"
source "$SCRIPTS_DIR/install/packages.sh"
source "$SCRIPTS_DIR/install/hardware.sh"

# Installation options
SKIP_PREFLIGHT=false
SKIP_PACKAGES=false
SKIP_DEV_TOOLS=false
SKIP_THEMES=false
MINIMAL_INSTALL=false
AUTO_YES=false
DRY_RUN=false
INSTALL_NVIDIA=false
INSTALL_ASUS=false

# Error tracking
declare -a INSTALL_ERRORS=()
declare -a INSTALL_WARNINGS=()

show_help() {
    cat << EOF
Usage: install.sh [OPTIONS]

Install dotfiles and configure Arch Linux + Hyprland environment.

Options:
    -h, --help          Show this help message
    -y, --yes           Auto-confirm all prompts
    --dry-run           Show what would be done without making changes
    --minimal           Minimal install (skip optional packages, themes)
    --no-preflight      Skip preflight checks
    --no-packages       Skip package installation
    --no-dev-tools      Skip development tools (go, rust, node, etc.)
    --no-themes         Skip theme installation
    --nvidia            Install NVIDIA drivers (auto-detected if not specified)
    --asus              Install ASUS tools (auto-detected if not specified)

Examples:
    ./install.sh                    # Full interactive install
    ./install.sh -y                 # Auto-confirm everything
    ./install.sh --minimal          # Minimal install
    ./install.sh --nvidia --asus    # Include specific hardware support
EOF
}

# Track errors and warnings
track_error() {
    local message="$1"
    INSTALL_ERRORS+=("$message")
    log_error "$message"
}

track_warning() {
    local message="$1"
    INSTALL_WARNINGS+=("$message")
    log_warn "$message"
}

# Show installation summary with errors/warnings
show_install_summary() {
    echo ""
    
    if [[ ${#INSTALL_ERRORS[@]} -eq 0 ]] && [[ ${#INSTALL_WARNINGS[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo -e "${LOG_BOLD}${LOG_YELLOW}═══════════════════════════════════════════════════${LOG_NC}"
    echo -e "${LOG_BOLD}${LOG_YELLOW}                 Installation Summary              ${LOG_NC}"
    echo -e "${LOG_BOLD}${LOG_YELLOW}═══════════════════════════════════════════════════${LOG_NC}"
    echo ""
    
    if [[ ${#INSTALL_WARNINGS[@]} -gt 0 ]]; then
        echo -e "${LOG_YELLOW}${LOG_BOLD}Warnings (${#INSTALL_WARNINGS[@]}):${LOG_NC}"
        for warning in "${INSTALL_WARNINGS[@]}"; do
            echo -e "  ${LOG_YELLOW}⚠${LOG_NC} $warning"
        done
        echo ""
    fi
    
    if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
        echo -e "${LOG_RED}${LOG_BOLD}Errors (${#INSTALL_ERRORS[@]}):${LOG_NC}"
        for error in "${INSTALL_ERRORS[@]}"; do
            echo -e "  ${LOG_RED}✗${LOG_NC} $error"
        done
        echo ""
        echo -e "${LOG_DIM}These errors may need manual intervention.${LOG_NC}"
        echo -e "${LOG_DIM}Check the output above for details.${LOG_NC}"
        echo ""
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --minimal)
                MINIMAL_INSTALL=true
                SKIP_DEV_TOOLS=true
                SKIP_THEMES=true
                shift
                ;;
            --no-preflight)
                SKIP_PREFLIGHT=true
                shift
                ;;
            --no-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --no-dev-tools)
                SKIP_DEV_TOOLS=true
                shift
                ;;
            --no-themes)
                SKIP_THEMES=true
                shift
                ;;
            --nvidia)
                INSTALL_NVIDIA=true
                shift
                ;;
            --asus)
                INSTALL_ASUS=true
                shift
                ;;
            *)
                log_warn "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# Sudo keep-alive
setup_sudo() {
    log_substep "Setting up sudo access..."
    
    # Ask for sudo password upfront
    sudo -v
    
    # Keep sudo alive in background
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
}

# Initialize git submodules
init_submodules() {
    log_substep "Initializing git submodules..."
    
    if [[ -f "$BASE_DIR/.gitmodules" ]]; then
        git -C "$BASE_DIR" submodule update --init --recursive || true
    fi
}

# Make scripts executable
setup_permissions() {
    log_substep "Setting script permissions..."
    
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$BASE_DIR/bin" -type f -name "dotfiles-*" -exec chmod +x {} \; 2>/dev/null || true
}

# Hardware detection and confirmation
detect_hardware() {
    log_step "Detecting hardware..."
    
    # Run detection
    run_detection
    
    # Show summary
    show_detection_summary
    
    # Auto-set flags based on detection if not explicitly set
    if [[ "$INSTALL_NVIDIA" == "false" ]] && [[ "$HAS_NVIDIA" == "true" ]]; then
        if $AUTO_YES; then
            INSTALL_NVIDIA=true
        else
            if ask_yes_no "Install NVIDIA drivers?" "y"; then
                INSTALL_NVIDIA=true
            fi
        fi
    fi
    
    if [[ "$INSTALL_ASUS" == "false" ]] && [[ "$IS_ASUS" == "true" ]]; then
        if $AUTO_YES; then
            INSTALL_ASUS=true
        else
            if ask_yes_no "Install ASUS tools (asusctl, supergfxctl)?" "y"; then
                INSTALL_ASUS=true
            fi
        fi
    fi
}

# Install development tools
install_dev_tools() {
    log_substep "Installing development tools..."
    
    local tools=(
        "install_go_rust.sh"
        "install_bun.sh"
        "install_node.sh"
        "install_uv.sh"
    )
    
    for tool in "${tools[@]}"; do
        local script="$SCRIPTS_DIR/$tool"
        if [[ -x "$script" ]]; then
            log_info "Running $tool..."
            if ! bash "$script"; then
                track_warning "Dev tool script failed: $tool"
            fi
        fi
    done
}

# Install tmux plugin manager
install_tpm() {
    log_substep "Installing tmux plugin manager..."
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ -d "$tpm_dir" ]]; then
        log_list_item "ok" "tpm already installed"
    else
        if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
            log_list_item "ok" "tpm installed"
        else
            log_list_item "fail" "tpm installation failed"
            track_warning "TPM installation failed"
        fi
    fi
}

# Install Oh My Zsh
install_ohmyzsh() {
    log_substep "Installing Oh My Zsh..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_list_item "ok" "Oh My Zsh already installed"
        return 0
    fi
    
    # Ensure zsh is installed
    if ! command -v zsh &>/dev/null; then
        sudo pacman -S --noconfirm --needed zsh || {
            log_list_item "fail" "Could not install zsh"
            track_error "Zsh installation failed"
            return 1
        }
    fi
    
    # Install Oh My Zsh
    if sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended 2>/dev/null; then
        log_list_item "ok" "Oh My Zsh installed"
    else
        log_list_item "fail" "Oh My Zsh installation failed"
        track_warning "Oh My Zsh installation failed"
    fi
}

# Set default shell to zsh
set_default_shell() {
    log_substep "Setting default shell to zsh..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_list_item "ok" "zsh already default shell"
        return 0
    fi
    
    local zsh_path
    zsh_path=$(which zsh)
    
    if [[ -z "$zsh_path" ]]; then
        log_list_item "fail" "zsh not found in PATH"
        track_warning "Could not find zsh binary"
        return 1
    fi
    
    log_info "Changing default shell to zsh requires authentication..."
    log_info "You may be prompted for your password."
    
    if sudo chsh -s "$zsh_path" "$USER" 2>/dev/null; then
        log_list_item "ok" "Default shell set to zsh"
        log_info "Shell change will take effect after logout/login"
    else
        log_list_item "warn" "Could not change default shell automatically"
        track_warning "Run manually: sudo chsh -s $(which zsh) $USER"
    fi
}

# Install themes
install_themes() {
    log_substep "Installing themes..."
    
    local theme_scripts=(
        "install_graphite_theme.sh"
        "install_sddm_theme.sh"
    )
    
    for script in "${theme_scripts[@]}"; do
        local path="$SCRIPTS_DIR/$script"
        if [[ -x "$path" ]]; then
            if ! bash "$path" 2>/dev/null; then
                track_warning "Theme script failed: $script"
            fi
        fi
    done
    
    # Apply themes
    if [[ -x "$SCRIPTS_DIR/apply-theme.sh" ]]; then
        bash "$SCRIPTS_DIR/apply-theme.sh" 2>/dev/null || true
    fi
}

# Enable system services
enable_services() {
    log_substep "Enabling services..."
    
    if [[ -x "$SCRIPTS_DIR/enable-services.sh" ]]; then
        if ! bash "$SCRIPTS_DIR/enable-services.sh" 2>/dev/null; then
            track_warning "Some system services may have failed to enable"
        fi
    fi
}

# Setup wallpapers
setup_wallpapers() {
    log_substep "Setting up wallpapers..."
    
    [[ -x "$SCRIPTS_DIR/sync-wallpapers.sh" ]] && bash "$SCRIPTS_DIR/sync-wallpapers.sh" || true
    [[ -x "$SCRIPTS_DIR/set-wallpaper.sh" ]] && bash "$SCRIPTS_DIR/set-wallpaper.sh" || true
}

# Install dotfiles (configs, scripts, etc.)
install_dotfiles() {
    log_substep "Installing dotfiles..."
    
    if [[ -x "$SCRIPTS_DIR/install_dotfiles.sh" ]]; then
        bash "$SCRIPTS_DIR/install_dotfiles.sh"
    else
        log_error "install_dotfiles.sh not found"
        return 1
    fi
}

# Show post-install instructions
show_post_install() {
    echo ""
    show_completion "Installation complete!"
    
    echo "Next steps:"
    echo ""
    echo "  1. Reboot your system:"
    echo -e "     ${LOG_BOLD}sudo reboot${LOG_NC}"
    echo ""
    echo "  2. After reboot, reload tmux plugins:"
    echo -e "     ${LOG_BOLD}tmux source ~/.tmux.conf${LOG_NC}"
    echo -e "     Then press ${LOG_BOLD}prefix + I${LOG_NC} to install plugins"
    echo ""
    echo "  3. Check installation status:"
    echo -e "     ${LOG_BOLD}dotfiles-version${LOG_NC}"
    echo ""
    echo "  4. Customize your setup:"
    echo "     • Shell:    ~/.config/dotfiles/zsh/"
    echo "     • Hyprland: ~/.config/hypr/local/"
    echo ""
    echo "  5. Update dotfiles:"
    echo -e "     ${LOG_BOLD}dotfiles-update${LOG_NC}"
    echo ""
}

# Main installation flow
main() {
    parse_args "$@"
    
    # Show banner
    show_banner "Dotfiles Installer" "Arch Linux + Hyprland"
    
    # Dry run notice
    if $DRY_RUN; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Initialize progress
    init_progress 10
    
    # Step 1: Preflight checks
    show_progress "Preflight checks"
    if ! $SKIP_PREFLIGHT; then
        if ! run_preflight; then
            log_error "Preflight checks failed"
            show_rollback_help "preflight"
            exit 1
        fi
    else
        log_info "Skipping preflight checks"
    fi
    
    # Step 2: Setup
    show_progress "Initial setup"
    if ! $DRY_RUN; then
        setup_sudo
        init_submodules
        setup_permissions
    fi
    
    # Step 3: Hardware detection
    show_progress "Hardware detection"
    detect_hardware
    
    # Step 4: Package installation
    show_progress "Installing packages"
    if ! $SKIP_PACKAGES && ! $DRY_RUN; then
        run_package_install "false" "$INSTALL_NVIDIA" "$INSTALL_ASUS"
    else
        log_info "Skipping package installation"
    fi
    
    # Step 5: Development tools
    show_progress "Development tools"
    if ! $SKIP_DEV_TOOLS && ! $DRY_RUN; then
        install_dev_tools
    else
        log_info "Skipping development tools"
    fi
    
    # Step 6: Shell setup
    show_progress "Shell setup"
    if ! $DRY_RUN; then
        install_tpm
        install_ohmyzsh
        set_default_shell
    fi
    
    # Step 7: Themes
    show_progress "Installing themes"
    if ! $SKIP_THEMES && ! $DRY_RUN; then
        install_themes
    else
        log_info "Skipping themes"
    fi
    
    # Step 8: Services
    show_progress "Enabling services"
    if ! $DRY_RUN; then
        enable_services
    fi
    
    # Step 9: Wallpapers and dotfiles
    show_progress "Installing dotfiles"
    if ! $DRY_RUN; then
        setup_wallpapers
        install_dotfiles
    fi
    
    # Step 10: Done!
    show_progress "Finishing up"
    
    if $DRY_RUN; then
        log_info "Dry run complete - no changes were made"
    else
        show_post_install
        show_install_summary
    fi
}

# Run main
main "$@"

#!/bin/bash
# Bootstrap script for dotfiles installation
# Usage: curl -sL https://raw.githubusercontent.com/Rakshitk2223/dotfiles/main/boot.sh | bash
#
# Or with custom options:
#   curl -sL .../boot.sh | bash -s -- --branch dev
#   curl -sL .../boot.sh | bash -s -- --minimal

set -euo pipefail

# Configuration - Update these for your repo
REPO_URL="${DOTFILES_REPO:-https://github.com/Rakshitk2223/dotfiles.git}"
INSTALL_DIR="${DOTFILES_DIR:-$HOME/.local/bin/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_banner() {
    echo ""
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════╗
    ║                                                   ║
    ║      Dotfiles Bootstrap Installer                 ║
    ║                                                   ║
    ╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_help() {
    cat << EOF
Usage: boot.sh [OPTIONS]

Bootstrap installer for dotfiles.

Options:
    -h, --help          Show this help message
    -b, --branch NAME   Use specific branch (default: main)
    -d, --dir PATH      Install to specific directory
    --repo URL          Use custom repository URL
    --minimal           Minimal install (skip optional packages)
    --no-packages       Skip package installation
    --dry-run           Show what would be done

Environment variables:
    DOTFILES_REPO       Repository URL
    DOTFILES_DIR        Installation directory
    DOTFILES_BRANCH     Git branch to use

Example:
    # Default install
    curl -sL .../boot.sh | bash

    # Custom branch
    curl -sL .../boot.sh | bash -s -- --branch dev

    # Custom location
    curl -sL .../boot.sh | bash -s -- --dir ~/dotfiles
EOF
}

check_requirements() {
    log_info "Checking requirements..."
    
    local missing=()
    
    for cmd in git curl rsync; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Install with: sudo pacman -S --noconfirm --needed ${missing[*]}"
        
        # Attempt to auto-install if running as script (not piped from curl)
        if [[ -t 0 ]]; then
            log_info "Attempting to install missing packages..."
            if sudo pacman -S --noconfirm --needed "${missing[@]}" 2>/dev/null; then
                log_info "Required packages installed successfully"
            else
                log_error "Failed to install required packages. Please install manually."
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_warn "This installer is designed for Arch Linux"
        echo -n "Continue anyway? [y/N] "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || exit 1
    fi
}

clone_repo() {
    log_info "Cloning dotfiles repository..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warn "Directory already exists: $INSTALL_DIR"
        echo ""
        echo "What would you like to do?"
        echo "  1) Resume/update from existing installation (git pull)"
        echo "  2) Fresh install (remove and reinstall)"
        echo "  3) Abort installation"
        echo ""
        echo -n "Choice [1/2/3]: "
        read -r response
        
        case "$response" in
            1|"")
                log_info "Updating existing installation..."
                git -C "$INSTALL_DIR" fetch --all
                git -C "$INSTALL_DIR" checkout "$BRANCH"
                git -C "$INSTALL_DIR" pull --rebase
                return 0
                ;;
            2)
                log_info "Removing existing installation..."
                rm -rf "$INSTALL_DIR"
                ;;
            3|*)
                log_info "Installation aborted by user"
                exit 0
                ;;
        esac
    fi
    
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    if git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"; then
        log_info "Repository cloned to $INSTALL_DIR"
    else
        log_error "Failed to clone repository"
        exit 1
    fi
    
    # Initialize submodules
    if [[ -f "$INSTALL_DIR/.gitmodules" ]]; then
        log_info "Initializing submodules..."
        git -C "$INSTALL_DIR" submodule update --init --recursive
    fi
}

run_installer() {
    local install_args=("$@")
    
    log_info "Running installer..."
    
    if [[ -x "$INSTALL_DIR/install.sh" ]]; then
        cd "$INSTALL_DIR"
        bash install.sh "${install_args[@]}"
    else
        log_error "Installer not found: $INSTALL_DIR/install.sh"
        exit 1
    fi
}

main() {
    local branch="$BRANCH"
    local install_dir="$INSTALL_DIR"
    local repo_url="$REPO_URL"
    local install_args=()
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -d|--dir)
                install_dir="$2"
                shift 2
                ;;
            --repo)
                repo_url="$2"
                shift 2
                ;;
            --minimal)
                install_args+=(--minimal)
                shift
                ;;
            --no-packages)
                install_args+=(--no-packages)
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                install_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Update globals
    BRANCH="$branch"
    INSTALL_DIR="$install_dir"
    REPO_URL="$repo_url"
    
    show_banner
    
    echo "Configuration:"
    echo "  Repository: $REPO_URL"
    echo "  Branch:     $BRANCH"
    echo "  Directory:  $INSTALL_DIR"
    echo ""
    
    if $dry_run; then
        log_info "[DRY RUN] Would clone and install dotfiles"
        exit 0
    fi
    
    check_requirements
    clone_repo
    run_installer "${install_args[@]}"
    
    echo ""
    log_info "Bootstrap complete!"
    log_info "You may need to restart your shell or reboot for all changes to take effect."
}

main "$@"

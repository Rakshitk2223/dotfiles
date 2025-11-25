#!/bin/bash
# Preflight checks for dotfiles installation
# Verifies system requirements and dependencies

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source helpers
source "$REPO_ROOT/scripts/helpers/logging.sh"
source "$REPO_ROOT/scripts/helpers/errors.sh"

# Minimum requirements
MIN_BASH_VERSION="4.0"

# Required commands for installation
REQUIRED_COMMANDS=(
    "git"
    "curl"
    "rsync"
)

# Optional but recommended commands
RECOMMENDED_COMMANDS=(
    "zsh"
    "tmux"
)

# Check if running on Arch Linux
check_arch_linux() {
    log_substep "Checking for Arch Linux..."
    
    if [[ -f /etc/arch-release ]]; then
        log_list_item "ok" "Arch Linux detected"
        return 0
    elif [[ -f /etc/os-release ]]; then
        local distro
        distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        if [[ "$distro" == "arch" ]] || [[ "$distro" == "endeavouros" ]] || [[ "$distro" == "manjaro" ]]; then
            log_list_item "ok" "Arch-based distro detected: $distro"
            return 0
        fi
    fi
    
    log_list_item "fail" "Not running Arch Linux (some features may not work)"
    return 1
}

# Check bash version
check_bash_version() {
    log_substep "Checking Bash version..."
    
    local current_version="${BASH_VERSION%%(*}"
    local major_version="${current_version%%.*}"
    local required_major="${MIN_BASH_VERSION%%.*}"
    
    if [[ "$major_version" -ge "$required_major" ]]; then
        log_list_item "ok" "Bash $current_version (>= $MIN_BASH_VERSION)"
        return 0
    else
        log_list_item "fail" "Bash $current_version (need >= $MIN_BASH_VERSION)"
        return 1
    fi
}

# Check required commands
check_required_commands() {
    log_substep "Checking required commands..."
    
    local missing=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_list_item "ok" "$cmd"
        else
            log_list_item "fail" "$cmd (missing)"
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Install with: sudo pacman -S ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Check recommended commands
check_recommended_commands() {
    log_substep "Checking recommended commands..."
    
    local missing=()
    
    for cmd in "${RECOMMENDED_COMMANDS[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_list_item "ok" "$cmd"
        else
            log_list_item "skip" "$cmd (not installed)"
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Recommended but missing: ${missing[*]}"
    fi
    
    return 0
}

# Check if pacman is available
check_pacman() {
    log_substep "Checking package manager..."
    
    if command -v pacman &>/dev/null; then
        log_list_item "ok" "pacman available"
        return 0
    else
        log_list_item "fail" "pacman not found"
        return 1
    fi
}

# Check internet connectivity
check_internet() {
    log_substep "Checking internet connectivity..."
    
    if curl -s --connect-timeout 5 https://archlinux.org > /dev/null 2>&1; then
        log_list_item "ok" "Internet connection available"
        return 0
    else
        log_list_item "fail" "No internet connection"
        return 1
    fi
}

# Check disk space (at least 1GB free in home)
check_disk_space() {
    log_substep "Checking disk space..."
    
    local free_kb
    free_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    local free_mb=$((free_kb / 1024))
    
    if [[ $free_mb -ge 1024 ]]; then
        log_list_item "ok" "${free_mb}MB free in \$HOME"
        return 0
    else
        log_list_item "fail" "Only ${free_mb}MB free (need >= 1024MB)"
        return 1
    fi
}

# Check if running as root (should not be)
check_not_root() {
    log_substep "Checking user privileges..."
    
    if [[ $EUID -eq 0 ]]; then
        log_list_item "fail" "Running as root (don't do this!)"
        return 1
    else
        log_list_item "ok" "Running as normal user: $USER"
        return 0
    fi
}

# Check sudo access
check_sudo() {
    log_substep "Checking sudo access..."
    
    if sudo -n true 2>/dev/null; then
        log_list_item "ok" "Sudo access available (cached)"
        return 0
    elif sudo -v 2>/dev/null; then
        log_list_item "ok" "Sudo access available"
        return 0
    else
        log_list_item "fail" "No sudo access"
        return 1
    fi
}

# Main preflight check
run_preflight() {
    local errors=0
    local warnings=0
    
    log_step "Running preflight checks..."
    
    check_not_root || ((errors++))
    check_bash_version || ((errors++))
    check_arch_linux || ((warnings++))
    check_pacman || ((errors++))
    check_required_commands || ((errors++))
    check_recommended_commands || ((warnings++))
    check_internet || ((errors++))
    check_disk_space || ((errors++))
    check_sudo || ((errors++))
    
    echo ""
    
    if [[ $errors -gt 0 ]]; then
        log_error "Preflight failed with $errors error(s)"
        return 1
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Preflight passed with $warnings warning(s)"
        return 0
    else
        log_success "All preflight checks passed"
        return 0
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_preflight "$@"
fi

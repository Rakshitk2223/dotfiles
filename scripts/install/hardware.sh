#!/bin/bash
# Hardware detection module for dotfiles
# Auto-detects NVIDIA GPU, ASUS laptop, and other hardware

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source helpers if available
if [[ -f "$REPO_ROOT/scripts/helpers/logging.sh" ]]; then
    source "$REPO_ROOT/scripts/helpers/logging.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_substep() { echo "  -> $1"; }
fi

# Detection results (exported for use by other scripts)
export HAS_NVIDIA=false
export HAS_AMD_GPU=false
export HAS_INTEL_GPU=false
export IS_ASUS=false
export IS_LAPTOP=false
export IS_VM=false
export GPU_MODEL=""
export LAPTOP_MODEL=""

# Detect NVIDIA GPU
detect_nvidia() {
    log_substep "Checking for NVIDIA GPU..."
    
    # Check lspci for NVIDIA
    if command -v lspci &>/dev/null; then
        local nvidia_info
        nvidia_info=$(lspci | grep -i "nvidia" | head -1 || true)
        
        if [[ -n "$nvidia_info" ]]; then
            HAS_NVIDIA=true
            GPU_MODEL=$(echo "$nvidia_info" | sed 's/.*: //')
            log_info "NVIDIA GPU detected: $GPU_MODEL"
            return 0
        fi
    fi
    
    # Check for nvidia kernel module
    if lsmod 2>/dev/null | grep -q "^nvidia"; then
        HAS_NVIDIA=true
        log_info "NVIDIA kernel module detected"
        return 0
    fi
    
    log_substep "No NVIDIA GPU found"
    return 1
}

# Detect AMD GPU
detect_amd_gpu() {
    log_substep "Checking for AMD GPU..."
    
    if command -v lspci &>/dev/null; then
        local amd_info
        amd_info=$(lspci | grep -iE "amd|radeon" | grep -i "vga\|display\|3d" | head -1 || true)
        
        if [[ -n "$amd_info" ]]; then
            HAS_AMD_GPU=true
            GPU_MODEL=$(echo "$amd_info" | sed 's/.*: //')
            log_info "AMD GPU detected: $GPU_MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Detect Intel GPU
detect_intel_gpu() {
    log_substep "Checking for Intel GPU..."
    
    if command -v lspci &>/dev/null; then
        local intel_info
        intel_info=$(lspci | grep -i "intel" | grep -i "vga\|display\|graphics" | head -1 || true)
        
        if [[ -n "$intel_info" ]]; then
            HAS_INTEL_GPU=true
            if [[ -z "$GPU_MODEL" ]]; then
                GPU_MODEL=$(echo "$intel_info" | sed 's/.*: //')
            fi
            log_info "Intel GPU detected"
            return 0
        fi
    fi
    
    return 1
}

# Detect ASUS laptop
detect_asus() {
    log_substep "Checking for ASUS hardware..."
    
    # Check DMI info
    if [[ -f /sys/class/dmi/id/sys_vendor ]]; then
        local vendor
        vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
        
        if [[ "$vendor" == *"ASUS"* ]] || [[ "$vendor" == *"ASUSTeK"* ]]; then
            IS_ASUS=true
            
            if [[ -f /sys/class/dmi/id/product_name ]]; then
                LAPTOP_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
            fi
            
            log_info "ASUS device detected: $LAPTOP_MODEL"
            return 0
        fi
    fi
    
    # Check for ASUS-specific kernel modules
    if lsmod 2>/dev/null | grep -qE "asus|asusctl"; then
        IS_ASUS=true
        log_info "ASUS kernel modules detected"
        return 0
    fi
    
    return 1
}

# Detect if running on laptop
detect_laptop() {
    log_substep "Checking if laptop..."
    
    # Check for battery
    if [[ -d /sys/class/power_supply ]]; then
        for supply in /sys/class/power_supply/*; do
            if [[ -f "$supply/type" ]]; then
                local type
                type=$(cat "$supply/type" 2>/dev/null || true)
                if [[ "$type" == "Battery" ]]; then
                    IS_LAPTOP=true
                    log_info "Laptop detected (battery present)"
                    return 0
                fi
            fi
        done
    fi
    
    # Check chassis type
    if [[ -f /sys/class/dmi/id/chassis_type ]]; then
        local chassis
        chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)
        # 9=Laptop, 10=Notebook, 14=Sub Notebook
        if [[ "$chassis" =~ ^(9|10|14)$ ]]; then
            IS_LAPTOP=true
            log_info "Laptop detected (chassis type)"
            return 0
        fi
    fi
    
    return 1
}

# Detect if running in VM
detect_vm() {
    log_substep "Checking for virtual machine..."
    
    # Check systemd-detect-virt
    if command -v systemd-detect-virt &>/dev/null; then
        local virt
        virt=$(systemd-detect-virt 2>/dev/null || true)
        if [[ "$virt" != "none" ]] && [[ -n "$virt" ]]; then
            IS_VM=true
            log_info "Virtual machine detected: $virt"
            return 0
        fi
    fi
    
    # Check for common VM indicators
    if grep -qE "hypervisor|vmware|virtualbox|qemu|kvm" /proc/cpuinfo 2>/dev/null; then
        IS_VM=true
        log_info "Virtual machine detected (cpuinfo)"
        return 0
    fi
    
    return 1
}

# Run all detections
run_detection() {
    log_step "Detecting hardware..."
    
    detect_nvidia || true
    detect_amd_gpu || true
    detect_intel_gpu || true
    detect_asus || true
    detect_laptop || true
    detect_vm || true
    
    echo ""
}

# Show detection summary
show_detection_summary() {
    echo ""
    echo "Hardware Detection Summary"
    echo "=========================="
    echo ""
    
    echo "GPU:"
    [[ "$HAS_NVIDIA" == "true" ]] && echo "  • NVIDIA: Yes ($GPU_MODEL)"
    [[ "$HAS_AMD_GPU" == "true" ]] && echo "  • AMD: Yes"
    [[ "$HAS_INTEL_GPU" == "true" ]] && echo "  • Intel: Yes"
    [[ "$HAS_NVIDIA" == "false" ]] && [[ "$HAS_AMD_GPU" == "false" ]] && [[ "$HAS_INTEL_GPU" == "false" ]] && echo "  • None detected"
    
    echo ""
    echo "System:"
    [[ "$IS_LAPTOP" == "true" ]] && echo "  • Type: Laptop"
    [[ "$IS_LAPTOP" == "false" ]] && echo "  • Type: Desktop"
    [[ "$IS_ASUS" == "true" ]] && echo "  • Brand: ASUS ($LAPTOP_MODEL)"
    [[ "$IS_VM" == "true" ]] && echo "  • Virtual Machine: Yes"
    
    echo ""
}

# Get recommended packages based on detection
get_recommended_packages() {
    local packages=()
    
    if [[ "$HAS_NVIDIA" == "true" ]]; then
        packages+=("nvidia-dkms" "nvidia-utils" "nvidia-settings" "libva-nvidia-driver")
    fi
    
    if [[ "$IS_ASUS" == "true" ]]; then
        packages+=("asusctl" "supergfxctl" "rog-control-center")
    fi
    
    if [[ "$IS_LAPTOP" == "true" ]]; then
        packages+=("tlp" "powertop")
    fi
    
    printf '%s\n' "${packages[@]}"
}

# Interactive hardware setup
interactive_hardware_setup() {
    run_detection
    show_detection_summary
    
    echo "Recommended packages based on your hardware:"
    echo ""
    
    local recommended
    mapfile -t recommended < <(get_recommended_packages)
    
    if [[ ${#recommended[@]} -eq 0 ]]; then
        echo "  No additional packages recommended"
        return 0
    fi
    
    for pkg in "${recommended[@]}"; do
        echo "  • $pkg"
    done
    
    echo ""
    echo -n "Install recommended packages? [Y/n] "
    read -r response
    
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        return 0  # Install
    else
        return 1  # Skip
    fi
}

# Export detection results as JSON (for scripting)
export_as_json() {
    cat << EOF
{
  "nvidia": $HAS_NVIDIA,
  "amd_gpu": $HAS_AMD_GPU,
  "intel_gpu": $HAS_INTEL_GPU,
  "asus": $IS_ASUS,
  "laptop": $IS_LAPTOP,
  "vm": $IS_VM,
  "gpu_model": "$GPU_MODEL",
  "laptop_model": "$LAPTOP_MODEL"
}
EOF
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --json)
            run_detection >/dev/null 2>&1
            export_as_json
            ;;
        --summary)
            run_detection
            show_detection_summary
            ;;
        --recommended)
            run_detection >/dev/null 2>&1
            get_recommended_packages
            ;;
        --interactive)
            interactive_hardware_setup
            ;;
        *)
            run_detection
            show_detection_summary
            ;;
    esac
fi

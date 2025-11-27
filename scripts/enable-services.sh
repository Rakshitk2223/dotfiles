#!/bin/bash
# This script enables and starts essential system and user services.

set -euo pipefail

# --- Log functions ---
log_info() {
    echo "[INFO] $1"
}

# --- Services to enable ---
SYSTEM_SERVICES=(
    "NetworkManager.service"
    "bluetooth.service"
    "smartd.service"
)

USER_SERVICES=(
    "pipewire.service"
    "pipewire-pulse.service"
    "wireplumber.service"
)

# --- Main execution ---
main() {
    log_info "Enabling and starting system services..."
    for service in "${SYSTEM_SERVICES[@]}"; do
        log_info "Enabling and starting system service: $service..."
        sudo systemctl enable --now "$service"
    done

    log_info "Enabling and starting user services..."
    for service in "${USER_SERVICES[@]}"; do
        log_info "Enabling and starting user service: $service..."
        systemctl --user enable --now "$service"
    done

    # Conditionally enable supergfxd for ASUS laptops
    if systemctl list-unit-files | grep -q '^supergfxd.service'; then
        log_info "Enabling and starting supergfxd.service..."
        sudo systemctl enable --now "supergfxd.service"
    else
        log_info "supergfxd.service not found, skipping."
    fi

    # Conditionally enable auto-cpufreq for power management
    if systemctl list-unit-files | grep -q '^auto-cpufreq.service'; then
        log_info "Enabling and starting auto-cpufreq.service..."
        sudo systemctl enable --now "auto-cpufreq.service"
    else
        log_info "auto-cpufreq.service not found, skipping."
    fi

    log_info "All essential services have been enabled and started."
}

main

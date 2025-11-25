#!/bin/bash
# Hook system library for dotfiles
# This file is sourced by other scripts to run user hooks

# Hook directories location (following Omarchy pattern)
HOOKS_DIR="${HOOKS_DIR:-$HOME/.config/dotfiles/hooks}"

# User's local shell customizations
USER_CONFIG_DIR="${USER_CONFIG_DIR:-$HOME/.config/dotfiles}"

# Initialize hook directories
hooks_init() {
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$USER_CONFIG_DIR/zsh"
}

# Run a single hook by name
# Usage: hook_run <hook_name> [args...]
# Example: hook_run post-update
hook_run() {
    local hook_name="$1"
    shift
    
    local hook_path="$HOOKS_DIR/$hook_name"
    
    if [[ -f "$hook_path" ]]; then
        echo "[HOOK] Running: $hook_name"
        if bash "$hook_path" "$@"; then
            echo "[HOOK] Completed: $hook_name"
            return 0
        else
            echo "[HOOK] Failed: $hook_name"
            return 1
        fi
    else
        # Hook doesn't exist, that's fine
        return 0
    fi
}

# Run all scripts in a hook directory
# Usage: hook_run_dir <hook_dir_name>
# Example: hook_run_dir post-update.d
hook_run_dir() {
    local hook_dir_name="$1"
    local hook_dir="$HOOKS_DIR/$hook_dir_name"
    
    if [[ ! -d "$hook_dir" ]]; then
        return 0
    fi
    
    local count=0
    for script in "$hook_dir"/*; do
        [[ -f "$script" && -x "$script" ]] || continue
        
        local script_name
        script_name="$(basename "$script")"
        
        echo "[HOOK] Running: $hook_dir_name/$script_name"
        if bash "$script"; then
            ((count++))
        else
            echo "[HOOK] Failed: $hook_dir_name/$script_name"
            return 1
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        echo "[HOOK] Completed $count hook(s) from $hook_dir_name"
    fi
    
    return 0
}

# Check if a hook exists
hook_exists() {
    local hook_name="$1"
    [[ -f "$HOOKS_DIR/$hook_name" ]]
}

# List all available hooks
hooks_list() {
    echo "Available hooks in $HOOKS_DIR:"
    echo ""
    
    if [[ ! -d "$HOOKS_DIR" ]]; then
        echo "  (hooks directory not created yet)"
        return 0
    fi
    
    local found=0
    for hook in "$HOOKS_DIR"/*; do
        [[ -e "$hook" ]] || continue
        found=1
        
        local hook_name
        hook_name="$(basename "$hook")"
        
        if [[ -f "$hook" ]]; then
            echo "  [file] $hook_name"
        elif [[ -d "$hook" ]]; then
            local script_count
            script_count=$(find "$hook" -maxdepth 1 -type f -executable | wc -l)
            echo "  [dir]  $hook_name/ ($script_count scripts)"
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "  (no hooks defined)"
    fi
    
    echo ""
    echo "Hook locations:"
    echo "  Single hooks: $HOOKS_DIR/<hook-name>"
    echo "  Hook dirs:    $HOOKS_DIR/<hook-name>.d/"
    echo ""
    echo "Available hook points:"
    echo "  post-install  - Runs after dotfiles installation"
    echo "  pre-update    - Runs before dotfiles update"
    echo "  post-update   - Runs after dotfiles update"
}

# Source user's local zsh config if it exists
# This is called from default/zsh/* files
source_user_config() {
    local config_name="$1"
    local user_config="$USER_CONFIG_DIR/zsh/$config_name"
    
    if [[ -f "$user_config" ]]; then
        source "$user_config"
    fi
}

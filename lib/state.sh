#!/bin/bash
# State management library for dotfiles
# This file is sourced by other scripts to manage installation state

# State directory location
STATE_DIR="${STATE_DIR:-$HOME/.local/state/dotfiles}"
STATE_VERSION_FILE="$STATE_DIR/version"
STATE_INSTALLED_FILE="$STATE_DIR/installed_at"
STATE_UPDATED_FILE="$STATE_DIR/updated_at"
STATE_MIGRATIONS_DIR="$STATE_DIR/migrations"

# Get the repository root directory (works when sourced from any location)
get_repo_root() {
    local source="${BASH_SOURCE[1]:-$0}"
    local dir
    dir="$(cd "$(dirname "$source")" && pwd)"
    
    # Walk up until we find the version file (repo root indicator)
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/version" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    # Fallback: assume we're in lib/ or bin/ subdirectory
    echo "$(cd "$(dirname "$source")/.." && pwd)"
}

# Initialize state directory structure
state_init() {
    if [[ ! -d "$STATE_DIR" ]]; then
        mkdir -p "$STATE_DIR"
        mkdir -p "$STATE_MIGRATIONS_DIR"
    fi
}

# Check if dotfiles have been installed before
state_is_installed() {
    [[ -f "$STATE_VERSION_FILE" ]]
}

# Get currently installed version
state_get_version() {
    if [[ -f "$STATE_VERSION_FILE" ]]; then
        cat "$STATE_VERSION_FILE"
    else
        echo "not installed"
    fi
}

# Get repository version
state_get_repo_version() {
    local repo_root
    repo_root="$(get_repo_root)"
    if [[ -f "$repo_root/version" ]]; then
        cat "$repo_root/version"
    else
        echo "unknown"
    fi
}

# Set installed version
state_set_version() {
    local version="$1"
    state_init
    echo "$version" > "$STATE_VERSION_FILE"
}

# Get installation timestamp
state_get_installed_at() {
    if [[ -f "$STATE_INSTALLED_FILE" ]]; then
        cat "$STATE_INSTALLED_FILE"
    else
        echo "unknown"
    fi
}

# Set installation timestamp (only on first install)
state_set_installed_at() {
    state_init
    if [[ ! -f "$STATE_INSTALLED_FILE" ]]; then
        date "+%Y-%m-%d %H:%M:%S" > "$STATE_INSTALLED_FILE"
    fi
}

# Get last update timestamp
state_get_updated_at() {
    if [[ -f "$STATE_UPDATED_FILE" ]]; then
        cat "$STATE_UPDATED_FILE"
    else
        echo "never"
    fi
}

# Set update timestamp
state_set_updated_at() {
    state_init
    date "+%Y-%m-%d %H:%M:%S" > "$STATE_UPDATED_FILE"
}

# Check if a migration has been run
state_migration_done() {
    local migration_name="$1"
    [[ -f "$STATE_MIGRATIONS_DIR/$migration_name" ]]
}

# Mark a migration as complete
state_migration_mark() {
    local migration_name="$1"
    state_init
    date "+%Y-%m-%d %H:%M:%S" > "$STATE_MIGRATIONS_DIR/$migration_name"
}

# Record full installation state (called after successful install)
state_record_install() {
    local repo_root
    repo_root="$(get_repo_root)"
    local version
    version="$(cat "$repo_root/version" 2>/dev/null || echo "1.0.0")"
    
    state_init
    state_set_version "$version"
    state_set_installed_at
    state_set_updated_at
}

# Record update state (called after successful update)
state_record_update() {
    local repo_root
    repo_root="$(get_repo_root)"
    local version
    version="$(cat "$repo_root/version" 2>/dev/null || echo "1.0.0")"
    
    state_init
    state_set_version "$version"
    state_set_updated_at
}

# Check if update is available (repo version > installed version)
state_update_available() {
    local installed repo
    installed="$(state_get_version)"
    repo="$(state_get_repo_version)"
    
    [[ "$installed" == "not installed" ]] && return 0
    [[ "$installed" != "$repo" ]] && return 0
    return 1
}

# =============================================================================
# Migration System
# =============================================================================

# Get list of pending migrations (not yet run)
migrations_get_pending() {
    local repo_root
    repo_root="$(get_repo_root)"
    local migrations_dir="$repo_root/migrations"
    
    if [[ ! -d "$migrations_dir" ]]; then
        return 0
    fi
    
    # Find all migration scripts, sorted by name (date prefix ensures order)
    for migration in "$migrations_dir"/*.sh; do
        [[ -f "$migration" ]] || continue
        local migration_name
        migration_name="$(basename "$migration")"
        
        # Skip if already run
        if ! state_migration_done "$migration_name"; then
            echo "$migration"
        fi
    done
}

# Run a single migration script
migration_run_single() {
    local migration_path="$1"
    local migration_name
    migration_name="$(basename "$migration_path")"
    
    echo "[MIGRATION] Running: $migration_name"
    
    # Run the migration
    if bash "$migration_path"; then
        state_migration_mark "$migration_name"
        echo "[MIGRATION] Completed: $migration_name"
        return 0
    else
        echo "[MIGRATION] Failed: $migration_name"
        return 1
    fi
}

# Run all pending migrations
migrations_run_all() {
    local pending
    local count=0
    local failed=0
    
    state_init
    
    # Get pending migrations into array
    mapfile -t pending < <(migrations_get_pending)
    
    if [[ ${#pending[@]} -eq 0 ]]; then
        echo "[MIGRATION] No pending migrations"
        return 0
    fi
    
    echo "[MIGRATION] Found ${#pending[@]} pending migration(s)"
    
    for migration in "${pending[@]}"; do
        [[ -z "$migration" ]] && continue
        
        if migration_run_single "$migration"; then
            ((count++))
        else
            ((failed++))
            echo "[MIGRATION] Stopping due to failure"
            return 1
        fi
    done
    
    echo "[MIGRATION] Completed $count migration(s)"
    return 0
}

# List all migrations and their status
migrations_list() {
    local repo_root
    repo_root="$(get_repo_root)"
    local migrations_dir="$repo_root/migrations"
    
    echo "Migrations:"
    echo ""
    
    if [[ ! -d "$migrations_dir" ]]; then
        echo "  No migrations directory found"
        return 0
    fi
    
    local found=0
    for migration in "$migrations_dir"/*.sh; do
        [[ -f "$migration" ]] || continue
        found=1
        
        local migration_name
        migration_name="$(basename "$migration")"
        
        if state_migration_done "$migration_name"; then
            local run_date
            run_date="$(cat "$STATE_MIGRATIONS_DIR/$migration_name" 2>/dev/null || echo "unknown")"
            echo "  [done] $migration_name (ran: $run_date)"
        else
            echo "  [pending] $migration_name"
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "  No migrations found"
    fi
}

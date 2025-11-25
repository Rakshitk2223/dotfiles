#!/bin/bash
# Error handling helper functions for dotfiles scripts
# Source this file: source "$SCRIPTS_DIR/helpers/errors.sh"

# Error handling mode
# strict: exit on any error (set -e behavior)
# lenient: continue on non-critical errors
ERROR_MODE="${ERROR_MODE:-strict}"

# Store the last error message
LAST_ERROR=""

# Cleanup functions to run on exit
declare -a CLEANUP_FUNCTIONS

# Setup error trapping
setup_error_handling() {
    set -o pipefail
    
    if [[ "$ERROR_MODE" == "strict" ]]; then
        set -e
    fi
    
    trap '_handle_error $? $LINENO "$BASH_COMMAND"' ERR
    trap '_run_cleanup' EXIT
}

# Internal: handle error
_handle_error() {
    local exit_code="$1"
    local line_no="$2"
    local command="$3"
    
    LAST_ERROR="Command '$command' failed with exit code $exit_code at line $line_no"
    
    if [[ "$ERROR_MODE" == "strict" ]]; then
        echo -e "\033[0;31m[ERROR]\033[0m $LAST_ERROR" >&2
        return "$exit_code"
    else
        echo -e "\033[1;33m[WARN]\033[0m $LAST_ERROR (continuing)" >&2
        return 0
    fi
}

# Internal: run cleanup functions
_run_cleanup() {
    local exit_code=$?
    
    for cleanup_func in "${CLEANUP_FUNCTIONS[@]}"; do
        if declare -f "$cleanup_func" > /dev/null; then
            "$cleanup_func" || true
        fi
    done
    
    return $exit_code
}

# Register a cleanup function
register_cleanup() {
    local func="$1"
    CLEANUP_FUNCTIONS+=("$func")
}

# Try to run a command, return success/failure without exiting
try_run() {
    local description="$1"
    shift
    
    if "$@" 2>/dev/null; then
        return 0
    else
        LAST_ERROR="$description failed"
        return 1
    fi
}

# Run a command, exit on failure with message
must_run() {
    local description="$1"
    shift
    
    if ! "$@"; then
        echo -e "\033[0;31m[FATAL]\033[0m $description failed" >&2
        exit 1
    fi
}

# Run a command, warn on failure but continue
should_run() {
    local description="$1"
    shift
    
    if ! "$@"; then
        echo -e "\033[1;33m[WARN]\033[0m $description failed (non-critical)" >&2
        return 0
    fi
}

# Check if a command exists
require_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "\033[0;31m[ERROR]\033[0m Required command '$cmd' not found. Install with: $package" >&2
        return 1
    fi
    return 0
}

# Check multiple required commands
require_commands() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\033[0;31m[ERROR]\033[0m Missing required commands: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

# Assert a condition is true
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        echo -e "\033[0;31m[ASSERT]\033[0m $message" >&2
        exit 1
    fi
}

# Rollback helper - shows rollback instructions
show_rollback_help() {
    local component="${1:-installation}"
    
    echo ""
    echo -e "\033[1;33m━━━ Rollback Instructions ━━━\033[0m"
    echo ""
    echo "If the $component failed, you can try:"
    echo ""
    echo "  1. Check the logs above for specific errors"
    echo ""
    echo "  2. Git rollback (if repo was modified):"
    echo "     cd ~/.local/bin/dotfiles && git status"
    echo "     git checkout -- <file>  # Restore specific file"
    echo "     git reset --hard HEAD   # Restore all files"
    echo ""
    echo "  3. Restore from backup:"
    echo "     ls ~/.local/state/dotfiles/backups/"
    echo ""
    echo "  4. Re-run installation:"
    echo "     ~/.local/bin/dotfiles/install.sh"
    echo ""
}

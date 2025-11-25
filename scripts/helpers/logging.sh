#!/bin/bash
# Logging helper functions for dotfiles scripts
# Source this file: source "$SCRIPTS_DIR/helpers/logging.sh"

# Colors
export LOG_RED='\033[0;31m'
export LOG_GREEN='\033[0;32m'
export LOG_YELLOW='\033[1;33m'
export LOG_BLUE='\033[0;34m'
export LOG_CYAN='\033[0;36m'
export LOG_MAGENTA='\033[0;35m'
export LOG_BOLD='\033[1m'
export LOG_DIM='\033[2m'
export LOG_NC='\033[0m' # No Color

# Log level (0=quiet, 1=error, 2=warn, 3=info, 4=debug)
LOG_LEVEL="${LOG_LEVEL:-3}"

# Enable/disable colors
LOG_COLORS="${LOG_COLORS:-true}"

# Log file (optional)
LOG_FILE="${LOG_FILE:-}"

# Internal: write to log file if configured
_log_to_file() {
    if [[ -n "$LOG_FILE" ]]; then
        local timestamp
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "[$timestamp] $1: $2" >> "$LOG_FILE"
    fi
}

# Internal: colorize output
_colorize() {
    local color="$1"
    local text="$2"
    
    if [[ "$LOG_COLORS" == "true" ]]; then
        echo -e "${color}${text}${LOG_NC}"
    else
        echo "$text"
    fi
}

# Log functions
log_debug() {
    [[ $LOG_LEVEL -ge 4 ]] || return 0
    _colorize "$LOG_DIM" "[DEBUG] $1"
    _log_to_file "DEBUG" "$1"
}

log_info() {
    [[ $LOG_LEVEL -ge 3 ]] || return 0
    _colorize "$LOG_GREEN" "[INFO] $1"
    _log_to_file "INFO" "$1"
}

log_warn() {
    [[ $LOG_LEVEL -ge 2 ]] || return 0
    _colorize "$LOG_YELLOW" "[WARN] $1"
    _log_to_file "WARN" "$1"
}

log_error() {
    [[ $LOG_LEVEL -ge 1 ]] || return 0
    _colorize "$LOG_RED" "[ERROR] $1" >&2
    _log_to_file "ERROR" "$1"
}

log_success() {
    [[ $LOG_LEVEL -ge 3 ]] || return 0
    _colorize "$LOG_GREEN" "[SUCCESS] $1"
    _log_to_file "SUCCESS" "$1"
}

log_step() {
    [[ $LOG_LEVEL -ge 3 ]] || return 0
    _colorize "${LOG_BOLD}${LOG_CYAN}" ">> $1"
    _log_to_file "STEP" "$1"
}

log_substep() {
    [[ $LOG_LEVEL -ge 3 ]] || return 0
    _colorize "$LOG_BLUE" "   -> $1"
    _log_to_file "SUBSTEP" "$1"
}

# Fatal error - logs and exits
log_fatal() {
    _colorize "$LOG_RED" "[FATAL] $1" >&2
    _log_to_file "FATAL" "$1"
    exit 1
}

# Print a header
log_header() {
    local text="$1"
    local width="${2:-50}"
    local border
    border=$(printf '═%.0s' $(seq 1 "$width"))
    
    echo ""
    _colorize "${LOG_BOLD}${LOG_CYAN}" "╔${border}╗"
    _colorize "${LOG_BOLD}${LOG_CYAN}" "║$(printf "%-${width}s" "  $text")║"
    _colorize "${LOG_BOLD}${LOG_CYAN}" "╚${border}╝"
    echo ""
}

# Print a section divider
log_section() {
    local text="$1"
    echo ""
    _colorize "${LOG_BOLD}" "━━━ $text ━━━"
    echo ""
}

# Print a list item
log_list_item() {
    local status="$1"
    local text="$2"
    
    case "$status" in
        ok|done|installed)
            _colorize "$LOG_GREEN" "  ✓ $text"
            ;;
        skip|skipped)
            _colorize "$LOG_YELLOW" "  ○ $text"
            ;;
        fail|error|missing)
            _colorize "$LOG_RED" "  ✗ $text"
            ;;
        pending|todo)
            _colorize "$LOG_BLUE" "  • $text"
            ;;
        *)
            echo "  $status $text"
            ;;
    esac
}

#!/bin/bash
# Presentation helper functions for dotfiles scripts
# Source this file: source "$SCRIPTS_DIR/helpers/presentation.sh"

# Colors (if not already defined)
: "${LOG_RED:=\033[0;31m}"
: "${LOG_GREEN:=\033[0;32m}"
: "${LOG_YELLOW:=\033[1;33m}"
: "${LOG_BLUE:=\033[0;34m}"
: "${LOG_CYAN:=\033[0;36m}"
: "${LOG_BOLD:=\033[1m}"
: "${LOG_NC:=\033[0m}"

# Progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0

# Initialize progress tracking
init_progress() {
    TOTAL_STEPS="$1"
    CURRENT_STEP=0
}

# Show progress step
show_progress() {
    local description="$1"
    ((CURRENT_STEP++))
    
    echo ""
    echo -e "${LOG_BOLD}${LOG_CYAN}[$CURRENT_STEP/$TOTAL_STEPS]${LOG_NC} ${LOG_BOLD}$description${LOG_NC}"
}

# Show a banner
show_banner() {
    local title="$1"
    local subtitle="${2:-}"
    
    echo ""
    echo -e "${LOG_BOLD}${LOG_CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════╗
    ║                                                   ║
EOF
    printf "    ║   %-47s ║\n" "$title"
    if [[ -n "$subtitle" ]]; then
        printf "    ║   %-47s ║\n" "$subtitle"
    fi
    cat << 'EOF'
    ║                                                   ║
    ╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${LOG_NC}"
}

# Show a simple box
show_box() {
    local text="$1"
    local width="${2:-50}"
    local border
    border=$(printf '─%.0s' $(seq 1 "$width"))
    
    echo "┌${border}┐"
    echo "│ $(printf "%-$((width-2))s" "$text") │"
    echo "└${border}┘"
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo -en "${LOG_BOLD}$question${LOG_NC} $prompt "
    read -r response
    
    response="${response:-$default}"
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Ask for input with default
ask_input() {
    local question="$1"
    local default="${2:-}"
    local var_name="$3"
    
    local prompt="$question"
    [[ -n "$default" ]] && prompt="$prompt [$default]"
    
    echo -en "${LOG_BOLD}$prompt:${LOG_NC} "
    read -r response
    
    response="${response:-$default}"
    
    if [[ -n "$var_name" ]]; then
        eval "$var_name=\"$response\""
    else
        echo "$response"
    fi
}

# Show a selection menu
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo ""
    echo -e "${LOG_BOLD}$title${LOG_NC}"
    echo ""
    
    local i=1
    for opt in "${options[@]}"; do
        echo "  $i) $opt"
        ((i++))
    done
    
    echo ""
    echo -en "${LOG_BOLD}Select [1-${#options[@]}]:${LOG_NC} "
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && \
       [[ "$selection" -ge 1 ]] && \
       [[ "$selection" -le ${#options[@]} ]]; then
        echo "${options[$((selection-1))]}"
        return 0
    else
        return 1
    fi
}

# Show a checklist summary
show_checklist() {
    local title="$1"
    shift
    
    echo ""
    echo -e "${LOG_BOLD}$title${LOG_NC}"
    echo ""
    
    while [[ $# -ge 2 ]]; do
        local status="$1"
        local item="$2"
        shift 2
        
        case "$status" in
            ok|done|yes|true|1)
                echo -e "  ${LOG_GREEN}✓${LOG_NC} $item"
                ;;
            fail|error|no|false|0)
                echo -e "  ${LOG_RED}✗${LOG_NC} $item"
                ;;
            skip|na)
                echo -e "  ${LOG_YELLOW}○${LOG_NC} $item"
                ;;
            *)
                echo "  • $item"
                ;;
        esac
    done
    echo ""
}

# Show a spinner while running a command
run_with_spinner() {
    local description="$1"
    shift
    local command=("$@")
    
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Run command in background
    "${command[@]}" &>/dev/null &
    local pid=$!
    
    # Show spinner
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars:$i:1}"
        echo -en "\r  ${LOG_CYAN}${char}${LOG_NC} $description"
        ((i = (i + 1) % ${#spin_chars}))
        sleep 0.1
    done
    
    # Get exit code
    wait "$pid"
    local exit_code=$?
    
    # Show result
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\r  ${LOG_GREEN}✓${LOG_NC} $description"
    else
        echo -e "\r  ${LOG_RED}✗${LOG_NC} $description"
    fi
    
    return $exit_code
}

# Show completion message
show_completion() {
    local message="${1:-Installation complete!}"
    
    echo ""
    echo -e "${LOG_GREEN}╔════════════════════════════════════════════════╗${LOG_NC}"
    echo -e "${LOG_GREEN}║                                                ║${LOG_NC}"
    printf "${LOG_GREEN}║${LOG_NC}   ✓ %-42s ${LOG_GREEN}║${LOG_NC}\n" "$message"
    echo -e "${LOG_GREEN}║                                                ║${LOG_NC}"
    echo -e "${LOG_GREEN}╚════════════════════════════════════════════════╝${LOG_NC}"
    echo ""
}

# Show failure message
show_failure() {
    local message="${1:-Installation failed}"
    
    echo ""
    echo -e "${LOG_RED}╔════════════════════════════════════════════════╗${LOG_NC}"
    echo -e "${LOG_RED}║                                                ║${LOG_NC}"
    printf "${LOG_RED}║${LOG_NC}   ✗ %-42s ${LOG_RED}║${LOG_NC}\n" "$message"
    echo -e "${LOG_RED}║                                                ║${LOG_NC}"
    echo -e "${LOG_RED}╚════════════════════════════════════════════════╝${LOG_NC}"
    echo ""
}

#!/bin/bash
# MOTD helper: Output formatting utilities

# Load colors
# shellcheck source=colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh" 2>/dev/null || true

# Format percentage with color coding
# Args: $1=percentage, $2=warning_threshold, $3=critical_threshold
format_percentage() {
    local pct=$1
    local warn=${2:-70}
    local crit=${3:-85}
    
    if (( pct < warn )); then
        echo -e "${GREEN}${pct}%${NC}"
    elif (( pct < crit )); then
        echo -e "${YELLOW}${pct}% ${SYM_WARNING}${NC}"
    else
        echo -e "${RED}${pct}% ${SYM_ERROR}${NC}"
    fi
}

# Format bytes to human readable
# Args: $1=bytes
format_bytes() {
    local bytes=$1
    
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$(( bytes / 1024 ))KB"
    elif (( bytes < 1073741824 )); then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Format seconds to human readable time ago
# Args: $1=seconds
format_time_ago() {
    local seconds=$1
    local minutes hours days
    
    if (( seconds < 60 )); then
        echo "${seconds}s ago"
    elif (( seconds < 3600 )); then
        minutes=$(( seconds / 60 ))
        echo "${minutes}m ago"
    elif (( seconds < 86400 )); then
        hours=$(( seconds / 3600 ))
        minutes=$(( (seconds % 3600) / 60 ))
        echo "${hours}h ${minutes}m ago"
    else
        days=$(( seconds / 86400 ))
        hours=$(( (seconds % 86400) / 3600 ))
        echo "${days}d ${hours}h ago"
    fi
}

# Left-pad string to fixed width
# Args: $1=string, $2=width
pad_left() {
    printf "%-${2}s" "$1"
}

# Print section header
# Args: $1=section_name
print_section_header() {
    echo -e "\n${BOLD}[$1]${NC}"
}

# Print labeled value with padding
# Args: $1=label, $2=value, $3=padding (default 15)
print_labeled_value() {
    local label=$1
    local value=$2
    local padding=${3:-15}
    
    printf "  %-${padding}s %s\n" "$label" "$value"
}

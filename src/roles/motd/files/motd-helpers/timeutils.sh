#!/bin/bash
# MOTD helper: Time calculation utilities

# Get seconds since epoch for a date string
# Args: $1=date_string
date_to_epoch() {
    date -d "$1" +%s 2>/dev/null || echo 0
}

# Get current epoch timestamp
current_epoch() {
    date +%s
}

# Calculate seconds difference between two epochs
# Args: $1=epoch1, $2=epoch2
epoch_diff() {
    echo $(( $1 - $2 ))
}

# Convert seconds to days
seconds_to_days() {
    echo $(( $1 / 86400 ))
}

# Parse uptime output to seconds
# Args: $1=uptime_output
uptime_to_seconds() {
    local uptime=$1
    local seconds=0
    
    # Parse "up X days, Y hours" format
    if [[ $uptime =~ ([0-9]+)\ day ]]; then
        seconds=$(( seconds + ${BASH_REMATCH[1]} * 86400 ))
    fi
    
    if [[ $uptime =~ ([0-9]+)\ hour ]]; then
        seconds=$(( seconds + ${BASH_REMATCH[1]} * 3600 ))
    fi
    
    if [[ $uptime =~ ([0-9]+)\ min ]]; then
        seconds=$(( seconds + ${BASH_REMATCH[1]} * 60 ))
    fi
    
    echo "$seconds"
}

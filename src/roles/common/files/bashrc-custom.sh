#!/bin/bash
# Ansible managed - Standard Notes IaC
# Custom bash prompt configuration
#
# This script configures colorized bash prompts:
# - Root: Red prompt showing root@fqdn
# - Regular users: Green prompt showing user@fqdn

# Only apply to interactive shells
if [ -n "$PS1" ]; then
    # Get the fully qualified domain name
    FQDN=$(hostname -f 2>/dev/null || hostname)
    
    # Check if running as root
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        # Root: Red prompt
        PS1='\[\033[01;31m\]\u@'"$FQDN"'\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        # Regular user: Green prompt
        PS1='\[\033[01;32m\]\u@'"$FQDN"'\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    fi
    
    export PS1
fi

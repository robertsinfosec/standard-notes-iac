#!/usr/bin/env bash

# Dev Container Post-Setup Script
# Description: Configure aliases and developer experience enhancements

set -euo pipefail

# --- Colors ---
CYAN='\033[36m'
GREEN='\033[32m'
BLUE='\033[34m'
RESET='\033[0m'

echo -e "${CYAN}[*] Setting up development environment${RESET}"

# --- Start Docker Daemon (DinD setup) ---
# echo -e "${GREEN}[+] Starting Docker daemon${RESET}"
# if ! pgrep dockerd > /dev/null; then
#   sudo nohup dockerd > /tmp/dockerd.log 2>&1 &
#   sleep 5
#   echo -e "${BLUE}[i] Docker started successfully${RESET}"
# else
#   echo -e "${BLUE}[i] Docker already running${RESET}"
# fi

# --- Install Ansible globally ---
echo -e "${GREEN}[+] Installing Ansible and linting tools${RESET}"
sudo /usr/local/python/current/bin/python3 -m pip install --upgrade pip
sudo /usr/local/python/current/bin/python3 -m pip install ansible ansible-lint yamllint

# Install Ansible collections
echo -e "${GREEN}[+] Installing Ansible collections${RESET}"
/usr/local/python/current/bin/ansible-galaxy collection install -r /workspaces/standard-notes-iac/src/requirements.yml || true

# --- Add useful aliases ---
echo -e "${GREEN}[+] Adding development aliases${RESET}"
cat >> "$HOME/.bashrc" << 'EOF'

# === Development Aliases ===
alias ll="ls -la"
alias ap="ansible-playbook"
alias al="ansible-lint"

EOF
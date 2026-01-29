#!/bin/bash
# Ansible managed - Standard Notes IaC
# Standard Notes backup script
# Run as: service-backup user

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/standard-notes"
APP_DIR="/opt/standard-notes"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/standard-notes-backup-${TIMESTAMP}.tar.gz"
LOG_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Error handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Start backup
log "Starting Standard Notes backup"

# Verify directories exist
[[ -d "${BACKUP_DIR}" ]] || error_exit "Backup directory ${BACKUP_DIR} does not exist"
[[ -d "${APP_DIR}" ]] || error_exit "Application directory ${APP_DIR} does not exist"

# Get service status
log "Checking service status"
cd "${APP_DIR}" || error_exit "Cannot change to ${APP_DIR}"

if sudo /usr/bin/docker compose ps | grep -q "running"; then
    log "Service is running, stopping for backup"
    sudo /usr/bin/docker compose down || error_exit "Failed to stop service"
    SERVICE_WAS_RUNNING=true
else
    log "Service is not running"
    SERVICE_WAS_RUNNING=false
fi

# Create backup archive
log "Creating backup archive"
tar -czf "${BACKUP_FILE}" \
    -C "${APP_DIR}" \
    --exclude='logs' \
    --exclude='*.log' \
    . || error_exit "Failed to create backup archive"

# Verify backup was created
[[ -f "${BACKUP_FILE}" ]] || error_exit "Backup file was not created"

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
log "Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Restart service if it was running
if [[ "${SERVICE_WAS_RUNNING}" == "true" ]]; then
    log "Restarting service"
    sudo /usr/bin/docker compose up -d || error_exit "Failed to restart service"
    
    # Wait for service to be healthy
    log "Waiting for service to be healthy"
    sleep 10
    
    if sudo /usr/bin/docker compose ps | grep -q "running"; then
        log "Service restarted successfully"
    else
        log "WARNING: Service may not have restarted correctly"
    fi
fi

# Set proper permissions on backup file
chmod 640 "${BACKUP_FILE}"

log "Backup completed successfully"
exit 0

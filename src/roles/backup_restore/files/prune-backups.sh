#!/bin/bash
# Ansible managed - Standard Notes IaC
# Standard Notes backup pruning script
# Run as: service-backup user

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/standard-notes"
RETENTION_DAYS="${1:-7}"  # Default 7 days if not specified

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Validate retention days
if ! [[ "${RETENTION_DAYS}" =~ ^[0-9]+$ ]]; then
    log "ERROR: Invalid retention days: ${RETENTION_DAYS}"
    exit 1
fi

log "Starting backup pruning (retention: ${RETENTION_DAYS} days)"

# Verify backup directory exists
if [[ ! -d "${BACKUP_DIR}" ]]; then
    log "ERROR: Backup directory ${BACKUP_DIR} does not exist"
    exit 1
fi

# Find and delete old backups
DELETED_COUNT=0
while IFS= read -r -d '' backup_file; do
    log "Deleting old backup: ${backup_file}"
    rm -f "${backup_file}"
    ((DELETED_COUNT++))
done < <(find "${BACKUP_DIR}" -name "standard-notes-backup-*.tar.gz" -type f -mtime "+${RETENTION_DAYS}" -print0)

# Find and delete old log files
while IFS= read -r -d '' log_file; do
    log "Deleting old log: ${log_file}"
    rm -f "${log_file}"
    ((DELETED_COUNT++))
done < <(find "${BACKUP_DIR}" -name "backup-*.log" -type f -mtime "+${RETENTION_DAYS}" -print0)

# Count remaining backups
REMAINING_COUNT=$(find "${BACKUP_DIR}" -name "standard-notes-backup-*.tar.gz" -type f | wc -l)

log "Pruning completed: ${DELETED_COUNT} files deleted, ${REMAINING_COUNT} backups remaining"
exit 0

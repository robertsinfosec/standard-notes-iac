# Message of the Day (MOTD) System

## Overview

The MOTD system provides real-time operational visibility for administrators and operators when connecting via SSH. The MOTD is designed as a modular, reusable component that can be adapted for any purpose-built VM infrastructure.

**Key Principles:**

- **Real-time Data** - All information is collected at SSH login time, never stale
- **Actionable Intelligence** - Show status that drives decisions, not noise
- **Visual Clarity** - Color coding and symbols for at-a-glance assessment
- **Modular Design** - Each section is independent and reusable
- **Production Quality** - Proper error handling, performance optimization, secure execution

## Design Philosophy

Purpose-built VMs have specific operational characteristics that make custom MOTD valuable:

1. **Known operators** - Only authorized admins/operators SSH in
2. **Operational focus** - Users are troubleshooting or maintaining the system
3. **Service-centric** - Primary concern is service health and resource status
4. **Time-sensitive** - Real-time data is crucial for incident response

## MOTD Structure

### Visual Layout

When you first SSH into this system, instead of seeing the generic Ubuntu MOTD, you will now see a structured, purpose-built report like this just before you get your shell prompt:

```
╔══════════════════════════════════════════════════════════════╗
║        Standard Notes Server - notes.example.com             ║
╚══════════════════════════════════════════════════════════════╝

[SERVICE STATUS]
  Web UI:         ✅ Running (healthy) 31 minutes
  API Server:     ✅ Running (healthy) 31 minutes
  MySQL:          ✅ Running (healthy) 31 minutes
  Redis Cache:    ✅ Running (healthy) 31 minutes
  Traefik:        ✅ Running (healthy) 31 minutes
  LocalStack:     ✅ Running (healthy) 31 minutes
  ------------------------------------------------------------
  Systemd Unit:   ✅ active (running) 31m

[RESOURCES]
  System Uptime:    32 minutes
  Disk Usage:       12G / 19G (64%)
  Database Size:    327M
  Memory:           2.4Gi / 5.8Gi (41%)
  Updates:          System up to date ✅

[BACKUPS]
  Last Backup:      ❌ No backups found
  Location:         /var/backups/standard-notes (empty)
  Status:           ❌ No backups exist - run backup immediately!

[SECURITY]
  SSH Attempts:     No attacks detected (24h)
  Certificate:      Valid until 2026-04-29 (89 days) ✅

[QUICK COMMANDS]
  Service logs:   docker compose -f /opt/standard-notes/docker-compose.yaml logs -f
  Service status: systemctl status standard-notes.service
  Restart:        sudo systemctl restart standard-notes.service
  Run backup:     sudo /usr/local/bin/backup/sn-backup.sh

 System information as of Thu Jan 29 22:38:35 UTC 2026

  System load:  0.71               Processes:             292
  Usage of /:   63.6% of 18.33GB   Users logged in:       1
  Memory usage: 39%                IPv4 address for eth0: 192.168.80.55
  Swap usage:   0%
═══════════════════════════════════════════════════════════════
```

For an admin or operator logging in, this Message of the Day (MOTD) provides immediate insight into the system's health and status.

### Section Priority

Sections are ordered by operational importance:

1. **SERVICE STATUS** - Most critical: is the application running?
2. **RESOURCES** - Resource exhaustion is common failure mode
3. **BACKUPS** - Data protection status
4. **SECURITY** - Security posture and threats
5. **QUICK COMMANDS** - Operational reference

## Real-World Examples

The MOTD system gracefully handles different operational states, providing accurate real-time information in all scenarios.

### Service Running (Normal Operation)

When Standard Notes is running normally, all containers show healthy status with uptime:

```
╔══════════════════════════════════════════════════════════════╗
║        Standard Notes Server - notes.example.com             ║
╚══════════════════════════════════════════════════════════════╝

[SERVICE STATUS]
  Web UI:         ✅ Running (healthy) 31 minutes
  API Server:     ✅ Running (healthy) 31 minutes
  MySQL:          ✅ Running (healthy) 31 minutes
  Redis Cache:    ✅ Running (healthy) 31 minutes
  Traefik:        ✅ Running (healthy) 31 minutes
  LocalStack:     ✅ Running (healthy) 31 minutes
  ------------------------------------------------------------
  Systemd Unit:   ✅ active (running) 31m

[RESOURCES]
  System Uptime:    32 minutes
  Disk Usage:       12G / 19G (64%)
  Database Size:    327M
  Memory:           2.4Gi / 5.8Gi (41%)
  Updates:          System up to date ✅

[BACKUPS]
  Last Backup:      ❌ No backups found
  Location:         /var/backups/standard-notes (empty)
  Status:           ❌ No backups exist - run backup immediately!

[SECURITY]
  SSH Attempts:     No attacks detected (24h)
  Certificate:      Valid until 2026-04-29 (89 days) ✅
```

**Key observations:**
- All containers show ✅ with health status
- Database size: 327M (actively growing)
- Memory usage: 41% (2.4Gi used by Standard Notes stack)
- Clear backup warning prompts immediate action

### Service Stopped (Maintenance)

When Standard Notes is stopped (e.g., `systemctl stop standard-notes`), MOTD reflects shutdown state:

```
╔══════════════════════════════════════════════════════════════╗
║        Standard Notes Server - notes.example.com             ║
╚══════════════════════════════════════════════════════════════╝

[SERVICE STATUS]
  Web UI:         ❌ Missing        -
  API Server:     ❌ Missing        -
  MySQL:          ❌ Missing        -
  Redis Cache:    ❌ Missing        -
  Traefik:        ❌ Missing        -
  LocalStack:     ❌ Missing        -
  ------------------------------------------------------------
  Systemd Unit:   ❌ inactive (dead) -

[RESOURCES]
  System Uptime:    33 minutes
  Disk Usage:       12G / 19G (64%)
  Database Size:    314M
  Memory:           661Mi / 5.8Gi (11%)
  Updates:          System up to date ✅

[BACKUPS]
  Last Backup:      ❌ No backups found
  Location:         /var/backups/standard-notes (empty)
  Status:           ❌ No backups exist - run backup immediately!

[SECURITY]
  SSH Attempts:     No attacks detected (24h)
  Certificate:      Valid until 2026-04-29 (89 days) ✅
```

**Key observations:**
- All containers show ❌ Missing (expected when stopped)
- Systemd shows inactive (dead) - confirms intentional shutdown
- Memory dropped from 41% to 11% (Standard Notes released ~1.7Gi)
- Process count decreased by 41 processes
- Database size still accessible (persisted data)
- No errors or timeouts - clean shutdown handling

### Error Detection Capabilities

The MOTD system detects critical mismatches that indicate problems:

**Critical Mismatch Example:**

If systemd shows "active (running)" but Docker containers are missing, MOTD displays:

```
⚠️  CRITICAL: Systemd active but containers missing - service may be failed
```

This catches scenarios where the systemd unit started successfully but Docker Compose failed to bring up containers.

## Technical Implementation

### Ubuntu MOTD Architecture

Ubuntu uses dynamic MOTD via `/etc/update-motd.d/` directory:

- Scripts are numbered (10-, 20-, 30-, etc.) and execute in order
- Each script outputs to stdout
- Combined output displayed on SSH login
- Scripts run as the logging-in user (not root)

### Script Organization

```
/etc/update-motd.d/
├── 00-header           # Banner with hostname/domain
├── 10-service-status   # Docker containers + systemd unit
├── 20-resources        # System resources and updates
├── 30-backups          # Backup status
├── 40-security         # Security events and certificates
├── 50-commands         # Quick command reference
└── 99-footer           # Bottom border
```

### Performance Requirements

**Target:** Total MOTD generation < 500ms

MOTD scripts run synchronously on login, blocking SSH session start. Performance is critical for good user experience.

**Performance budget per script:**

- Header/Footer: <10ms (static output)
- Service Status: <150ms (docker compose ps, systemctl show)
- Resources: <100ms (df, free, apt-check)
- Backups: <50ms (stat, du)
- Security: <100ms (journalctl, openssl)
- Commands: <10ms (static output)

**Optimization strategies:**

- Parallel execution where possible (background jobs in bash)
- Caching for expensive operations (certificate expiry check)
- Timeout protection (kill scripts after 2s max)
- Graceful degradation (show partial info if data unavailable)

### Error Handling

Scripts must handle failures gracefully:

```bash
# Good: Graceful degradation
if ! docker_status=$(timeout 2s docker compose ps 2>/dev/null); then
    echo "  Services:       ⚠️  Unable to check (docker unavailable)"
    exit 0
fi

# Bad: Script crashes, no MOTD shown
docker_status=$(docker compose ps)
```

**Error handling principles:**

1. **Never fail silently** - Show "⚠️ Unable to check" rather than nothing
2. **Use timeouts** - Prevent hung scripts from blocking login
3. **Validate input** - Check file existence before reading
4. **Exit 0 always** - Script failures shouldn't prevent login

## Data Sources

### Service Status Section

**Docker Compose containers:**

```bash
docker compose -f /opt/standard-notes/docker-compose.yaml ps --format json
```

**Output format:**

```json
[
  {
    "Name": "server_self_hosted",
    "Status": "Up 5 hours (healthy)",
    "State": "running",
    "Health": "healthy"
  }
]
```

**Container health states:**

- `healthy` → ✅ Running (healthy)
- `starting` → ⚠️ Starting (initializing)
- `unhealthy` → ❌ Running (unhealthy)
- `running` (no health) → ⚠️ Running (no health check)
- `exited` → ❌ Stopped
- `dead` → ❌ Dead
- `restarting` → ⚠️ Restarting

**Systemd service:**

```bash
systemctl show standard-notes.service -p ActiveState,SubState,ExecMainStartTimestamp
```

**Output format:**

```
ActiveState=active
SubState=running
ExecMainStartTimestamp=Thu 2026-01-29 16:17:53 UTC
```

**Systemd states:**

- `active (running)` → ✅ active (running)
- `activating (start)` → ⚠️ activating
- `inactive (dead)` → ❌ inactive
- `failed` → ❌ failed

**Alignment validation:**

If systemd shows `active` but all Docker containers are `exited`, display critical warning:

```
[SERVICE STATUS]
  ⚠️⚠️⚠️ CRITICAL: Systemd active but containers stopped ⚠️⚠️⚠️
```

### Resources Section

**System uptime:**

```bash
uptime -p
```

Output: `up 12 days, 8 hours`

**Disk usage (application):**

```bash
df -h /opt/standard-notes | awk 'NR==2 {print $3, $2, $5}'
```

Output: `12.5G 27.8G 45%`

**Database size:**

```bash
du -sh /opt/standard-notes/mysql/data 2>/dev/null | awk '{print $1}'
```

Output: `2.3G`

**Memory usage:**

```bash
free -h | awk 'NR==2 {print $3, $2}'
```

Output: `3.2Gi 4.0Gi`

Calculate percentage: `(used / total) * 100`

**APT updates:**

```bash
/usr/lib/update-notifier/apt-check 2>&1
```

Output: `23;5` (format: `<total>;<security>`)

**Color coding thresholds:**

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Disk usage | <70% | 70-85% | >85% |
| Memory usage | <75% | 75-90% | >90% |
| Security updates | 0 | 1-9 | ≥10 |
| Total updates | <20 | 20-49 | ≥50 |

### Backups Section

**Last backup timestamp:**

```bash
# Find most recent backup file
latest_backup=$(find /var/backups/standard-notes -name 'sn-*.tar.gz' -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

# Get timestamp
stat -c %y "$latest_backup" 2>/dev/null
```

**Backup size:**

```bash
du -h "$latest_backup" 2>/dev/null | awk '{print $1}'
```

**Time ago calculation:**

```bash
backup_epoch=$(stat -c %Y "$latest_backup")
now_epoch=$(date +%s)
diff_seconds=$((now_epoch - backup_epoch))

# Convert to human readable
hours=$((diff_seconds / 3600))
minutes=$(((diff_seconds % 3600) / 60))
echo "${hours}h ${minutes}m ago"
```

**Backup status validation:**

Check if backup systemd timer exists and last run succeeded:

```bash
systemctl show sn-backup.timer -p Result,LastTriggerUSecTimestamp 2>/dev/null
```

### Security Section

**SSH ban attempts (fail2ban):**

```bash
# Count unique banned IPs in last 24h
journalctl -u fail2ban -S "24 hours ago" --no-pager 2>/dev/null | \
  grep -c "Ban"
```

**Certificate expiry:**

```bash
# Extract certificate from running Traefik
echo | openssl s_client -connect localhost:443 -servername "$DOMAIN" 2>/dev/null | \
  openssl x509 -noout -enddate 2>/dev/null
```

Output: `notAfter=Apr  8 14:32:19 2026 GMT`

**Days until expiry:**

```bash
expiry_epoch=$(date -d "Apr 8 14:32:19 2026 GMT" +%s)
now_epoch=$(date +%s)
days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
```

**Certificate color coding:**

- ✅ >30 days
- ⚠️ 15-30 days
- ❌ <15 days

**Last login:**

Parse `/var/log/auth.log` for last successful SSH authentication before current session.

### Quick Commands Section

**Command references (static output):**

Commands are contextual to Standard Notes deployment:

```
  Service logs:   docker compose -f /opt/standard-notes/docker-compose.yaml logs -f
  Service status: systemctl status standard-notes
  Restart:        sudo systemctl restart standard-notes
  Run backup:     sudo /usr/local/bin/backup/sn-backup.sh
```

**Customization for other VMs:**

This section should be templated in Ansible to support different services:

```yaml
motd_quick_commands:
  - label: "Service logs"
    command: "docker compose -f /opt/standard-notes/docker-compose.yaml logs -f"
  - label: "Service status"
    command: "systemctl status standard-notes"
  - label: "Restart"
    command: "sudo systemctl restart standard-notes"
  - label: "Run backup"
    command: "sudo /usr/local/bin/backup/sn-backup.sh"
```

## Visual Design System

### Status Symbols

Unicode symbols for universal terminal compatibility:

- ✅ Success/Healthy/Running
- ⚠️ Warning/Degraded/Unknown
- ❌ Error/Failed/Stopped

**Rationale:** Avoid emoji (🟢🟡🔴) which may not render correctly in all terminals.

### ANSI Color Codes

```bash
# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# Usage
echo -e "${GREEN}✅${NC} Service running"
echo -e "${YELLOW}⚠️${NC} Warning condition"
echo -e "${RED}❌${NC} Service failed"
```

### Layout Standards

**Column alignment:**

Use fixed-width labels with padding:

```bash
printf "  %-15s %s\n" "Web UI:" "✅ Running (healthy)"
printf "  %-15s %s\n" "API Server:" "✅ Running (healthy)"
```

**Section headers:**

```bash
echo -e "${BOLD}[SERVICE STATUS]${NC}"
```

**Borders:**

```bash
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Standard Notes Server - notes.example.com               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
```

Border width: 64 characters (standard terminal width / 2)

## Security Considerations

### Script Execution Context

MOTD scripts execute as the **logging-in user**, not root:

```bash
# When service-deployer logs in, scripts run as service-deployer
# When service-backup logs in, scripts run as service-backup
```

**Implications:**

1. Scripts must have appropriate file permissions (755)
2. Scripts can only read files accessible to the user
3. Docker commands require user to be in `docker` group
4. Systemctl commands work (doesn't require root for status checks)

### Sensitive Data Exposure

**Never display in MOTD:**

- Database passwords or credentials
- API keys or tokens
- Private keys or certificates
- User email addresses or PII
- Backup encryption passphrases

**Safe to display:**

- Service running state
- Resource usage metrics
- File timestamps and sizes
- Public certificate expiry dates
- SSH ban counts (not IPs unless they're attackers)

### Performance Security

**Timeout protection:**

Malicious or buggy scripts could block SSH login. Use timeouts:

```bash
# Wrapper in /etc/update-motd.d/ script
timeout 2s /usr/local/bin/motd-helpers/check-services.sh || {
    echo "  Services:       ⚠️  Check timed out"
    exit 0
}
```

**Resource limits:**

Scripts should not consume excessive CPU/memory:

```bash
# Limit script to 10MB memory, 2s CPU
ulimit -v 10240 -t 2
```

## Modularity and Reusability

### Ansible Role Structure

The MOTD role is designed for reuse across different purpose-built VMs:

```
roles/motd/
├── defaults/
│   └── main.yml              # Configuration variables
├── files/
│   └── motd-helpers/         # Reusable helper scripts
│       ├── colors.sh         # Color definitions
│       ├── formatters.sh     # Output formatting utilities
│       └── timeutils.sh      # Time calculation utilities
├── templates/
│   ├── 00-header.j2          # Templated header with hostname/domain
│   ├── 10-service-status.j2  # Service check script
│   ├── 20-resources.j2       # Resource monitoring script
│   ├── 30-backups.j2         # Backup status script
│   ├── 40-security.j2        # Security monitoring script
│   ├── 50-commands.j2        # Quick commands reference
│   └── 99-footer.j2          # Footer border
├── tasks/
│   └── main.yml              # Ansible tasks
└── handlers/
    └── main.yml              # No handlers needed (MOTD is stateless)
```

### Configuration Variables

**Standard Notes-specific variables:**

```yaml
# defaults/main.yml
motd_hostname: "Standard Notes Server"
motd_domain: "{{ domain }}"
motd_app_directory: /opt/standard-notes
motd_compose_file: /opt/standard-notes/docker-compose.yaml
motd_systemd_service: standard-notes.service
motd_backup_directory: /var/backups/standard-notes
motd_show_localstack: true

# Service display configuration
motd_services:
  - name: "Web UI"
    container: web_self_hosted
  - name: "API Server"
    container: server_self_hosted
  - name: "MySQL"
    container: db_self_hosted
  - name: "Redis Cache"
    container: cache_self_hosted
  - name: "Traefik"
    container: traefik_standard_notes
  - name: "LocalStack"
    container: localstack_self_hosted
    optional: true

# Quick commands
motd_quick_commands:
  - label: "Service logs"
    command: "docker compose -f {{ motd_compose_file }} logs -f"
  - label: "Service status"
    command: "systemctl status {{ motd_systemd_service }}"
  - label: "Restart"
    command: "sudo systemctl restart {{ motd_systemd_service }}"
  - label: "Run backup"
    command: "sudo /usr/local/bin/backup/sn-backup.sh"

# Thresholds
motd_disk_warning_threshold: 70
motd_disk_critical_threshold: 85
motd_memory_warning_threshold: 75
motd_memory_critical_threshold: 90
motd_cert_warning_days: 30
motd_cert_critical_days: 15
```

### Adaptation for Other VMs

**Example: PostgreSQL-based application**

```yaml
# Overrides in playbook or group_vars
motd_hostname: "MyApp Server"
motd_domain: "myapp.example.com"
motd_app_directory: /opt/myapp
motd_compose_file: /opt/myapp/docker-compose.yaml
motd_systemd_service: myapp.service
motd_backup_directory: /var/backups/myapp

motd_services:
  - name: "Web Frontend"
    container: myapp_web
  - name: "API Backend"
    container: myapp_api
  - name: "PostgreSQL"
    container: myapp_postgres
  - name: "Redis"
    container: myapp_redis
  - name: "Nginx"
    container: myapp_nginx

motd_quick_commands:
  - label: "App logs"
    command: "docker compose -f /opt/myapp/docker-compose.yaml logs -f myapp_api"
  - label: "Database console"
    command: "docker compose -f /opt/myapp/docker-compose.yaml exec myapp_postgres psql -U myapp"
  - label: "Restart"
    command: "sudo systemctl restart myapp"
```

The role templates use these variables to generate appropriate MOTD scripts for any application.

## Testing and Validation

### Unit Testing Scripts

Each MOTD script should have corresponding tests:

```bash
# tests/test-service-status.sh
#!/bin/bash
# Test service status script with mocked docker output

source /usr/local/bin/motd-helpers/colors.sh
source /etc/update-motd.d/10-service-status

# Mock docker compose output
mock_docker_output='[{"Name":"server","State":"running","Health":"healthy"}]'

# Test healthy service rendering
result=$(format_service_status "$mock_docker_output")
assert_contains "$result" "✅ Running (healthy)"
```

### Integration Testing

**Test MOTD in CI/CD:**

```yaml
# GitHub Actions test
- name: Test MOTD generation
  run: |
    # Trigger MOTD generation
    sudo run-parts --report /etc/update-motd.d/
    
    # Validate output
    motd_output=$(sudo run-parts /etc/update-motd.d/)
    
    # Check for required sections
    echo "$motd_output" | grep -q "\[SERVICE STATUS\]"
    echo "$motd_output" | grep -q "\[RESOURCES\]"
    echo "$motd_output" | grep -q "\[BACKUPS\]"
    
    # Performance check: <500ms total
    time sudo run-parts /etc/update-motd.d/ > /dev/null
```

### Manual Testing Checklist

After MOTD role deployment, test these scenarios:

- [ ] Fresh SSH login shows complete MOTD
- [ ] MOTD appears in <500ms
- [ ] All services show correct status
- [ ] Color coding displays correctly
- [ ] Container stopped → ❌ appears correctly
- [ ] High memory usage → ⚠️ appears with color
- [ ] Security updates → shows correct count
- [ ] Backup missing → graceful error message
- [ ] Docker unavailable → graceful degradation
- [ ] SSH as different users (service-deployer, service-backup)

## Performance Optimization

### Parallel Data Collection

Scripts can collect data in parallel using background jobs:

```bash
#!/bin/bash
# /etc/update-motd.d/20-resources

# Start all data collection in parallel
get_uptime &
PID_UPTIME=$!

get_disk_usage &
PID_DISK=$!

get_memory_usage &
PID_MEMORY=$!

get_apt_updates &
PID_APT=$!

# Wait for all to complete (with timeout)
wait $PID_UPTIME $PID_DISK $PID_MEMORY $PID_APT

# Format and display results
format_resources
```

### Caching Expensive Operations

**Certificate expiry check** is expensive (TLS handshake):

```bash
# Cache certificate expiry for 1 hour
CERT_CACHE=/var/cache/motd/cert-expiry
CERT_CACHE_MAX_AGE=3600

if [[ -f "$CERT_CACHE" ]]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CERT_CACHE")))
    if (( cache_age < CERT_CACHE_MAX_AGE )); then
        cat "$CERT_CACHE"
        exit 0
    fi
fi

# Fetch fresh certificate data
cert_expiry=$(check_certificate_expiry)
echo "$cert_expiry" | tee "$CERT_CACHE"
```

### Timeout Protection

Wrap expensive operations with timeout:

```bash
# Timeout after 2 seconds
docker_status=$(timeout 2s docker compose ps --format json 2>/dev/null) || {
    echo "⚠️  Unable to check services (timeout)"
    exit 0
}
```

## Maintenance

### Updating MOTD Scripts

MOTD scripts are managed by Ansible. To update:

1. Modify templates in `roles/motd/templates/`
2. Run Ansible playbook
3. Scripts are redeployed to `/etc/update-motd.d/`
4. No service restart required (takes effect on next SSH login)

### Disabling MOTD

To disable MOTD system-wide:

```bash
# Remove execute permission from all MOTD scripts
chmod -x /etc/update-motd.d/*
```

To disable individual sections:

```bash
# Disable backups section
chmod -x /etc/update-motd.d/30-backups
```

### Debugging MOTD Scripts

**Test MOTD manually:**

```bash
# Run all MOTD scripts as if logging in
sudo run-parts /etc/update-motd.d/

# Run specific script
sudo /etc/update-motd.d/10-service-status

# Debug with trace
bash -x /etc/update-motd.d/10-service-status
```

**Check MOTD generation time:**

```bash
time sudo run-parts /etc/update-motd.d/
```

**View script errors:**

```bash
# MOTD script errors go to syslog
journalctl -t update-motd --since "1 hour ago"
```

## Future Enhancements

Potential improvements for future versions:

1. **Metrics trends** - Show resource usage delta vs 24h ago
2. **Alert history** - Count of recent service restarts
3. **User activity** - Active SSH sessions count
4. **Network status** - External connectivity check
5. **Container resource usage** - Per-container CPU/memory
6. **Database query metrics** - Slow query count, connection count
7. **HTTP response time** - Check application response latency
8. **Log error summary** - Recent error count from application logs

## References

- Ubuntu MOTD: `/usr/share/doc/update-motd/README.md`
- ANSI color codes: [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
- Docker Compose CLI: `docker compose ps --help`
- Systemd: `man systemctl`, `man systemd.service`

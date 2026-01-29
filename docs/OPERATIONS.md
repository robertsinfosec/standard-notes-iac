> **Documentation:** [Quick Start](../QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Security Design](SECURITY_DESIGN.md) | **Operations** | [Testing](TESTING.md) | [PRD](PRD.md)

---

# Operations Guide: Standard Notes IaC

This document provides operational procedures for managing a deployed Standard Notes instance, including backup and restore, upgrades, monitoring, troubleshooting, and disaster recovery.

> [!IMPORTANT]
> All operational procedures assume you have SSH access as the `service-deployer` user and can run Ansible playbooks. For emergency procedures, you may need to SSH directly to the VPS.

## 1. Deployment Operations

### 1.1 Initial Deployment

Initial deployment is performed via Ansible playbook. See [ARCHITECTURE.md](ARCHITECTURE.md#10-deployment-flow) for detailed deployment flow.

**Prerequisites:**
- Ubuntu 24.04 LTS server with SSH access as `root` (initially)
- DNS records configured (A record for domain, CNAME for www)
- Secrets populated (GitHub Actions secrets or local `.env`)
- Ansible 2.14+ installed locally (for local deployment)

Deployment uses dedicated Ansible roles to keep changes scoped and auditable. Role scope and responsibilities are defined in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

> [!IMPORTANT]
> **First Run vs Subsequent Runs**
>
> Initial deployment requires different authentication than subsequent runs:
>
> **First deployment:**
> - Connect as `root` user with password authentication
> - Ansible creates `service-deployer` user with SSH key
> - Hardens SSH (disables root login, disables password auth)
> - Configures firewall (UFW)
> - Installs and configures all services
> - Reboots server after completion
>
> **Subsequent deployments:**
> - Connect as `service-deployer` user with SSH key only
> - Root login disabled
> - Password authentication disabled
> - Re-run playbook is idempotent and safe
>
> **GitHub Actions workflow handles both scenarios:**
> - Workflow inputs (manual trigger) override GitHub Secrets
> - First run: Provide VPS IP, `root`, root password as workflow inputs
> - Later runs: Use GitHub Secrets (`service-deployer` + SSH key)

**GitHub Actions Deployment:**

1. Go to repository → Actions → Deploy Standard Notes workflow
2. Click "Run workflow"
3. **First deployment:** Fill in workflow inputs:
   - Target Host: `203.0.113.42` (VPS IP address)
   - SSH User: `root`
   - SSH Password: `<root-password>` (leave blank to use GitHub Secret)
4. **Subsequent deployments:** Leave inputs blank (uses GitHub Secrets)
5. Click "Run workflow" and monitor progress
6. After first deployment completes, update GitHub Secrets:
   - `TARGET_HOST` → `example.com` (or keep as IP)
   - `DEPLOY_USER` → `service-deployer`
   - `SSH_PRIVATE_KEY` → `<service-deployer-private-key>`
   - Remove or ignore `SSH_PASSWORD` secret

**Local Deployment:**

```bash
cd src/

# First deployment - root user
cp inventory.example inventory
nano inventory
# Set: ansible_user=root ansible_ssh_pass=<root-password>

# Install Ansible Galaxy collections
ansible-galaxy collection install -r requirements.yml

# Run playbook
ansible-playbook -i inventory site.yml

# After first run, update inventory
nano inventory
# Set: ansible_user=service-deployer ansible_ssh_private_key_file=~/.ssh/id_ed25519
# Remove: ansible_ssh_pass

# Subsequent runs
ansible-playbook -i inventory site.yml
```

### 1.2 Re-deployment (Configuration Changes)

When modifying configuration (changing domain, updating secrets, etc.):

```bash
# Local deployment
cd src/
ansible-playbook -i inventory site.yml

# GitHub Actions: push changes or trigger workflow manually
```

Ansible is idempotent - safe to run repeatedly. Only changed resources will be updated.

### 1.3 Deployment Verification

After deployment, verify all components are healthy:

```bash
# Check systemd service status
sudo systemctl status standard-notes.service

# Check container health
docker compose ps

# Check logs for errors
docker compose logs --tail=50

# Test HTTPS endpoint
curl -I https://example.com
curl -I https://api.example.com
```

Expected results:
- Service status: `active (running)`
- All containers: `Up (healthy)`
- HTTPS: `200 OK` or redirect to login page

## 2. Backup and Restore

Backups protect against data loss from hardware failure, software bugs, human error, or security incidents.

### 2.1 Backup Strategy

This project implements **pull-based backups** initiated from an external system (e.g., home lab).

**Pull-based Model:**
- External system SSH to VPS as `service-backup` user
- Execute backup script on VPS
- Transfer backup archive to external system
- VPS retains recent backups, external system archives long-term

**Why Pull-based:**
- VPS doesn't need credentials to external backup storage
- Backup system controls schedule and retention
- Simpler to implement multiple backup destinations
- Better separation of concerns

> [!TIP]
> **3-2-1 Backup Strategy**
>
> Follow the 3-2-1 rule for robust backups:
> - **3** copies of data (production + 2 backups)
> - **2** different media types (local disk + cloud/NAS)
> - **1** copy off-site (geographic separation)
>
> Example: Production on VPS + backup on home NAS + backup on cloud storage (Backblaze B2, AWS S3 Glacier, etc.)

### 2.2 What Gets Backed Up

Each backup archive (`sn-backup-yyyyMMdd.HHmmss.tar.gz`) contains:

1. **MySQL database** - Complete tarball of `/opt/standard-notes/mysql/data/`
2. **Redis data** - Complete tarball of `/opt/standard-notes/redis/data/`
3. **Uploads directory** - User-uploaded files (`/opt/standard-notes/uploads/`)
4. **Application logs** - Standard Notes logs (`/opt/standard-notes/logs/`)
5. **Configuration files** - `docker-compose.yaml`, `localstack_bootstrap.sh`, Traefik configs
6. **TLS certificates** - Let's Encrypt certificates (`/opt/standard-notes/traefik/acme.json`)

**Excluded from backups:**
- `.env` file (contains secrets - security risk if backup compromised)
- Docker images (can be re-pulled from registry)
- System packages and OS files

> [!IMPORTANT]
> **Excluding .env from Backups**
>
> The `.env` file is intentionally excluded from backups for security:
> - Contains database passwords, API tokens, encryption keys
> - If backup archive is compromised, secrets would be exposed
> - Store `.env` separately in password manager or secrets vault
> - For disaster recovery, recreate `.env` from password manager
>
> Future enhancement: Encrypt backup archives with GPG/age before transfer.

### 2.3 Backup Scripts

Ansible deploys two backup scripts to `/usr/local/bin/backup/`:

#### sn-backup.sh

Creates timestamped backup archive of entire `/opt/standard-notes/` directory.

**Usage:**
```bash
sudo systemctl stop standard-notes
sudo /usr/local/bin/backup/sn-backup.sh
sudo systemctl start standard-notes
```

**Output:**
```
/var/backups/standard-notes/sn-backup-yyyyMMdd.HHmmss.tar.gz
```

**Timestamp format:** `yyyyMMdd.HHmmss` (e.g., `20260128.153045`)
- Chronologically sortable
- Multiple backups per day supported
- Filesystem-safe (no colons or spaces)

**Script functionality:**
1. Stop Standard Notes service (prevents inconsistent backup)
2. Create tarball of `/opt/standard-notes/` (excluding `.env`)
3. Save to `/var/backups/standard-notes/sn-backup-<timestamp>.tar.gz`
4. Set permissions (640, service-backup owner)
5. Service restart handled externally

**Retention:** Last 7 backups kept by default (configurable in script header).

#### prune-backups.sh

Removes backups older than retention period.

**Usage:**
```bash
sudo /usr/local/bin/backup/prune-backups.sh [days]

# Default: keep 30 days
sudo /usr/local/bin/backup/prune-backups.sh

# Keep 90 days
sudo /usr/local/bin/backup/prune-backups.sh 90
```

**Script functionality:**
1. Find backups older than N days
2. List files to be deleted
3. Delete old backups
4. Report disk space freed

### 2.4 Backup from External System

From your backup system (home lab, NAS, etc.), create a script to pull backups:

```bash
#!/bin/bash
# pull-standard-notes-backup.sh

VPS_HOST="example.com"
VPS_USER="service-backup"
VPS_BACKUP_DIR="/var/backups/standard-notes"
LOCAL_BACKUP_DIR="/backups/standard-notes"
SSH_KEY="$HOME/.ssh/service-backup-key"

# Create backup on VPS
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" \
    "sudo /usr/local/bin/backup/sn-backup.sh"

# Find most recent backup
LATEST_BACKUP=$(ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" \
    "ls -t $VPS_BACKUP_DIR/sn-backup-*.tar.gz | head -n1")

# Transfer to local system
scp -i "$SSH_KEY" \
    "$VPS_USER@$VPS_HOST:$LATEST_BACKUP" \
    "$LOCAL_BACKUP_DIR/"

# Verify transfer
FILENAME=$(basename "$LATEST_BACKUP")
if [ -f "$LOCAL_BACKUP_DIR/$FILENAME" ]; then
    echo "Backup transferred successfully: $FILENAME"
    
    # Optional: delete from VPS after successful transfer
    # ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "rm $LATEST_BACKUP"
else
    echo "ERROR: Backup transfer failed!"
    exit 1
fi

# Prune old backups on VPS (keep 7 days)
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" \
    "sudo /usr/local/bin/backup/prune-backups.sh 7"
```

**Schedule with cron:**

```cron
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/pull-standard-notes-backup.sh >> /var/log/sn-backup.log 2>&1
```

### 2.5 Backup Testing

Regularly test backup restoration to ensure backups are viable.

**Quarterly test procedure:**
1. Restore backup to test system (separate VPS or local VM)
2. Verify database restoration
3. Verify application starts successfully
4. Verify login and note access
5. Document any issues

> [!WARNING]
> Untested backups are not backups. A backup is only valid if you've successfully restored from it. Test your restore procedure at least quarterly.

### 2.6 Restore Procedure

To restore from backup after data loss or corruption:

**Step 1: Stop services**

```bash
sudo systemctl stop standard-notes
```

**Step 2: Transfer backup to VPS**

From your backup system:

```bash
scp -i ~/.ssh/service-backup-key \
    /backups/standard-notes/sn-backup-20260128.143022.tar.gz \
    service-backup@example.com:/var/backups/standard-notes/
```

**Step 3: Extract backup**

On VPS as `service-backup`:

```bash
cd /var/backups/standard-notes
tar -xzf sn-backup-20260128.143022.tar.gz
```

**Step 4: Restore database**

Since backups are filesystem snapshots taken while the service is stopped, we restore by replacing the data directory.

```bash
# Clear existing database data (WARNING: destructive!)
sudo rm -rf /opt/standard-notes/mysql/data/*

# Restore MySQL data from extracted backup
# Using cp -a to preserve permissions and attributes
sudo cp -a sn-backup-20260128.143022/mysql/data/. /opt/standard-notes/mysql/data/

# Restore Redis data (optional but recommended for session continuity)
sudo rm -rf /opt/standard-notes/redis/data/*
sudo cp -a sn-backup-20260128.143022/redis/data/. /opt/standard-notes/redis/data/
```

**Step 5: Restore uploads**

```bash
sudo rm -rf /opt/standard-notes/uploads/*
sudo cp -r sn-backup-20260128.143022/uploads/* \
    /opt/standard-notes/uploads/
sudo chown -R <container-uid>:<container-gid> \
    /opt/standard-notes/uploads/
```

If you need to restore environment configuration, recreate `/opt/standard-notes/.env` from your password manager or secrets vault and set permissions to 600 for `service-runner`.

**Step 6: Restore acme.json (if needed)**

```bash
sudo cp sn-backup-20260128.143022/acme.json /opt/standard-notes/traefik/acme.json
sudo chown root:root /opt/standard-notes/traefik/acme.json
sudo chmod 600 /opt/standard-notes/traefik/acme.json
```

**Step 7: Start services**

```bash
sudo systemctl start standard-notes
```

**Step 8: Verify restoration**

```bash
# Check service status
sudo systemctl status standard-notes

# Check container health
docker compose ps

# Test login
curl -I https://example.com
```

**Step 9: Clean up**

```bash
rm -rf /var/backups/standard-notes/sn-backup-20260128.143022/
```

## 3. Upgrades and Updates

### 3.1 System Package Updates

Ubuntu automatic security updates are enabled via `unattended-upgrades`. See [SECURITY_DESIGN.md](SECURITY_DESIGN.md#71-automatic-security-updates) for details.

**Manual system updates:**

```bash
# Update package lists
sudo apt update

# List upgradable packages
sudo apt list --upgradable

# Upgrade all packages
sudo apt upgrade -y

# Check if reboot required
test -f /var/run/reboot-required && echo "Reboot required"

# Reboot if needed
sudo reboot
```

> [!TIP]
> **Interactive Unattended Upgrades Configuration**
>
> To configure automatic updates interactively:
> ```bash
> sudo dpkg-reconfigure unattended-upgrades
> ```
> This presents a dialog to enable/disable automatic security updates and configure email notifications.

### 3.2 Docker Image Updates

Standard Notes, MySQL, and Traefik images should be updated periodically for security patches and new features.

**Update procedure:**

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate

# Verify health
docker compose ps
docker compose logs --tail=50
```

**Automated approach (recommended):**

Create systemd timer to update weekly:

```ini
# /etc/systemd/system/docker-update.timer
[Unit]
Description=Update Docker images weekly

[Timer]
OnCalendar=Sun 03:00
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/docker-update.service
[Unit]
Description=Update Docker images

[Service]
Type=oneshot
WorkingDirectory=/opt/standard-notes
ExecStart=/usr/bin/docker compose pull
ExecStart=/usr/bin/docker compose up -d --force-recreate
User=service-runner
```

Enable timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now docker-update.timer
```

### 3.3 Standard Notes Version Pinning

By default, `docker-compose.yaml` uses `:latest` tag for Standard Notes image. This automatically pulls the newest version.

**To pin to specific version:**

Edit `docker-compose.yaml`:

```yaml
services:
  standardnotes:
    image: standardnotes/server:1.2.3  # Specific version
```

**Version update process:**
1. Test new version in non-production environment
2. Update version in `docker-compose.yaml`
3. Re-run Ansible playbook or manually update
4. Verify functionality

### 3.4 Breaking Changes

Monitor Standard Notes release notes for breaking changes:
- https://github.com/standardnotes/server/releases

**Common breaking changes:**
- Database schema migrations
- Environment variable changes
- API version changes requiring client updates

**Migration procedure:**
1. Review release notes
2. Create backup before upgrading
3. Test upgrade on non-production system
4. Apply upgrade to production
5. Monitor logs for errors
6. Rollback if issues (restore from backup)

## 4. Monitoring

Monitoring provides visibility into system health and early warning of issues.

### 4.1 Health Checks

Docker Compose health checks monitor container health. See [ARCHITECTURE.md](ARCHITECTURE.md#33-traefik-v30-reverse-proxy) for health check configuration.

**Check health status:**

```bash
docker compose ps
```

Healthy output:
```
NAME                     STATUS
standard-notes-mysql     Up (healthy)
standard-notes-app       Up (healthy)
standard-notes-traefik   Up (healthy)
```

Unhealthy output triggers automatic restart via Docker restart policy.

### 4.2 External Uptime Monitoring

External monitoring detects outages from user perspective.

> [!TIP]
> **Recommended: Better Stack Uptime Monitoring**
>
> [Better Stack](https://betterstack.com/) offers free uptime monitoring with:
> - HTTPS health checks every 30 seconds (free tier)
> - Email/SMS/Slack alerts
> - Status page
> - Incident management
>
> **Configuration:**
> 1. Create Better Stack account
> 2. Add monitor for `https://example.com/healthz` or `https://example.com`
> 3. Configure alert contacts
> 4. Optionally create public status page
>
> **Alternatives:** UptimeRobot, Pingdom, StatusCake

**Monitor these endpoints:**
- `https://example.com` - Web UI
- `https://api.example.com` - API endpoint
- `https://api.example.com/healthz` - Health check endpoint (if available)

**Alert thresholds:**
- Down for 2 consecutive checks (1 minute)
- Response time > 5 seconds
- SSL certificate expiring < 7 days

### 4.3 Log Monitoring

Regular log review helps identify issues before they become outages.

**Key logs to monitor:**

```bash
# Application logs
docker compose logs -f standardnotes

# MySQL logs
docker compose logs -f mysql

# Traefik access logs
docker compose logs -f traefik

# systemd service logs
sudo journalctl -u standard-notes.service -f

# SSH access logs
sudo tail -f /var/log/auth.log

# Fail2Ban activity
sudo tail -f /var/log/fail2ban.log
```

**Warning signs:**
- Database connection errors
- High error rates in application logs
- Unusual SSH access patterns
- Fail2Ban bans from your own IP
- Disk space warnings
- Memory pressure (OOM killer)

### 4.4 Resource Monitoring

Monitor system resources to prevent outages from resource exhaustion.

**Disk space:**

```bash
# Check disk usage
df -h /opt/standard-notes
df -h /var/backups/standard-notes

# Find largest directories
du -sh /opt/standard-notes/* | sort -h
```

**Memory usage:**

```bash
# System memory
free -h

# Container memory
docker stats --no-stream
```

**CPU usage:**

```bash
# System CPU
top -bn1 | head -n 5

# Container CPU
docker stats --no-stream
```

**Alert thresholds (recommended):**
- Disk usage > 80%: Warning
- Disk usage > 90%: Critical
- Memory usage > 85%: Warning
- CPU usage > 90% sustained: Investigation needed

### 4.5 Metrics Collection (Future Enhancement)

Not in v1.0 scope, but potential future additions:

- **Prometheus + Grafana:** Time-series metrics and dashboards
- **Docker stats exporter:** Container metrics
- **Node exporter:** System metrics
- **MySQL exporter:** Database metrics
- **Alertmanager:** Sophisticated alerting rules

## 5. Troubleshooting

### 5.1 Ansible Deployment Fails on Package Upgrade

**Symptoms:**
- Ansible playbook fails at "Upgrade all packages to latest version" task
- Error message: `E: dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem`

**Root cause:**

A previous package installation or upgrade on the target server was interrupted (power failure, SSH disconnect, manual cancellation), leaving dpkg in an inconsistent state.

**Automatic fix:**

The `common` role includes a pre-flight check that automatically detects and repairs interrupted dpkg installations before attempting package upgrades. Simply re-run the playbook:

```bash
# From local machine
ansible-playbook -i inventory.ini site.yml

# Or via GitHub Actions
# Trigger "Deploy Standard Notes" workflow
```

The playbook will automatically run `dpkg --configure -a` if needed.

**Manual fix (if needed):**

If you need to fix the issue manually before running Ansible:

```bash
# SSH to target server
ssh service-deployer@your-server.example.com

# Repair dpkg state
sudo dpkg --configure -a

# Verify no issues remain
sudo dpkg --audit
# Should return no output if dpkg is healthy
```

**Prevention:**

- Avoid canceling package upgrades mid-operation
- Use `screen` or `tmux` for long SSH sessions to prevent disconnects
- The Ansible playbook now handles this automatically

### 5.2 Service Won't Start

**Symptoms:**
- `systemctl start standard-notes` fails
- `docker compose up` exits with error

**Diagnosis:**

```bash
# Check systemd service status
sudo systemctl status standard-notes.service

# Check Docker Compose logs
docker compose logs

# Validate docker-compose.yaml syntax
docker compose config
```

**Common causes:**

#### Invalid docker-compose.yaml

**Fix:** Re-run Ansible playbook to regenerate from template

#### Missing or invalid .env file

**Fix:** Verify `.env` exists and has correct permissions

```bash
ls -la /opt/standard-notes/.env
# Should be: -rw------- service-runner:standard-notes
```

#### Port conflicts

**Fix:** Check if ports 80, 443, 3000, 3306 are in use

```bash
sudo netstat -tulpn | grep -E ':(80|443|3000|3306)\s'
```

#### Docker daemon not running

**Fix:**

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 5.2 Database Connection Errors

**Symptoms:**
- Standard Notes logs show MySQL connection refused
- Application returns 500 errors

**Diagnosis:**

```bash
# Check MySQL container health
docker compose ps mysql

# Check MySQL logs
docker compose logs mysql

# Test database connection
docker compose exec mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
```

**Common causes:**

#### MySQL container not healthy

**Fix:** Wait for health check to pass (can take 30-60 seconds on startup)

#### Wrong database credentials

**Fix:** Verify `.env` has correct `MYSQL_USER` and `MYSQL_PASSWORD`

#### Database doesn't exist

**Fix:**

```bash
docker compose exec mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" \
    -e "CREATE DATABASE IF NOT EXISTS standardnotes;"
```

### 5.3 TLS Certificate Issues

**Symptoms:**
- HTTPS not working
- Certificate warnings in browser
- Traefik logs show ACME errors

**Diagnosis:**

```bash
# Check Traefik logs
docker compose logs traefik | grep -i acme

# Check acme.json permissions
ls -la /opt/standard-notes/traefik/acme.json
# Should be: -rw------- root:root

# Verify DNS resolves correctly
dig example.com +short
dig api.example.com +short
```

**Common causes:**

#### DNS not propagated

**Fix:** Wait for DNS propagation (up to 48 hours, usually < 1 hour)

#### Cloudflare API token invalid

**Fix:** Verify `CLOUDFLARE_DNS_API_TOKEN` in `.env` has correct permissions (Zone:DNS:Edit)

#### Rate limit hit

Let's Encrypt has rate limits (50 certs per domain per week).

**Fix:** Wait 1 week, or use Let's Encrypt staging for testing

#### acme.json wrong permissions

**Fix:**

```bash
sudo chmod 600 /opt/standard-notes/traefik/acme.json
sudo chown root:root /opt/standard-notes/traefik/acme.json
```

### 5.4 Disk Space Exhaustion

**Symptoms:**
- Containers crashing randomly
- Database errors
- Unable to write files

**Diagnosis:**

```bash
# Check disk usage
df -h

# Find large directories
du -sh /* | sort -h | tail -n 20
```

**Common causes:**

#### Docker logs consuming space

**Fix:** Configure Docker log rotation

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Add to `/etc/docker/daemon.json`, then:

```bash
sudo systemctl restart docker
```

#### Old backups not pruned

**Fix:**

```bash
sudo /usr/local/bin/backup/prune-backups.sh 7
```

#### MySQL binlogs accumulating

**Fix:** Configure MySQL binlog retention

```cnf
# In MySQL config
expire_logs_days = 7
```

#### Unused Docker images/volumes

**Fix:**

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes (CAUTION: only if you know volumes are unused)
docker volume prune
```

### 5.5 High Memory Usage

**Symptoms:**
- System slowness
- OOM (Out of Memory) killer terminating processes
- Swap usage very high

**Diagnosis:**

```bash
# Check memory usage
free -h

# Check container memory
docker stats --no-stream

# Check for OOM kills
dmesg | grep -i kill
sudo journalctl -k | grep -i oom
```

**Common causes:**

#### MySQL buffer pool too large

**Fix:** Reduce MySQL `innodb_buffer_pool_size` in MySQL configuration

#### Too many connections

**Fix:** Reduce MySQL `max_connections` or investigate why so many connections

#### Memory leak in application

**Fix:** Restart containers, report bug to Standard Notes project

**Immediate mitigation:**

```bash
# Restart containers
docker compose restart

# If system unresponsive, reboot
sudo reboot
```

### 5.6 Cannot SSH to Server

**Symptoms:**
- SSH connection refused
- SSH connection timeout
- Authentication failure

**Diagnosis:**

From local system:

```bash
# Test connection
ssh -v service-deployer@example.com

# Check port
nc -zv example.com 22
```

**Common causes:**

#### Firewall blocking SSH

**Fix:** Access via VPS provider console and verify UFW rules match [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md).

```bash
sudo ufw status
```

#### SSH service not running

**Fix:**

```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

#### Wrong SSH key

**Fix:** Verify you're using correct private key

```bash
ssh -i ~/.ssh/correct-key service-deployer@example.com
```

#### Fail2Ban banned your IP

**Fix:** Access via VPS console, check and unban:

```bash
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip YOUR.IP.ADDRESS.HERE
```

## 6. Disaster Recovery

Disaster recovery procedures for catastrophic failures.

### 6.1 Complete Server Loss

If VPS is completely destroyed (provider failure, account compromise, etc.):

**Recovery procedure:**

1. **Provision new VPS** with Ubuntu 24.04 LTS
2. **Configure DNS** to point to new VPS IP
3. **Deploy via Ansible** (GitHub Actions or local)
4. **Restore from backup** (see section 2.6)
5. **Verify functionality**
6. **Update monitoring** with new IP

**RTO (Recovery Time Objective):** 2-4 hours  
**RPO (Recovery Point Objective):** Last backup (ideally < 24 hours)

> [!NOTE]
> RTO and RPO depend on backup frequency and how quickly you can provision new infrastructure. Daily backups mean up to 24 hours of data loss is possible. More frequent backups reduce RPO but increase operational overhead.

### 6.2 Database Corruption

If MySQL database is corrupted but filesystem intact:

**Recovery procedure:**

1. **Stop services:** `sudo systemctl stop standard-notes`
2. **Attempt MySQL repair:**
   ```bash
   docker compose exec mysql mysqlcheck --auto-repair --all-databases
   ```
3. **If repair fails, restore from backup** (see section 2.6)
4. **Start services:** `sudo systemctl start standard-notes`

### 6.3 Compromised Secrets

If `.env` file or secrets are exposed:

**Immediate actions:**

1. **Rotate all secrets** (MySQL passwords, Standard Notes keys, Cloudflare token)
2. **Regenerate `.env`** with new secrets
3. **Re-run Ansible playbook** to deploy new secrets
4. **Rotate SSH keys** if compromised
5. **Rotate TLS certificates** (delete `acme.json`, Traefik will regenerate)
6. **Review logs** for unauthorized access
7. **Notify users** if user data may be compromised

**Prevention:**
- Never commit `.env` to version control
- Use strong, randomly generated secrets
- Limit access to GitHub Actions secrets
- Regular security audits

### 6.4 Provider Outage

If VPS provider has extended outage:

**Mitigation options:**

1. **Wait for provider recovery** (if SLA acceptable)
2. **Migrate to new provider:**
   - Provision VPS at different provider
   - Update DNS to new IP
   - Deploy via Ansible
   - Restore from backup

**Provider diversification (future):**
- Maintain Ansible playbooks compatible with multiple providers
- Document provider-specific differences
- Test deployments on multiple providers periodically

## 7. Operational Best Practices

### 7.1 Documentation

- Keep operational runbooks up to date
- Document all configuration changes
- Maintain changelog of infrastructure changes
- Git commit messages should explain WHY, not just WHAT

### 7.2 Change Management

- Test changes in non-production environment first
- Create backup before making changes
- Make changes during low-traffic periods
- Have rollback plan before deploying

### 7.3 Access Control

- Use unique SSH keys per administrator
- Rotate SSH keys periodically
- Remove access immediately when team members leave
- Log and audit all administrative actions

### 7.4 Communication

- Maintain status page for user communication
- Document maintenance windows in advance
- Notify users of planned downtime
- Post-incident reviews for outages

### 7.5 Continuous Improvement

- Review incidents and near-misses
- Update documentation with lessons learned
- Automate repetitive operational tasks
- Monitor for new security vulnerabilities

## 8. Operational Metrics

Track these metrics to measure operational health:

### 8.1 Availability Metrics

- **Uptime percentage:** Target 99.9% (< 43 minutes downtime/month)
- **Mean Time Between Failures (MTBF):** Time between outages
- **Mean Time To Recovery (MTTR):** Time to restore service

### 8.2 Backup Metrics

- **Backup success rate:** Target 100%
- **Backup duration:** Track for capacity planning
- **Time since last successful backup:** Alert if > 48 hours
- **Restore test success rate:** Target 100% (quarterly tests)

### 8.3 Performance Metrics

- **Response time:** Median and 95th percentile
- **Error rate:** Percentage of 5xx errors
- **Database query time:** Slow query monitoring

### 8.4 Security Metrics

- **Failed login attempts:** Trend over time
- **Fail2Ban bans:** Frequency and sources
- **Time to patch vulnerabilities:** Track for improvement

## 9. Runbook Quick Reference

Common operational tasks at a glance:

| Task | Command |
|------|---------|
| Check service status | `sudo systemctl status standard-notes` |
| Restart service | `sudo systemctl restart standard-notes` |
| View logs | `docker compose logs -f` |
| Check container health | `docker compose ps` |
| Create backup | `sudo /usr/local/bin/backup/sn-backup.sh` |
| Update Docker images | `docker compose pull && docker compose up -d --force-recreate` |
| Check disk space | `df -h` |
| Check memory usage | `free -h` |
| View SSH logs | `sudo tail -f /var/log/auth.log` |
| Unban IP from Fail2Ban | `sudo fail2ban-client set sshd unbanip IP` |
| System updates | `sudo apt update && sudo apt upgrade` |
| Reboot server | `sudo reboot` |

## 10. Emergency Contacts

Maintain list of emergency contacts and resources:

- **VPS Provider Support:** Provider-specific contact info
- **DNS Provider Support:** Cloudflare support channels
- **Team Contacts:** On-call rotation (if applicable)
- **Standard Notes Community:** https://standardnotes.com/help
- **GitHub Issues:** https://github.com/standardnotes/server/issues

## 11. Operational Roadmap

Future operational enhancements:

- Automated restore testing
- Blue-green deployment capability
- Advanced monitoring (Prometheus/Grafana)
- Automated performance testing
- Incident management integration (PagerDuty, etc.)
- Configuration drift detection
- Automated security scanning
- Chaos engineering practices

---

> [!NOTE]
> Operations is an ongoing discipline. This guide will evolve as operational experience grows and new challenges emerge. Contribute improvements via pull requests.

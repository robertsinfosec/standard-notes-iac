# Quick Start Guide: Deploy Standard Notes in 30 Minutes

This guide walks you through deploying a production-ready Standard Notes instance from scratch. Follow these steps in order for a successful deployment.

> [!NOTE]
> This quick start assumes you're deploying via GitHub Actions. For local deployment, see the [Local Deployment](#option-b-local-deployment) section.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Ubuntu 24.04 LTS VPS** - 4GB+ RAM, 20GB+ disk, public IPv4 address
  - Providers: RackNerd, DigitalOcean, Linode, Vultr, Hetzner
  - Fresh installation only (no existing services)
- [ ] **Domain name** - Two DNS records needed:
  - A record: `example.com` → VPS IP address
  - A record: `api.example.com` → VPS IP address
  - CNAME (optional): `www.example.com` → `example.com`
- [ ] **Cloudflare account** - For automated TLS certificates via DNS challenge
  - API token with `Zone:DNS:Edit` permissions
- [ ] **GitHub account** - For repository and GitHub Actions
- [ ] **SSH key pair** - For VPS access and deployment

> [!IMPORTANT]
> DNS propagation can take up to 48 hours. Verify DNS resolves before proceeding:
> ```bash
> dig example.com +short
> dig api.example.com +short
> ```

## Deployment Overview

```mermaid
graph LR
    A[Provision VPS] --> B[Configure DNS]
    B --> C[Fork Repository]
    C --> D[Generate Secrets]
    D --> E[Configure GitHub]
    E --> F[Run Deployment]
    F --> G[Verify & Test]
```

## Step 1: Provision Your VPS

### 1.1 Create VPS Instance

1. Log into your VPS provider
2. Create new instance:
   - **OS:** Ubuntu 24.04 LTS (fresh install)
   - **Plan:** Minimum 4GB RAM, 2 vCPU, 20GB disk
   - **Datacenter:** Choose location close to your users
   - **SSH Key:** Add your public SSH key during creation

3. Note the VPS public IP address (e.g., `VPS_IP`)

### 1.2 Test SSH Access

```bash
ssh root@VPS_IP
# Should connect successfully
exit
```

> [!TIP]
> If using DigitalOcean, Linode, or Vultr, you can add your SSH key during droplet/instance creation. For other providers, you may need to add it manually after creation.

## Step 2: Configure DNS

### 2.1 Add DNS Records

In your DNS provider (Cloudflare, Namecheap, etc.), add these records:

| Type  | Name               | Content         | TTL  |
|-------|--------------------|-----------------|------|
| A     | `@`                | `VPS_IP`        | Auto |
| A     | `api`              | `VPS_IP`        | Auto |
| CNAME | `www`              | `example.com`   | Auto |

Replace `VPS_IP` with your actual VPS IP address.

### 2.2 Verify DNS Propagation

Wait for DNS to propagate (usually 5-30 minutes, max 48 hours):

```bash
# Should return your VPS IP
dig example.com +short
dig api.example.com +short
```

## Step 3: Configure Cloudflare for TLS

### 3.1 Add Domain to Cloudflare

If not already using Cloudflare as DNS provider:

1. Log into Cloudflare
2. Add site → Enter `example.com`
3. Copy Cloudflare nameservers
4. Update nameservers at your domain registrar
5. Wait for nameserver propagation (can take 24 hours)

### 3.2 Create API Token

1. Go to Cloudflare dashboard → Profile → API Tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. **Permissions:**
   - Zone → DNS → Edit
5. **Zone Resources:**
   - Include → Specific zone → `example.com`
6. Create Token and **copy it immediately** (shown only once)

Example token: `abc123def456ghi789jkl012mno345pqr678stu901vwx234yz`

## Step 4: Fork and Clone Repository

### 4.1 Fork Repository

1. Go to `https://github.com/yourusername/standard-notes-iac`
2. Click "Fork" button
3. Create fork in your account

### 4.2 Clone Locally (Optional)

Only needed if deploying locally instead of GitHub Actions:

```bash
git clone https://github.com/yourusername/standard-notes-iac.git
cd standard-notes-iac
```

## Step 5: Generate Secrets

Standard Notes requires multiple secure secrets. Generate them using these commands:

The authoritative list of required secrets and variables lives in [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md).

```bash
# Install tools if not available
sudo apt install pwgen openssl   # Ubuntu/Debian
brew install pwgen               # macOS

# Database passwords
echo "MYSQL_ROOT_PASSWORD=$(pwgen -s -y 32 1)"
echo "MYSQL_PASSWORD=$(pwgen -s -y 32 1)"
echo "REDIS_PASSWORD=$(pwgen -s -y 32 1)"

# Standard Notes application secrets
echo "AUTH_JWT_SECRET=$(openssl rand -hex 32)"
echo "VALET_TOKEN_SECRET=$(openssl rand -hex 32)"
echo "ENCRYPTION_SERVER_KEY=$(openssl rand -hex 32)"
```

Example output:
```
MYSQL_ROOT_PASSWORD=<generate-secure-password>
MYSQL_PASSWORD=<generate-secure-password>
REDIS_PASSWORD=<generate-secure-password>
AUTH_JWT_SECRET=<generate-secure-hex-string>
VALET_TOKEN_SECRET=<generate-secure-hex-string>
ENCRYPTION_SERVER_KEY=<generate-secure-hex-string>
```

**Save these secrets** in a password manager - you'll add them to GitHub Secrets in the next step.

> [!WARNING]
> These are real production secrets. Never commit them to Git or share them in plaintext.
>
> The placeholder values above (`<generate-secure-password>`) are intentional to avoid triggering GitHub Secret Scanning on fake passwords.

## Step 6: Configure GitHub Actions

### 6.1 Add GitHub Secrets

1. Go to your forked repository on GitHub
2. Settings → Secrets and variables → Actions
3. Click "New repository secret" for each secret listed in [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md). That document is the single source of truth for required secrets.

> [!NOTE]
> Complete list of Standard Notes environment variables at https://github.com/standardnotes/server/blob/main/.env.sample
>
> Additional optional secrets (SMTP, S3, etc.) can be added as needed.

**SSH Private Key:**

```bash
# Display your private key
cat ~/.ssh/id_ed25519
# Or for RSA:
cat ~/.ssh/id_rsa

# Copy entire output including:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ...key content...
# -----END OPENSSH PRIVATE KEY-----
```

### 6.2 Add GitHub Variables

Click "New repository variable" for each variable listed in [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md). That document is the single source of truth for required variables.

> [!TIP]
> **Timezone Selection**
>
> Use standard IANA timezone format (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`).
> List of timezones: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

> [!NOTE]
> SMTP configuration (optional) can be added via additional GitHub Secrets/Variables if needed for email notifications. See Standard Notes `.env.sample` for complete variable list.

## Step 7: Run Deployment

### 7.1 Trigger GitHub Actions Workflow

> [!IMPORTANT]
> **First Deployment vs Subsequent Deployments**
>
> The GitHub Actions workflow supports both initial provisioning (root user + password) and ongoing deployments (service account + SSH key).
>
> **For your FIRST deployment:**
> 1. Use workflow inputs to specify VPS IP, `root` user, and root password
> 2. Workflow creates `service-deployer` user and hardens SSH
> 3. Server reboots after initial configuration
>
> **For subsequent deployments:**
> 1. Leave workflow inputs blank
> 2. Workflow uses GitHub Secrets (`service-deployer` user + SSH key)
> 3. Idempotent updates without reboot

**First Deployment (Manual Trigger with Inputs):**

1. Go to repository → Actions tab
2. Select "Deploy Standard Notes" workflow
3. Click "Run workflow" button
4. **Fill in workflow inputs:**
   - **Target Host:** `203.0.113.42` (your VPS IP address)
   - **SSH User:** `root`
   - **SSH Password:** `<your-root-password>` (from VPS provider)
   - Leave SSH Private Key blank (not used for first run)
5. Click green "Run workflow" button
6. Monitor progress (typically 5-10 minutes)
7. **After successful first deployment:** Update GitHub Secrets for future runs:
   - Add/update `DEPLOY_USER` → `service-deployer`
   - Add/update `SSH_PRIVATE_KEY` → `<service-deployer-ssh-private-key>`
   - `SSH_PASSWORD` secret no longer needed

**Subsequent Deployments (Manual Trigger):**

1. Go to repository → Actions tab
2. Select "Deploy Standard Notes" workflow  
3. Click "Run workflow"
4. **Leave all inputs blank** (uses GitHub Secrets)
5. Click green "Run workflow" button

**Alternative: Push to Main (if workflow configured for it):**

```bash
git commit --allow-empty -m "Trigger deployment"
git push origin main
```

### 7.2 Monitor Deployment

1. Go to Actions tab
2. Click on the running workflow
3. Watch deployment progress

**Typical timeline:**
- Initial deployment: 10-15 minutes (includes system reboot)
- Subsequent deployments: 5-10 minutes (no reboot)

**Expected stages:**
1. Checkout code
2. Set up Ansible
3. Run Ansible playbook:
   - Common system setup (timezone, NTP, packages)
   - Create users (service-deployer, service-runner, service-backup)
   - Configure SSH hardening
   - Configure firewall (UFW)
   - Install Fail2Ban
   - Install Docker and Docker Compose
   - Deploy Standard Notes containers
   - Configure systemd service
   - **(First run only)** Queue system reboot

> [!NOTE]
> **About the Reboot**
>
> First deployment reboots the server after hardening SSH and configuring the firewall. This ensures:
> - Kernel security updates are active
> - SSH configuration changes are fully applied
> - Clean state for service startup
>
> The workflow will disconnect during reboot and **may show an error**. This is expected. Wait 2-3 minutes and verify deployment manually via SSH.

### 7.3 Deployment Success

Successful deployment shows:

```
PLAY RECAP *********************************************************************
example.com                : ok=47   changed=23   unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

If deployment fails, check the logs for error messages. Common issues:

- DNS not propagated → Wait and retry
- SSH key authentication failed → Verify SSH_PRIVATE_KEY secret
- Cloudflare API token invalid → Regenerate token with correct permissions

## Step 8: Verify Deployment

### 8.1 Check Service Status

SSH to your VPS:

```bash
ssh service-deployer@example.com
```

Check services:

```bash
# Service status
sudo systemctl status standard-notes

# Container health
docker compose ps

# Should show:
# NAME                     STATUS
# standard-notes-mysql     Up (healthy)
# standard-notes-app       Up (healthy)  
# standard-notes-traefik   Up (healthy)
```

### 8.2 Test HTTPS Endpoints

From your local machine:

```bash
# Main domain (should return 200 or redirect to login)
curl -I https://example.com

# API domain
curl -I https://api.example.com

# Verify TLS certificate
openssl s_client -connect example.com:443 -servername example.com < /dev/null 2>/dev/null | grep -A2 "Verify return code"
# Should show: Verify return code: 0 (ok)
```

### 8.3 Access Web Interface

1. Open browser to `https://example.com`
2. You should see Standard Notes login/registration page
3. Create an account
4. Verify you can create and sync notes

> [!TIP]
> Use the web interface first to verify everything works. Then install Standard Notes desktop or mobile apps and configure with `https://api.example.com` as the server URL.

## Step 9: Configure Backups

### 9.1 Set Up Backup Pulling

On your backup system (home server, NAS, etc.), create backup script:

```bash
#!/bin/bash
# /usr/local/bin/pull-sn-backup.sh

VPS_HOST="example.com"
VPS_USER="service-backup"
LOCAL_BACKUP_DIR="/backups/standard-notes"
SSH_KEY="$HOME/.ssh/service-backup-key"

# Create backup on VPS
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" \
    "sudo /usr/local/bin/backup/sn-backup.sh"

# Find and download latest backup
LATEST=$(ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" \
   "ls -t /var/backups/standard-notes/sn-backup-*.tar.gz | head -n1")

scp -i "$SSH_KEY" "$VPS_USER@$VPS_HOST:$LATEST" "$LOCAL_BACKUP_DIR/"

echo "Backup completed: $(basename $LATEST)"
```

### 9.2 Schedule Daily Backups

```bash
# Make executable
chmod +x /usr/local/bin/pull-sn-backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
```

Add line:
```cron
0 2 * * * /usr/local/bin/pull-sn-backup.sh >> /var/log/sn-backup.log 2>&1
```

### 9.3 Copy service-backup SSH Key

You need the `service-backup` user's SSH public key on your backup system:

```bash
# On VPS
sudo cat /home/service-backup/.ssh/authorized_keys

# Copy the public key, then on your backup system:
ssh-copy-id -i /path/to/service-backup-key service-backup@example.com
```

See [OPERATIONS.md](docs/OPERATIONS.md#24-backup-from-external-system) for complete backup configuration.

## Step 10: Set Up Monitoring

### 10.1 Configure Uptime Monitoring

1. Sign up for [Better Stack](https://betterstack.com/) (free tier)
2. Add monitor:
   - **URL:** `https://example.com`
   - **Check interval:** 30 seconds (free tier) or 1 minute
   - **Expected status:** 200-399
3. Configure alert contacts (email, Slack, SMS)
4. Optional: Create public status page

### 10.2 Verify Monitoring Works

1. Temporarily stop service: `sudo systemctl stop standard-notes`
2. Wait for alert (should arrive within 2 minutes)
3. Restart service: `sudo systemctl start standard-notes`
4. Verify recovery notification

See [OPERATIONS.md](docs/OPERATIONS.md#42-external-uptime-monitoring) for monitoring details.

## Next Steps

Your Standard Notes instance is now deployed! Here's what to do next:

### Security Hardening

- [ ] Review [SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md) for security best practices
- [ ] Change SSH port from 22 to non-standard port (reduces log noise)
- [ ] Set up Fail2Ban monitoring alerts
- [ ] Review firewall rules: `sudo ufw status`

### Operational Setup

- [ ] Test backup restoration on a test system (quarterly)
- [ ] Document your specific configuration (domain, backup schedule, etc.)
- [ ] Set calendar reminders for maintenance tasks
- [ ] Join Standard Notes community for updates

### Optional Enhancements

- [ ] Configure Cloudflare proxy for DDoS protection
- [ ] Set up log aggregation (Loki + Grafana)
- [ ] Deploy to multiple environments (staging + production)
- [ ] Automate Docker image updates (weekly)

### Learning Resources

- **Architecture:** [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design and components
- **Security:** [SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md) - Security controls and hardening
- **Operations:** [OPERATIONS.md](docs/OPERATIONS.md) - Day-to-day management
- **Reference:** [PRD.md](docs/PRD.md) - Complete product requirements

## Troubleshooting

### Common Issues

**"DNS not found" during deployment**
- Wait for DNS propagation (5-60 minutes typically)
- Verify with `dig example.com +short`

**"Connection refused" when accessing site**
- Check firewall: `sudo ufw status` (should allow 80, 443)
- Check containers: `docker compose ps` (should show healthy)
- Check logs: `docker compose logs`

**TLS certificate not issuing**
- Verify DNS resolves correctly
- Check Cloudflare API token permissions
- Review Traefik logs: `docker compose logs traefik | grep -i acme`
- Verify `acme.json` permissions: `ls -la /opt/standard-notes/traefik/acme.json` (should be 600)

**Can't SSH to VPS**
- Verify SSH key in GitHub secret matches VPS
- Check UFW isn't blocking: `sudo ufw status`
- Try root login if service-deployer fails: `ssh root@example.com`

See [OPERATIONS.md](docs/OPERATIONS.md#5-troubleshooting) for comprehensive troubleshooting guide.

## Option B: Local Deployment

If deploying from your local workstation instead of GitHub Actions:

### Prerequisites

- Ansible 2.14+ installed locally
- Python 3.8+
- SSH access to VPS
- `ansible-galaxy` command available

### Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ansible python3-pip
```

**macOS:**
```bash
brew install ansible
```

**Verify installation:**
```bash
ansible --version  # Should show 2.14 or higher
```

### Steps

1. **Clone repository:**
   ```bash
   git clone https://github.com/yourusername/standard-notes-iac.git
   cd standard-notes-iac/src
   ```

2. **Install Ansible collections:**
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

3. **Create .env file:**
   ```bash
   cp .env.example .env
   nano .env
   # Fill in all secrets and configuration from Step 5 above
   ```

4. **Load environment variables:**
   
   Ansible uses `lookup('env', 'VAR_NAME')` to read secrets from your shell environment. Before running the playbook, export all variables from your `.env` file:
   
   ```bash
   cd src
   set -a  # automatically export all variables
   source .env
   set +a  # turn off auto-export
   ```
   
   Verify variables are loaded:
   ```bash
   echo $DOMAIN
   echo $MYSQL_ROOT_PASSWORD
   # Should show your values, not empty
   ```

5. **Create inventory file (first deployment):**
   ```bash
   nano inventory.ini
   ```
   
   Add:
   ```ini
   [standardnotes]
   203.0.113.42 ansible_user=root ansible_ssh_pass=<root-password>
   ```

6. **Run playbook (first deployment):**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

7. **Update inventory for subsequent runs:**
   
   After first successful deployment, edit inventory:
   ```bash
   nano inventory.ini
   ```
   
   Change to:
   ```ini
   [standardnotes]
   example.com ansible_user=service-deployer ansible_ssh_private_key_file=~/.ssh/id_ed25519
   ```
   
   Remove `ansible_ssh_pass` line.

8. **Subsequent deployments:**
   
   Always load environment variables first:
   ```bash
   cd src
   set -a && source .env && set +a
   ansible-playbook -i inventory.ini site.yml
   ```

9. **Continue from Step 8** (Verify Deployment above)

> [!TIP]
> **Managing Inventory**
>
> - `src/inventory` is gitignored (contains sensitive host info)
> - `src/inventory.example` provides template
> - For multiple environments, use `inventory.prod`, `inventory.staging`, etc.
> - Use `-i inventory.prod` to specify which inventory file

> [!NOTE]  
> Local deployment gives you more control and visibility into Ansible output, but requires maintaining local Ansible environment. GitHub Actions is recommended for most users.

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/standard-notes-iac/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/standard-notes-iac/discussions)
- **Standard Notes:** [Official Help](https://standardnotes.com/help)

---

**Estimated total time:** 30-60 minutes (mostly waiting for DNS propagation)

**Congratulations!** You now have a production-ready, self-hosted Standard Notes instance with automated backups, security hardening, and monitoring. 🎉

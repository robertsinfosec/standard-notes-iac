> **Documentation:** [Quick Start](../QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Security Design](SECURITY_DESIGN.md) | [Operations](OPERATIONS.md) | [Testing](TESTING.md) | **PRD**

---

# Product Requirements Document: Standard Notes IaC

## 1. Problem Statement

Self-hosting Standard Notes requires manual configuration of multiple components: web application, database, reverse proxy, TLS certificates, and ongoing operational tasks like backups and updates. This manual process is error-prone, time-consuming, and difficult to reproduce consistently across deployments.

Existing deployment options lack:

- Automated, repeatable deployment workflows
- Proper security hardening from the start
- Clear operational procedures for backups and disaster recovery
- Integration with modern CI/CD practices
- Comprehensive documentation for both deployment and maintenance

This project provides production-grade Infrastructure as Code to deploy Standard Notes with security best practices, automated deployments, and clear operational runbooks.

## 2. Target Audiences

This project serves two distinct user groups with different needs and technical backgrounds. Understanding these audiences shapes documentation structure and feature prioritization.

### 2.1 Primary: End Users

#### Profile

Semi-technical users who understand basic Linux system administration, DNS configuration, and SSH. They may be privacy-focused individuals, small teams, or hobbyists who want to self-host Standard Notes without becoming infrastructure experts.

#### What They Need to Accomplish

- Fork this repository
- Configure secrets and environment variables via GitHub Actions or local `.env` files
- Deploy a production-ready Standard Notes instance to their VPS
- Perform routine operational tasks (backups, updates, monitoring)

#### What They Should NOT Need to Know

- How to write Ansible playbooks from scratch
- Docker Compose networking internals
- Systemd service file syntax
- Fail2Ban jail configuration syntax

### 2.2 Secondary: Contributors

#### Profile

Experienced infrastructure engineers, DevOps practitioners, or security-focused developers who want to improve, extend, or customize this project. They understand Infrastructure as Code principles, configuration management, and production operations.

#### What They Need to Understand

- Complete system architecture and design decisions
- How components interact and why specific tools were chosen
- Development workflow and testing strategies
- How to propose and implement improvements

#### Expected Expertise

- Ansible playbook and role development
- Docker and Docker Compose
- Linux system administration and security hardening
- CI/CD with GitHub Actions

## 3. Goals

### Primary Goals

1. **Automated Deployment:** Provide fully automated, idempotent deployment of Standard Notes using Ansible
2. **Security by Default:** Implement SSH hardening, IDS/IPS (Fail2Ban), least-privilege user accounts, and automated TLS via Traefik
3. **Operational Simplicity:** Include backup scripts, systemd service management, and health checks for all Docker services
4. **Dual Deployment Modes:** Support both GitHub Actions-based deployment and local manual deployment via `.env` configuration
5. **Production-Grade Quality:** All code and documentation meets standards suitable for long-term production use
6. **Educational Value:** Document design decisions and security practices to help users understand what they're deploying

### Success Metrics

- A user with a fresh Ubuntu 24.04 VPS can deploy Standard Notes in under 30 minutes
- All security hardening is applied automatically without manual intervention
- Backups can be executed and restored using documented procedures
- System can be redeployed idempotently without data loss

## 4. Non-Goals

Defining what this project will NOT do is as important as defining what it will do. This prevents scope creep and sets clear expectations.

### Explicitly Out of Scope

1. **Multi-server deployments:** This project targets single-server deployments only
2. **High availability / clustering:** No load balancing, database replication, or failover mechanisms
3. **Managed database services:** MySQL runs as a Docker Compose service, not as a cloud-managed database
4. **DNS management:** Users must configure DNS records manually; DNS automation is not included
5. **Advanced monitoring/observability:** Beyond Docker health checks, monitoring tools (Prometheus, Grafana, etc.) are not included
6. **Email delivery service:** Users must provide their own SMTP server credentials
7. **Multiple Standard Notes instances:** One instance per server only
8. **Operating system variety:** Only Ubuntu 24.04 LTS is supported initially

### Future Possibilities (Not in v1.0)

- Terraform examples for provisioning VPS on various cloud providers
- Support for additional Linux distributions (Debian 12, Rocky Linux 9, etc.)
- Automated OS patching and update workflows
- Integration with external monitoring services
- Multi-instance support with shared Traefik

## 5. Supported Environments

This section defines the technical environments where this project is designed to work reliably. Supporting a limited, well-defined set of environments ensures quality and maintainability.

### 5.1 Target Infrastructure

#### Supported

- VPS providers (RackNerd, DigitalOcean, Linode, Vultr, Hetzner, etc.)
- Bare metal servers with public IP addresses
- Cloud VMs (AWS EC2, GCP Compute Engine, Azure VMs) when manually provisioned

#### Minimum Specifications

- 2 CPU cores (recommended: 4 cores)
- 4 GB RAM (recommended: 8 GB)
- 40 GB disk space (recommended: 80 GB or more depending on usage)
- Public IPv4 address with ports 80, 443, and 22 accessible

### 5.2 Operating Systems

#### Supported

- Ubuntu 24.04 LTS (fresh installation only)

#### Rationale

Focusing on a single, recent LTS release ensures:

- Predictable package versions and system behavior
- Long-term support (until 2029)
- Modern Docker and systemd versions
- Consistent security update mechanisms

### 5.3 Control Machine

#### GitHub Actions (Primary)

- GitHub-hosted runners (Ubuntu latest)
- SSH access to target VPS using SSH key authentication
- GitHub Actions secrets for storing sensitive configuration

#### Local Development (Secondary)

- Any system capable of running Ansible (Linux, macOS, WSL2 on Windows)
- Ansible 2.14 or newer
- SSH client
- Local `.env` file for configuration

### 5.4 Required External Services

Users must provide:

- Domain name with ability to create DNS A/AAAA records
- Cloudflare account for TLS certificate DNS challenge (API token required)
- SMTP server for Standard Notes email delivery (host, port, credentials)

## 6. Unsupported Environments

Being explicit about unsupported platforms prevents wasted effort and sets clear boundaries. These limitations are intentional trade-offs for simplicity and maintainability.

### What Will NOT Work

- Shared hosting without root/sudo access
- Systems behind NAT without port forwarding configured
- Windows Server (Docker on Windows has different networking/volume behavior)
- LXC/LXD containers (nested Docker may not work reliably)
- Very old Ubuntu versions (20.04 or earlier)
- ARM architecture (not tested; may work but unsupported)

### Why Certain Platforms Are Excluded

- **Kubernetes:** Over-engineering for single-instance deployments; adds significant complexity
- **Docker Swarm:** Minimal benefit for single-server setup
- **Older Ubuntu versions:** Outdated Docker, systemd, and security patch availability
- **Non-Debian systems:** Package managers, paths, and service management differ too much

## 7. Security Requirements

Security is a primary design consideration, not an afterthought. This section defines the security controls, policies, and hardening measures that must be implemented automatically during deployment.

### 7.1 Secrets Management

Proper secrets management is critical for security in a public repository. All sensitive credentials must be kept out of version control and injected at deployment time.

#### Out of Version Control

All secrets must remain outside version control. This includes:

- MySQL root and user passwords
- Standard Notes encryption keys and JWT secrets
- SMTP credentials
- Cloudflare API tokens
- SSH private keys

#### Storage Mechanisms

- **GitHub Actions:** GitHub Actions secrets and environment variables
- **Local Deployment:** `.env` file (git-ignored) loaded by Ansible

#### Template Approach

Repository includes `.env.example` with placeholder values. Users copy to `.env` and populate with real secrets.

### 7.2 Network Security

Network security controls protect data in transit and limit attack surface. Encryption, firewalling, and access controls are configured automatically.

#### TLS/SSL Requirements

- All HTTP traffic redirected to HTTPS
- TLS certificates automatically provisioned via Let's Encrypt (Traefik + Cloudflare DNS challenge)
- Modern TLS cipher suites only (TLS 1.2 minimum, prefer TLS 1.3)

#### Firewall Expectations

Ansible will configure `ufw` (Uncomplicated Firewall) to:

- Allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- Deny all other inbound traffic
- Allow all outbound traffic

#### Exposure Boundaries

- Standard Notes web UI and API are publicly accessible via HTTPS
- MySQL is only accessible within Docker internal network (not exposed to host)
- SSH is hardened (key-based only, no password authentication, non-standard port optional)

### 7.3 Auditability

All system activities must be logged to support security investigations, troubleshooting, and compliance. Logs provide visibility into system behavior and changes.

#### Logging Requirements

- All Ansible playbook runs must log actions taken
- SSH authentication attempts logged via syslog
- Fail2Ban actions logged (bans, unbans)
- Docker Compose service logs available via `docker compose logs`

#### Traceability

- All infrastructure changes tracked via Git commits
- GitHub Actions runs provide deployment audit trail
- Manual deployments should be documented in operational logs

### 7.4 System Hardening

System hardening reduces attack surface and limits the impact of potential compromises. All hardening is applied automatically via Ansible, with no manual security configuration required.

#### Automated Hardening

Ansible roles will enforce:

- SSH key-based authentication only (password auth disabled)
- Fail2Ban with jails for SSH and Standard Notes
 - Least-privilege user accounts (`service-deployer`, `service-runner`)
- Automatic security updates enabled
- Unnecessary services disabled

#### Principle of Least Privilege

User account separation limits blast radius of potential compromises:

- **`service-deployer` user:** SSH access, sudo for deployment tasks (Ansible execution)
- **`service-runner` user:** Owns `/opt/standard-notes/`, member of `standard-notes` group, limited sudo for systemd service control only (`systemctl start|stop|restart|enable|disable standard-notes`)
- **`service-backup` user:** Owns `/var/backups/standard-notes/`, member of `standard-notes` group, can execute backup scripts with specific sudo permissions for database dumps
- **`standard-notes` group:** Shared group for controlled access between `service-runner` and `service-backup`
- **`root` user:** Owns Traefik ACME certificate file (`/opt/standard-notes/traefik/acme.json`)

Directory ownership and permissions:

- `/opt/standard-notes/`: Owned by `service-runner:standard-notes` with group read permissions
- `/var/backups/standard-notes/`: Owned by `service-backup:service-backup` 
- `/usr/local/bin/backup/`: Backup scripts executable by `service-backup`, may require specific sudo grants for database access

Security rationale:

If Standard Notes application is compromised, attacker gains `service-runner` access but:

- Cannot access backup archives in `/var/backups/standard-notes/` (different owner)
- Cannot SSH as `service-backup` to exfiltrate backups remotely
- Cannot modify backup scripts in `/usr/local/bin/backup/`
- Limited sudo scope prevents easy privilege escalation

## 8. Operational Requirements

Successful production operation requires more than just deployment. This section defines backup strategies, upgrade procedures, and monitoring capabilities that enable long-term system maintenance.

### 8.1 Backup & Restore

Regular backups protect against data loss from hardware failure, software bugs, or operator error. This project implements pull-based backups controlled by an external system.

#### Backup Strategy

Pull-based backups from external system (e.g., home lab):

1. SSH into VPS and execute backup script
2. Backup script creates timestamped `.tar.gz` in `/var/backups/standard-notes/`
3. Backup script outputs the backup filename to stdout
4. SCP the backup file to remote storage
5. SSH back in to execute cleanup script (prune old backups, keep N most recent)

Example workflow from home lab:

```bash
# Run remote backup script
BACKUP_FILE=$(ssh service-backup@example.com /usr/local/bin/backup/sn-backup.sh)

# Copy the backup file down to local storage
scp service-backup@example.com:/var/backups/standard-notes/${BACKUP_FILE} /var/nas-data/sn-backups/

# Run cleanup script to prune old backups on VPS
ssh service-backup@example.com /usr/local/bin/backup/prune-backups.sh
```

#### What Must Be Backed Up

Backup contents and exclusions are defined in [docs/OPERATIONS.md](docs/OPERATIONS.md) as the single source of truth.

#### RTO/RPO Targets

- Recovery Time Objective: < 1 hour (manual restore process)
- Recovery Point Objective: Dependent on backup frequency (user-controlled)

#### Restore Procedure

Documented process to:

1. Deploy fresh Standard Notes instance (or use existing)
2. Stop services
3. Restore database from dump
4. Restore files and certificates
5. Restart services
6. Verify functionality

### 8.2 Upgrades

Software updates are inevitable and necessary for security and functionality. This section defines how application and infrastructure updates are applied safely.

#### Standard Notes Version Upgrades

Standard Notes runs using `:latest` Docker tag. Upgrades performed by:

1. Pull new image: `docker compose pull`
2. Restart services: `systemctl restart standard-notes`
3. Health checks verify successful upgrade

#### Infrastructure Upgrades

- OS security patches: Automatic via `unattended-upgrades`
- Ansible playbook updates: User re-runs playbook (idempotent)
- Docker / Docker Compose updates: Handled by Ubuntu package manager

#### Rollback Capabilities

- Database restore from backup
- Docker image pinning (if user modifies compose file to use specific tag instead of `:latest`)

### 8.3 Monitoring

Basic health monitoring enables detection of service failures and aids troubleshooting. Advanced observability tools are out of scope, but Docker health checks provide essential visibility.

#### Health Checks

All Docker Compose services MUST define health checks:

- Standard Notes: HTTP health endpoint
- MySQL: Database connectivity check
- Traefik: HTTP endpoint check

#### Service Management

`service-runner` user can execute:

- `systemctl status standard-notes`
- `systemctl start|stop|restart standard-notes`
- `docker compose logs` (via service user permissions)

#### Observability Beyond Health Checks

Out of scope. Users may add their own monitoring solutions.

## 9. Quality Requirements

Production-grade infrastructure requires specific quality attributes beyond functional correctness. These requirements ensure the system is maintainable, reproducible, and safe to operate.

### 9.1 Idempotency

All Ansible playbooks and roles must be idempotent:

- Re-running the playbook on an already-configured system makes no changes
- Re-running after partial failure completes the deployment
- No "run once" scripts or manual steps required

### 9.2 Reproducibility

Same inputs produce same outputs:

- Identical `.env` + playbook version = identical deployment
- No reliance on external state or timing
- All dependencies pinned to specific versions where possible

### 9.3 Documentation Standards

All code and configuration must be documented:

- Ansible tasks have descriptive names
- Complex logic includes comments explaining WHY
- No magic values; all configuration via variables
- README and docs provide complete operational guidance

### 9.4 Versioning Scheme

This project uses a date/time version format to preserve chronological ordering.

**Format:** `yy.Mdd.hmm`

**Rules:**

- `yy` is the two-digit year.
- `M` is the month without a leading zero.
- `dd` is the day with a leading zero.
- `h` is the hour (24-hour clock) without a leading zero.
- `mm` is the minute with a leading zero.

**Example:**

- January 28 at 9:28am → `25.128.928`

This format is monotonic over time and makes release order obvious without additional metadata.

## 10. Success Criteria

Defining measurable success criteria provides clear targets and helps evaluate whether this project achieves its goals.

### This Project Succeeds When

1. A technically-capable user can deploy Standard Notes in under 30 minutes from a fresh Ubuntu VPS
2. Security hardening is applied automatically without manual steps
3. Backups and restores work reliably using documented procedures
4. The system can be maintained over months/years without accumulating technical debt
5. Documentation is clear enough that users can troubleshoot common issues independently
6. Contributors can understand and extend the codebase without original author involvement

### User Satisfaction Indicators

- Successful deployments reported in issues/discussions
- Low rate of deployment failures or configuration errors
- Community contributions to improve documentation and automation
- Positive feedback on security posture and operational simplicity

## 11. Constraints & Assumptions

Every project operates within constraints and makes assumptions about its environment and users. Documenting these explicitly prevents misaligned expectations.

### Technical Constraints

- Single-server deployment only (no horizontal scaling)
- Docker Compose orchestration (not Kubernetes)
- Ubuntu 24.04 LTS only (initially)

### Resource Constraints

- Maintained by small team or individual (not large enterprise)
- No dedicated support team (community support only)

### User Knowledge Assumptions

- Users understand basic Linux commands
- Users can configure DNS records
- Users have SSH access to their VPS
- Users can navigate GitHub Actions UI (for CI/CD deployment)

### Security Assumptions

- Users trust GitHub to store secrets securely
- VPS provider is trustworthy
- User's control machine (for local deployment) is secure

## 12. Resolved Decisions

Architectural and operational decisions made during specification phase:

### 12.1 Docker Images and Versioning

**Decision:** Follow official Standard Notes Docker guidance at https://standardnotes.com/help/self-hosting/docker

- Use `:latest` tags for all images (Standard Notes server, MySQL, Redis, Localstack, Traefik)
- Manual upgrade process: `docker compose pull && docker compose up -d --force-recreate`
- User controls upgrade timing (not automated)
- Database migrations handled automatically by Standard Notes on container restart

**Rationale:** Matches vendor recommendations, simplifies initial deployment, users opt-in to updates.

### 12.2 Service Dependencies

**Decision:** Include all services from vendor's docker-compose.example.yml

- **server:** Standard Notes application (`standardnotes/server:latest`)
- **db:** MySQL 8 (`mysql:8`)
- **cache:** Redis 6 (`redis:6.0-alpine`)
- **localstack:** AWS SNS/SQS emulation (`localstack/localstack:3.0`)
- **traefik:** Reverse proxy with automatic TLS (added by this project)

**Rationale:** Localstack provides self-contained SNS/SQS without requiring AWS account. Redis required for session storage.

### 12.3 Backup Strategy

**Decision:** Pull-based backups from external system, no cron on VPS

- External system (home lab) initiates SSH connection as `service-backup` user
- Runs backup script on VPS: `/usr/local/bin/backup/sn-backup.sh`
- Creates timestamped tarball: `sn-backup-yyyyMMdd.HHmmss.tar.gz`
- Backup contents and exclusions are defined in [docs/OPERATIONS.md](docs/OPERATIONS.md) as the single source of truth
- VPS retains last 7 backups by default (configurable retention period)
- External system manages long-term retention and offsite copies

**Rationale:** Pull-based model eliminates need for VPS to store external credentials, aligns with 3-2-1 backup strategy.

### 12.4 TLS Certificate Strategy

**Decision:** Cloudflare DNS-01 challenge required for v1.0

- Traefik configured for Cloudflare DNS-01 challenge
- Requires Cloudflare API token with `Zone:DNS:Edit` permission
- Future enhancement: Support HTTP-01 challenge and other DNS providers

**Rationale:** DNS-01 is most reliable, works with private networks, well-tested pattern. Users wanting alternatives can modify Traefik configuration.

### 12.5 Fail2Ban for Standard Notes

**Decision:** Deferred to post-deployment analysis

- v1.0 includes SSH jail only (protects against SSH brute force)
- Standard Notes jail requires log format analysis after deployment
- No publicly available Standard Notes Fail2Ban filters found
- Document as known limitation in v1.0
- Create GitHub issue for v1.1 enhancement

**Rationale:** Cannot create effective filter without understanding log format. SSH hardening provides initial security.

### 12.6 Multi-Domain Support

**Decision:** Single domain set only in v1.0

- One primary domain: `example.com`
- One API subdomain: `api.example.com`
- Optional CNAME: `www.example.com` → `example.com`
- Multi-domain deployments are out of scope

**Rationale:** Keeps configuration simple, matches Standard Notes architecture (separate web/API domains).

### 12.7 Inventory Management

**Decision:** Dynamic inventory from environment variable

- GitHub Actions: Workflow inputs override GitHub Secrets
- First deployment: Prompts for IP address, root username, root password
- Subsequent deployments: Uses GitHub Secrets (service-deployer user + SSH key)
- Local deployment: User creates `src/inventory` file (gitignored)
- Inventory file location: `src/inventory` (follows project structure rules)

**Rationale:** Supports both initial provisioning (root/password) and hardened deployments (service account/key).

### 12.8 Unattended Upgrades

**Decision:** Security updates only by default, configurable

- Default: Security updates only (`UNATTENDED_UPGRADES=security-only`)
- Optional: All updates (`UNATTENDED_UPGRADES=all`)
- Optional: Disabled (`UNATTENDED_UPGRADES=none`)
- Configured via environment variable

**Rationale:** Conservative default (security-only) suitable for production, flexibility for user preference.

### 12.9 Time Synchronization

**Decision:** Use Ubuntu 24.04 default (systemd-timesyncd)

- systemd-timesyncd built-in to Ubuntu 24.04
- Syncs with default Ubuntu NTP servers
- No additional configuration needed
- Sufficient accuracy for single-server deployment

**Rationale:** Zero-config solution, adequate for use case, one less service to manage.

### 12.10 CI/CD and Quality Gates

**Decision:** Linting workflow only, manual deployment trigger

- GitHub Actions workflow for linting: ansible-lint, yamllint, shellcheck
- Runs on push and pull requests
- CodeQL for bash scripts in roles
- Deployment workflow is manual trigger only (workflow_dispatch)
- No automatic deployment on push to main

**Rationale:** Manual deployment prevents accidental production changes. Linting catches errors before merge.

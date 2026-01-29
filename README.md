# Standard Notes Infrastructure-as-Code

Production-grade Infrastructure-as-Code (IaC) for deploying self-hosted Standard Notes instances with security and operational best practices built in.

[![CI - Lint and Validate](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/ci.yml/badge.svg)](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/ci.yml)
[![Deploy](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/deploy.yml/badge.svg)](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/deploy.yml)
[![CodeQL](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/robertsinfosec/standard-notes-iac/actions/workflows/github-code-scanning/codeql)
[![Dependabot](https://img.shields.io/badge/dependabot-enabled-025E8C?logo=dependabot&logoColor=white)](https://github.com/robertsinfosec/standard-notes-iac/security/dependabot)
[![issues](https://img.shields.io/github/issues/robertsinfosec/standard-notes-iac?label=issues)](https://github.com/robertsinfosec/standard-notes-iac/issues)
[![PRs](https://img.shields.io/github/issues-pr/robertsinfosec/standard-notes-iac?label=pull%20requests)](https://github.com/robertsinfosec/standard-notes-iac/pulls)
[![last commit](https://img.shields.io/github/last-commit/robertsinfosec/standard-notes-iac?label=last%20commit)](https://github.com/robertsinfosec/standard-notes-iac/commits/main)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-2.14+-red.svg)](https://www.ansible.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange.svg)](https://ubuntu.com/)

## Overview

This project automates the deployment of a secure, production-ready Standard Notes server on a single VPS using Ansible, Docker Compose, and industry-standard security practices.

**What you get:**

- 🔐 **Security by default** - SSH hardening, UFW firewall, Fail2Ban, user separation
- 🔒 **Automatic HTTPS** - Let's Encrypt TLS certificates via Traefik with Cloudflare DNS
- 📦 **Docker Compose** - Simple, single-server deployment
- 🔄 **Idempotent automation** - Ansible playbooks safe to run repeatedly
- 💾 **Backup-ready** - Pull-based backup scripts and procedures
- 📚 **Comprehensive docs** - Architecture, security design, operations guides

## Quick Start

Deploy Standard Notes to your VPS in 30 minutes. See [QUICKSTART.md](QUICKSTART.md) for complete walkthrough.

### Prerequisites

- Ubuntu 24.04 LTS VPS (4GB+ RAM, 20GB+ disk)
- Domain name with DNS configured
- Cloudflare account (for automated TLS)
- GitHub account (for GitHub Actions deployment)

### Deployment Options

**Option A: GitHub Actions (Recommended)**

1. Fork this repository
2. Configure GitHub Actions secrets and variables (authoritative list in [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md))
3. Push to main branch or manually trigger workflow
4. Access your Standard Notes instance at `https://your-domain.com`

**Option B: Local Deployment**

```bash
# Clone repository
git clone https://github.com/yourusername/standard-notes-iac.git
cd standard-notes-iac

# Configure secrets
cd src/
cp .env.example .env
# Edit .env with your secrets

# Run deployment
ansible-playbook -i inventory site.yml
```

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

## Architecture

This deployment uses:

- **Standard Notes** - Latest version, port 3000 (internal)
- **MySQL 8.0/9.0** - Database, port 3306 (internal)
- **Traefik v3.0** - Reverse proxy with automatic HTTPS
- **Ubuntu 24.04 LTS** - Host operating system
- **Docker Compose** - Container orchestration

All services run on a single VPS with security hardening applied automatically.

For detailed architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Security

Security controls implemented automatically:

- **SSH hardening** - Key-only authentication, no root login
- **UFW firewall** - Ports 22, 80, 443 only
- **Fail2Ban** - Intrusion detection and automatic IP banning
- **User separation** - Least-privilege accounts limit blast radius
- **TLS encryption** - Let's Encrypt certificates via Cloudflare DNS challenge
- **Automatic updates** - Security patches via unattended-upgrades

This list is a summary. The single source of truth for security controls, ports, and hardening details is [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md).

## Documentation

### Getting Started

- [QUICKSTART.md](QUICKSTART.md) - Step-by-step deployment guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute to this project

### Technical Documentation

- [docs/PRD.md](docs/PRD.md) - Product requirements and scope
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System architecture and design
- [docs/SECURITY_DESIGN.md](docs/SECURITY_DESIGN.md) - Security controls and hardening
- [docs/OPERATIONS.md](docs/OPERATIONS.md) - Backup, upgrades, monitoring, troubleshooting
- [docs/TESTING.md](docs/TESTING.md) - Testing standards and validation steps

### Standards

- [STYLE_GUIDE.md](STYLE_GUIDE.md) - Coding and documentation standards

## Features

### Automated Deployment

- Ansible playbooks handle all configuration
- Idempotent - safe to run multiple times
- Dual deployment modes (GitHub Actions + local)
- No manual configuration required

### Security by Default

- Hardened SSH configuration
- Firewall configured automatically
- Intrusion detection with Fail2Ban
- User account separation for defense in depth
- Secrets management via environment variables

### Production Ready

- Health checks for all services
- Automatic container restarts
- systemd service management
- Comprehensive logging
- Pull-based backup procedures (see [docs/OPERATIONS.md](docs/OPERATIONS.md) for the authoritative process and backup contents)

### Operational Excellence

- Detailed operations guide
- Troubleshooting documentation
- Upgrade procedures
- Disaster recovery procedures

## System Requirements

### VPS Requirements

- **OS:** Ubuntu 24.04 LTS (fresh installation)
- **RAM:** 4GB minimum (8GB recommended)
- **CPU:** 2+ vCPUs
- **Disk:** 20GB minimum (50GB+ recommended for user data)
- **Network:** Public IPv4 address

### Supported VPS Providers

Tested with:

- RackNerd
- DigitalOcean
- Linode
- Vultr
- Hetzner

Any VPS provider supporting Ubuntu 24.04 should work.

### Local Development Requirements

For local Ansible deployment:

- Ansible 2.14+
- Python 3.8+
- SSH access to VPS

## Project Structure

```
/
├── docs/                  # Technical documentation
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── SECURITY_DESIGN.md
│   └── OPERATIONS.md
├── src/                   # Implementation code (TBD)
│   ├── site.yml           # Main Ansible playbook
│   ├── roles/             # Ansible roles
│   ├── scripts/           # Shell scripts
│   └── .env.example       # Environment template
├── .github/               # GitHub Actions workflows
├── QUICKSTART.md          # Quick start guide
├── CONTRIBUTING.md        # Contribution guidelines
├── STYLE_GUIDE.md         # Code and documentation standards
├── README.md              # This file
└── LICENSE                # MIT License
```

## Roadmap

### v1.0 (Current Focus)

- ✅ Complete documentation suite
- ⏳ Ansible playbooks and roles
- ⏳ GitHub Actions workflow
- ⏳ Testing and validation

### Future Enhancements

- Terraform examples for VPS provisioning
- Multi-platform support (Debian, RHEL)
- High-availability architecture option
- Advanced monitoring (Prometheus/Grafana)
- Automated backup testing

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#12-future-enhancements) for complete roadmap.

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Code of conduct
- Development workflow
- Testing requirements
- Pull request process
- Style guide compliance

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/standard-notes-iac/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/standard-notes-iac/discussions)
- **Standard Notes:** [Official Help](https://standardnotes.com/help)

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Standard Notes](https://standardnotes.com/) - For creating an excellent self-hosted notes platform
- [Ansible](https://www.ansible.com/) - For powerful infrastructure automation
- [Traefik](https://traefik.io/) - For elegant reverse proxy with automatic HTTPS

## Disclaimer

This project is not officially affiliated with Standard Notes. It is a community-driven effort to simplify self-hosting Standard Notes with infrastructure best practices.

---

**Ready to deploy?** Start with [QUICKSTART.md](QUICKSTART.md) 🚀

![Alt](https://repobeats.axiom.co/api/embed/27f04ce61cc4c43e5959055c3c9b255eefbdf530.svg "Repobeats analytics image")
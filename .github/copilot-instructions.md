# GitHub Copilot Instructions

These instructions guide AI assistants (GitHub Copilot, Cursor, Cline, etc.) when working on this Infrastructure-as-Code project.

## Project Context

You are working on a **public, open-source Infrastructure-as-Code (IaC) project** for deploying self-hosted Standard Notes servers. This project emphasizes:

- Production-grade quality suitable for public consumption
- Security by default
- Comprehensive documentation
- Zero technical debt tolerance

## Core Principles

### 1. Documentation-First Workflow

All implementation work requires specification approval first.

#### Documentation and Code Separation

The project uses strict folder separation:

- Documentation and specifications live in `docs/` directory
- Implementation code lives in `src/` directory
- Never write implementation code before documentation is complete and approved
- Update documentation when making code changes

#### Key Documentation Files

These are the primary specification documents:
- `docs/PRD.md` - Product requirements
- `docs/ARCHITECTURE.md` - System design
- `docs/SECURITY_DESIGN.md` - Security architecture
- `docs/OPERATIONS.md` - Operational procedures
- `QUICKSTART.md` - Getting started guide
- `CONTRIBUTING.md` - Contribution guidelines
- `STYLE_GUIDE.md` - Coding standards

### 2. Repository Structure

The project enforces strict folder conventions to maintain organization.

#### Folder Layout

All files must be placed in their designated locations:

```
/
├── docs/                  # ALL design documentation
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── SECURITY_DESIGN.md
│   └── OPERATIONS.md
├── src/                   # ALL implementation code
│   ├── site.yml           # Main Ansible playbook
│   ├── roles/             # Ansible roles
│   ├── scripts/           # Shell scripts
│   └── .env.example       # Environment template
├── .github/               # GitHub-specific files
├── QUICKSTART.md          # User-facing quick start
├── CONTRIBUTING.md        # Contribution guide
├── STYLE_GUIDE.md         # Coding standards
├── README.md              # Project overview
└── LICENSE                # MIT license
```

#### Critical Rule

Never create code files outside `src/` directory.

### 3. Zero Technical Debt

Write code correctly the first time. Never use placeholder comments or incomplete implementations.

#### Prohibited in All Code

These patterns are never acceptable:

- `TODO` comments
- `FIXME` comments
- Commented-out code
- "Will implement later" placeholders
- Half-finished features

#### Correct Approach

Follow these practices instead:

- Complete implementation fully before committing
- Create GitHub issues for future enhancements
- Document known limitations in appropriate docs

### 4. Security Posture

Security is a primary concern for this public infrastructure project. All code must follow security best practices by default.

#### Never Commit Secrets to Version Control

All sensitive credentials must be kept out of Git:

- No real passwords, API keys, or tokens in code
- Use placeholder values in examples: `<generated-secret>`, `your-api-token-here`
- Secrets come from environment variables or GitHub Actions secrets
- `.env` file must be in `.gitignore`

#### Security Checklist for All Code

Every code contribution must meet these security requirements:

- No hardcoded credentials
- Proper file permissions (600 for secrets, 640 for configs, 755 for scripts)
- Use cryptographically secure random generation for secrets
- Follow principle of least privilege
- Validate and sanitize all inputs

### 5. Quality Standards

All code must meet production-grade quality requirements before being merged.

#### Code Quality Requirements

Every contribution must satisfy these criteria:

- **Idempotent** - Running multiple times produces same result
- **Tested** - Deployed to real environment and verified
- **Documented** - Comments explain WHY, not WHAT
- **Linted** - Passes all linters (ansible-lint, shellcheck, yamllint)
- **Consistent** - Follows STYLE_GUIDE.md conventions

## Coding Standards Summary

These are condensed examples. See STYLE_GUIDE.md for complete standards.

> [!IMPORTANT]
> **Markdown Standard Enforcement**
>
> ALL markdown files must follow these rules with ZERO exceptions:
>
> 1. **Use real headers, never bold text for headings**
>    - ✓ Correct: `### Configuration Options`
>    - ✗ Wrong: `**Configuration Options:**`
>
> 2. **Every section needs explanatory text before subsections/lists**
>    - ✓ Correct: 
>      ```markdown
>      ### Backup Strategy
>      
>      Pull-based backups from external system (e.g., home lab):
>      
>      - External system initiates SSH connection
>      ```
>    - ✗ Wrong:
>      ```markdown
>      ### Backup Strategy
>      
>      - External system initiates SSH connection
>      ```
>
> 3. **Blank lines required above and below ALL markdown elements**
>    - Headers, code blocks, lists, tables, admonitions
>    - ✓ Correct spacing shown in examples above
>    - ✗ Wrong: Any element touching another without blank line
>
> 4. **Use GitHub admonitions, not bold pseudo-headers**
>    - ✓ Correct: `> [!IMPORTANT]` with content
>    - ✗ Wrong: `**Important:**` inline in paragraph
>
> **Validation:** Every markdown file you create MUST pass these checks before committing.

### Ansible

Example showing FQCN usage and variable patterns:

```yaml
# Use FQCN (Fully Qualified Collection Names)
- name: Install package
  ansible.builtin.apt:
    name: docker-ce
    state: present
  become: true
  tags:
    - docker

# Variables use snake_case
mysql_root_password: "{{ lookup('env', 'MYSQL_ROOT_PASSWORD') }}"

# Never hardcode secrets
database_password: "{{ db_password }}"  # ✓ Good
database_password: "supersecret123"     # ✗ Bad
```

### Shell Scripts

Shell scripts must use safe defaults and clear naming conventions:

```bash
#!/bin/bash
set -euo pipefail  # Always set safe options

# Constants in UPPER_CASE
BACKUP_DIR="/var/backups/standard-notes"

# Variables in snake_case
backup_file="backup-$(date +%Y%m%d).tar.gz"

# Always quote variables
if [[ -f "$backup_file" ]]; then
    rm "$backup_file"
fi

# Functions in snake_case
create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    # Implementation
}
```

### Markdown Documentation

Follow these markdown standards for all documentation files:

```markdown
# Use Real Headers (not bold text)

## Section Name

Every section needs explanatory text before subsections or content.

### Subsection

More explanatory text here.

> [!IMPORTANT]
> Use GitHub admonitions for emphasis, not bold headers.

- List items need blank lines above and below
- Use `code` for inline code/paths
- Use \`\`\`language blocks for code samples
```

### Docker Compose

Docker Compose configurations must include health checks and explicit configuration:

```yaml
services:
  servicename:
    image: image:tag                # Pin versions
    container_name: project-service # Consistent naming
    restart: unless-stopped         # Always set restart policy
    environment:
      VAR: ${ENV_VAR}              # From .env file
    healthcheck:                   # Always include health checks
      test: ["CMD", "curl", "-f", "http://localhost/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Git Commits

All commit messages must follow conventional commit format:

```
type: Short summary (max 50 chars)

Longer explanation of WHY this change was made, not WHAT changed.
The diff shows WHAT changed - the commit message explains WHY.

Fixes #123
```

**Commit types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`

## Common Patterns

These are the most frequently used code patterns in this project.

### Ansible Variable Loading

How to load variables from environment (GitHub Actions or local .env file):

```yaml
# Load from environment (GitHub Actions or local .env)
mysql_password: "{{ lookup('env', 'MYSQL_PASSWORD') }}"
domain: "{{ lookup('env', 'DOMAIN') }}"

# Provide defaults for optional values
smtp_port: "{{ lookup('env', 'SMTP_PORT') | default('587') }}"
```

### File Permissions

Standard file permission patterns for security:

```yaml
# Secrets: owner-only read/write
- name: Create .env file
  ansible.builtin.template:
    src: env.j2
    dest: /opt/standard-notes/.env
    owner: service-runner
    group: standard-notes
    mode: '0600'

# Configs: owner read/write, group read
- name: Copy docker-compose
  ansible.builtin.template:
    src: docker-compose.yaml.j2
    dest: /opt/standard-notes/docker-compose.yaml
    owner: service-runner
    group: standard-notes
    mode: '0640'

# Scripts: executable
- name: Copy backup script
  ansible.builtin.copy:
    src: sn-backup.sh
    dest: /usr/local/bin/backup/sn-backup.sh
    owner: root
    group: root
    mode: '0755'
```

### User Accounts

Project uses user separation for security:

- **service-deployer** - Deployment and administration (full sudo)
- **service-runner** - Runs Standard Notes service (limited sudo for systemctl)
- **service-backup** - Backup operations (limited sudo for backup scripts)
- **standard-notes** group - Shared read access to application files

## Architecture Context

### Target Platform

- **OS:** Ubuntu 24.04 LTS only (initially)
- **Deployment:** Single-server VPS (DigitalOcean, Linode, Vultr, etc.)
- **Orchestration:** Docker Compose (not Kubernetes)
- **Configuration:** Ansible 2.14+
- **CI/CD:** GitHub Actions (primary), local .env (secondary)

### Components

- **Standard Notes** - `:latest` tag, port 3000 internal
- **MySQL 8.0/9.0** - Port 3306 internal only
- **Traefik v3.0** - Reverse proxy, ports 80/443, automatic TLS via Let's Encrypt
- **UFW Firewall** - Ports 22, 80, 443 only
- **Fail2Ban** - SSH jail (Standard Notes jail TBD)

### Storage Strategy

**Bind mounts (not named volumes)** under `/opt/standard-notes/`:

```
/opt/standard-notes/
├── docker-compose.yaml
├── .env
├── traefik/
│   ├── acme.json
│   └── traefik.yaml
├── standardnotes/
│   └── uploads/
└── mysql/
    └── data/
```

Rationale: Simpler backups, easier troubleshooting, no Docker volume management.

### Backup Strategy

**Pull-based backups** from external system:

- External system (home lab) initiates via SSH as `service-backup` user
- Runs backup script on VPS
- Transfers archive to external storage
- VPS retains recent backups, external archives long-term

## When to Ask Questions

**Ask clarifying questions when:**

- Requirements are ambiguous or contradictory
- Security implications are unclear
- Multiple valid approaches exist
- Scope is unclear (what's in scope vs future enhancement)
- User intent is uncertain

**Don't assume:**

- Default configurations without explicit requirements
- Security posture (ask if uncertain)
- Scope creep (stick to defined requirements)

## Testing Requirements

Before suggesting code changes, ensure you can answer:

1. **Does it work?** - Tested in real environment?
2. **Is it idempotent?** - Can run multiple times safely?
3. **Does it follow standards?** - Complies with STYLE_GUIDE.md?
4. **Is it documented?** - Updated relevant docs?
5. **Is it secure?** - No secrets, proper permissions, least privilege?

## Response Style

When helping with this project:

- **Be explicit** - State assumptions and reasoning
- **Reference docs** - Link to PRD, ARCHITECTURE, etc. when relevant
- **Show examples** - Provide code examples, not just descriptions
- **Explain tradeoffs** - If multiple approaches exist, explain pros/cons
- **Think production** - This is public, production-grade infrastructure

## Prohibited Shortcuts

**Never suggest or implement:**

- "Just do X for now, we'll fix it later"
- Commented-out code "for reference"
- TODO/FIXME comments
- Hardcoded secrets "temporarily"
- Skipping tests "to move faster"
- Documentation "we'll add later"

**Instead:**

- Do it right the first time
- Create GitHub issues for future work
- Document known limitations properly
- Use environment variables for all secrets
- Test before committing
- Update docs with code changes

## Project Goals Alignment

Every contribution should align with project goals from PRD:

**In scope:**
- Automated, reproducible deployments
- Security by default
- Self-hosting on single VPS
- Dual deployment modes (GitHub Actions + local)
- Comprehensive documentation

**Out of scope (v1.0):**
- Multi-server deployments
- High availability / clustering
- Managed database services (RDS, etc.)
- DNS management automation
- Multiple OS support (Ubuntu 24.04 only initially)

## Getting Help

If uncertain about architectural decisions, security implications, or scope:

1. Check existing documentation (PRD, ARCHITECTURE, SECURITY_DESIGN)
2. Search GitHub issues for similar discussions
3. Ask the user for clarification
4. Propose options with tradeoffs rather than assumptions

---

**Remember:** This project serves as a reference implementation for the community. Quality and clarity are more important than speed.

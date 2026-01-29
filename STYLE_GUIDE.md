# Style Guide

This document defines coding and documentation standards for the Standard Notes IaC project to maintain consistency, quality, and long-term maintainability.

> [!IMPORTANT]
> All contributions must follow these standards. Pull requests that violate style guidelines will be asked to revise before merging.

## Table of Contents

1. [General Principles](#1-general-principles)
2. [Ansible Standards](#2-ansible-standards)
3. [Shell Script Standards](#3-shell-script-standards)
4. [Markdown Documentation](#4-markdown-documentation)
5. [Docker Compose Standards](#5-docker-compose-standards)
6. [Naming Conventions](#6-naming-conventions)
7. [Git Commit Standards](#7-git-commit-standards)

## 1. General Principles

### 1.1 Zero Technical Debt

Write code correctly the first time. No TODOs, no commented code, no "fix later" placeholders.

**Prohibited:**

```yaml
# TODO: Add health check later
# FIXME: This is broken but works for now
# NOTE: Need to refactor this eventually
```

**Correct:**

If something needs improvement, either implement it now or create a GitHub issue to track it properly.

### 1.2 Idempotency

All infrastructure code must be idempotent - running it multiple times produces the same result without errors.

**Example - Ansible task idempotency:**

```yaml
- name: Ensure directory exists
  ansible.builtin.file:
    path: /opt/standard-notes
    state: directory
    owner: service-runner
    group: standard-notes
    mode: '0750'
```

Running this task 10 times should succeed 10 times and make changes only on first run.

### 1.3 Explicit Over Implicit

Be explicit about behavior, dependencies, and requirements. Don't rely on defaults that might change.

```yaml
# Good - Explicit
- name: Install Docker
  ansible.builtin.apt:
    name: docker-ce
    state: present
    update_cache: true
  become: true

# Bad - Implicit assumptions
- name: Install Docker
  apt:
    name: docker-ce
```

### 1.4 Documentation First

Document WHY decisions were made, not just WHAT the code does. Future maintainers need context.

## 2. Ansible Standards

### 2.1 File Organization

```
src/
├── site.yml                    # Main playbook entry point
├── inventory                   # Inventory file (for local deployment)
├── group_vars/
│   └── all.yml                 # Variables for all hosts
├── host_vars/
│   └── hostname.yml            # Host-specific variables
└── roles/
    ├── common/                 # Common system setup
    ├── users/                  # User account management
    ├── ssh-hardening/          # SSH security configuration
    ├── firewall/               # UFW firewall setup
    ├── fail2ban/               # Intrusion detection
    ├── docker/                 # Docker installation
    ├── backup/                 # Backup configuration
    └── standardnotes/          # Standard Notes deployment
```

### 2.2 Naming Conventions

**Playbooks:** `kebab-case.yml`
```
deploy-standard-notes.yml
configure-firewall.yml
```

**Roles:** `kebab-case` directories
```
roles/ssh-hardening/
roles/standard-notes/
```

**Variables:** `snake_case`
```yaml
mysql_root_password: "{{ lookup('env', 'MYSQL_ROOT_PASSWORD') }}"
standard_notes_domain: "{{ lookup('env', 'DOMAIN') }}"
```

**Tasks:** Clear, descriptive names in present tense
```yaml
- name: Install Docker CE package
- name: Create Standard Notes directory
- name: Copy docker-compose template
```

### 2.3 YAML Formatting

**Indentation:** 2 spaces (no tabs)

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: "{{ mysql_root_password }}"
```

**Line length:** Aim for < 120 characters

**Quotes:** Use quotes for strings with special characters or variables

```yaml
# Good
path: "/opt/standard-notes"
name: "{{ service_name }}"

# Acceptable for simple strings
state: present
mode: '0644'
```

### 2.4 Task Structure

Standard task format:

```yaml
- name: Clear, descriptive task name
  ansible.builtin.module_name:
    parameter: value
    another_param: value
  become: true                  # Explicit privilege escalation
  when: condition               # Conditional execution
  tags:
    - tag-name                  # For selective execution
  notify: handler_name          # Trigger handlers
```

### 2.5 Module Usage

**Always use FQCN (Fully Qualified Collection Names):**

```yaml
# Good
- name: Install package
  ansible.builtin.apt:
    name: nginx
    state: present

# Bad - Short form deprecated
- name: Install package
  apt:
    name: nginx
```

**Common modules:**
- `ansible.builtin.apt` - Package management
- `ansible.builtin.file` - File/directory management
- `ansible.builtin.template` - Template rendering
- `ansible.builtin.copy` - Copy files
- `ansible.builtin.service` - Service management
- `ansible.builtin.user` - User management
- `ansible.builtin.command` - Run commands (use sparingly)

### 2.6 Variables and Secrets

**Never hardcode secrets:**

```yaml
# Good - From environment variable
mysql_password: "{{ lookup('env', 'MYSQL_PASSWORD') }}"

# Bad - Hardcoded
mysql_password: "supersecret123"
```

**Variable precedence order:**
1. Extra vars (`-e` command line)
2. Environment variables
3. `group_vars/all.yml`
4. Role defaults (`roles/rolename/defaults/main.yml`)

### 2.7 Error Handling

```yaml
- name: Stop Standard Notes service
  ansible.builtin.service:
    name: standard-notes
    state: stopped
  failed_when: false              # Don't fail if service doesn't exist
  
- name: Ensure critical directory exists
  ansible.builtin.file:
    path: /opt/standard-notes
    state: directory
  # No failed_when - this MUST succeed
```

### 2.8 Validation

**Always validate Ansible code:**

```bash
# Syntax check
ansible-playbook --syntax-check site.yml

# Linting
ansible-lint

# Dry run
ansible-playbook --check site.yml
```

## 3. Shell Script Standards

### 3.1 Shebang and Options

Every shell script must start with:

```bash
#!/bin/bash
#
# Script description here
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

**Explanation:**
- `set -e` - Exit immediately if any command fails
- `set -u` - Treat undefined variables as errors
- `set -o pipefail` - Fail on pipe errors (not just last command)

### 3.2 Variable Naming

**Constants:** `UPPER_CASE`

```bash
BACKUP_DIR="/var/backups/standard-notes"
RETENTION_DAYS=30
LOG_FILE="/var/log/backup.log"
```

**Variables:** `snake_case`

```bash
backup_file="backup-$(date +%Y%m%d).tar.gz"
mysql_container="standard-notes-mysql"
```

### 3.3 Quoting

**Always quote variables to handle spaces:**

```bash
# Good
if [ -f "$backup_file" ]; then
    rm "$backup_file"
fi

# Bad - breaks on filenames with spaces
if [ -f $backup_file ]; then
    rm $backup_file
fi
```

### 3.4 Conditionals

Use `[[ ]]` for conditionals (bash), not `[ ]`:

```bash
# Good - Bash conditional
if [[ "$status" == "running" ]]; then
    echo "Service is running"
fi

# Acceptable for POSIX compatibility
if [ "$status" = "running" ]; then
    echo "Service is running"
fi
```

### 3.5 Functions

```bash
# Function names: snake_case
create_backup() {
    local timestamp
    local backup_file
    
    timestamp=$(date +%Y%m%d-%H%M%S)
    backup_file="${BACKUP_DIR}/backup-${timestamp}.tar.gz"
    
    # Implementation
    echo "Creating backup: $backup_file"
}

# Main execution
main() {
    create_backup
    cleanup_old_backups
}

main "$@"
```

### 3.6 Error Messages

```bash
# Consistent error format
error() {
    echo "ERROR: $*" >&2
}

warn() {
    echo "WARNING: $*" >&2
}

info() {
    echo "INFO: $*"
}

# Usage
if [[ ! -d "$BACKUP_DIR" ]]; then
    error "Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi
```

### 3.7 ShellCheck Validation

**All shell scripts must pass ShellCheck:**

```bash
shellcheck script.sh
```

Address all warnings unless explicitly justified with inline comments:

```bash
# shellcheck disable=SC2034  # Variable used in sourced script
EXTERNAL_VAR="value"
```

## 4. Markdown Documentation

All markdown documentation must follow professional formatting standards for consistency and readability.

### 4.1 Section Headers

Use proper markdown headers, never simulate them with bold text.

#### 4.1.1 Correct Usage

```markdown
### Configuration Options

The following environment variables control application behavior.
```

#### 4.1.2 Incorrect Usage

```markdown
**Configuration Options:**

The following environment variables...
```

> [!IMPORTANT]
> If content is important enough to stand out, it deserves a real header (`###`), not bolded text.

### 4.2 Section Descriptions

Every section header must have at least one sentence explaining what the section contains.

#### 4.2.1 Correct Example

```markdown
### Rate Limiting

The API enforces per-IP and global rate limits using Cloudflare Durable Objects.

| Setting | Default | Description |
|---------|---------|-------------|
...
```

#### 4.2.2 Incorrect Example

```markdown
### Rate Limiting

| Setting | Default | Description |
|---------|---------|-------------|
...
```

> [!IMPORTANT]
> Readers need context before diving into details. Every header must have explanatory text.

### 4.3 Blank Lines

All markdown elements MUST have blank lines above and below them for proper rendering.

#### 4.3.1 Elements Requiring Blank Lines

- Headings
- Code blocks
- Lists
- Tables
- Block quotes
- Admonitions

#### 4.3.2 Correct Example

```markdown
This is a paragraph.

### Heading

This is another paragraph.

```typescript
const example = 'code';
```

And more text.
```

#### 4.3.3 Incorrect Example

```markdown
This is a paragraph.
### Heading
More text with no spacing.
```typescript
code here
```
And more text.
```

> [!IMPORTANT]
> GitHub-Flavored Markdown requires blank lines above and below all structural elements for proper rendering.

### 4.4 No Horizontal Rules

Do NOT use `---` horizontal rules in documentation.

Section headers already create visual separation when rendered. Adding `---` creates unnecessary double lines.

#### 4.4.1 Incorrect Example

```markdown
## Section One

Content here.

---

## Section Two

More content.
```

#### 4.4.2 Correct Example

```markdown
## Section One

Content here.

## Section Two

More content.
```

> [!IMPORTANT]
> Headers provide sufficient visual separation. Horizontal rules create double lines and visual clutter.

### 4.5 No Emoji in Headers

Do NOT use emoji in section headers for professional appearance.

#### 4.5.1 Correct Example

```markdown
### Production Ready

Built for reliable operation in production environments.
```

#### 4.5.2 Incorrect Example

```markdown
### 🐳 Production Ready

Built for reliable operation...
```

> [!IMPORTANT]
> Professional documentation avoids decorative emoji in structural elements like headers.

### 4.6 List Item Descriptors

Bolded list items with colons are acceptable for describing options or examples within content.

#### 4.6.1 Correct Example

```markdown
Configuration requirements:

- **Required:** `FREEBUSY_ICAL_URL` for upstream calendar
- **Optional:** `CACHE_TTL_SECONDS` for caching duration (default: 60)
```

#### 4.6.2 Example Code Usage

```markdown
Run the development server:

```bash
npm --prefix src run dev
```
```

> [!NOTE]
> Bolded descriptors in lists (like `**Required:**`) are content labels, not section headers, and are acceptable.

### 4.7 GitHub Admonitions

Use GitHub-Flavored Markdown admonitions to highlight important information without breaking document flow.

#### 4.7.1 Available Admonition Types

```markdown
> [!NOTE]
> Useful information that users should know.

> [!TIP]
> Helpful advice for doing things better.

> [!IMPORTANT]
> Key information users need to know.

> [!WARNING]
> Urgent info that needs immediate attention.

> [!CAUTION]
> Advises about risks or negative outcomes.
```

> [!TIP]
> Use admonitions to emphasize rules, warnings, or key concepts without adding extra headers.

### 4.8 Code Comments

Explain WHY, not WHAT:

```typescript
// Good - Explain WHY, not WHAT
// Use UTC to avoid timezone issues with DST transitions
const timestamp = new Date().toISOString();

// Hash IPs to comply with privacy policy and GDPR
const hashedIp = await hashIp(clientIp, env.RL_SALT);

// Skip already-removed trailers to avoid re-downloading
if (removedSet.has(trailerId)) {
  continue;
}

// Bad - Stating the obvious
counter += 1;  // ❌ Increment counter
const x = 5;   // ❌ Set x to 5
```

## 5. Docker Compose Standards

### 5.1 File Structure

```yaml
services:
  servicename:
    image: image:tag                    # Explicit version
    container_name: container-name      # Explicit container name
    restart: unless-stopped             # Restart policy
    environment:
      ENV_VAR: value
    volumes:
      - /host/path:/container/path
    networks:
      - network-name
    healthcheck:                        # Always include health checks
      test: ["CMD", "command"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    depends_on:
      dependency:
        condition: service_healthy      # Wait for healthy, not just started

networks:
  network-name:
    driver: bridge
```

### 5.2 Naming Conventions

**Services:** `lowercase`, no special characters

```yaml
services:
  mysql:
  standardnotes:
  traefik:
```

**Container names:** Project prefix with hyphen separator

```yaml
container_name: standard-notes-mysql
container_name: standard-notes-app
container_name: standard-notes-traefik
```

**Networks:** Descriptive, project-scoped

```yaml
networks:
  standard-notes-net:
```

**Volumes (if used):** Project prefix

```yaml
volumes:
  standard-notes-mysql-data:
```

### 5.3 Environment Variables

**Prefer .env file over inline values:**

```yaml
# Good - From .env file
environment:
  MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
  DOMAIN: ${DOMAIN}

# Bad - Hardcoded
environment:
  MYSQL_ROOT_PASSWORD: supersecret
  DOMAIN: example.com
```

### 5.4 Health Checks

**Every service must have a health check:**

```yaml
# MySQL health check
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# HTTP service health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 5.5 Restart Policies

**Standard restart policy:**

```yaml
restart: unless-stopped
```

**Only use `no` if service should not auto-restart:**

```yaml
restart: no  # One-time migration tasks, etc.
```

### 5.6 Resource Limits (Optional but Recommended)

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '1.0'
      memory: 1G
```

## 6. Naming Conventions

### 6.1 Files and Directories

**Ansible playbooks:** `kebab-case.yml`
```
deploy-standard-notes.yml
configure-firewall.yml
```

**Shell scripts:** `kebab-case.sh`
```
sn-backup.sh
prune-backups.sh
```

**Documentation:** `SCREAMING-KEBAB-CASE.md` for root-level, `Title Case.md` for docs/
```
README.md
CONTRIBUTING.md
QUICKSTART.md
docs/ARCHITECTURE.md
docs/PRD.md
```

**Directories:** `kebab-case`
```
roles/ssh-hardening/
roles/standard-notes/
```

### 6.2 Variables

**Ansible/YAML:** `snake_case`
```yaml
mysql_root_password
standard_notes_domain
backup_retention_days
```

**Environment variables:** `SCREAMING_SNAKE_CASE`
```bash
MYSQL_ROOT_PASSWORD
AUTH_JWT_SECRET
DOMAIN
```

**Shell script variables:** `snake_case` for variables, `UPPER_CASE` for constants
```bash
backup_file="backup.tar.gz"
BACKUP_DIR="/var/backups"
```

### 6.3 Functions

**Shell scripts:** `snake_case`
```bash
create_backup()
prune_old_backups()
verify_mysql_connection()
```

**Ansible handlers:** `lowercase with spaces`
```yaml
handlers:
  - name: restart docker
  - name: reload ufw
```

### 6.4 Users and Groups

**System users:** `service-` prefix with kebab-case
```
service-deployer
service-runner
service-backup
```

**Groups:** `kebab-case`
```
standard-notes
docker
```

### 6.5 Services

**systemd services:** Project name with `.service`
```
standard-notes.service
```

**Docker Compose services:** `lowercase`, descriptive
```yaml
services:
  mysql:
  standardnotes:
  traefik:
```

## 7. Git Commit Standards

### 7.1 Commit Message Format

```
<type>: <short summary in imperative mood>

<optional longer description explaining WHY>

<optional footer with issue references>
```

**First line rules:**
- Maximum 50 characters
- Imperative mood ("Add feature" not "Added feature")
- No period at end
- Lowercase after colon

### 7.2 Commit Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code formatting, no logic change |
| `refactor` | Code restructuring, no behavior change |
| `test` | Add or update tests |
| `chore` | Maintenance, dependencies, tooling |
| `security` | Security improvements |

### 7.3 Commit Message Examples

**Good examples:**

```
feat: Add Fail2Ban jail for Standard Notes

Adds custom filter to detect repeated failed login attempts and
automatically ban attacking IP addresses. Reduces risk of brute
force credential attacks.

Fixes #42
```

```
fix: Correct UFW rule ordering for Docker

Docker manipulates iptables directly, which can bypass UFW rules.
This ensures UFW rules are inserted in correct order relative to
Docker chains by reloading UFW after Docker starts.

Relates to #38
```

```
docs: Improve TLS troubleshooting guide

Added common issue: DNS not propagated causing certificate issuance
failure. Includes verification commands and expected wait times.
```

```
chore: Update Ansible to 2.15.1

Includes security fixes for CVE-2023-XXXXX and performance
improvements for template rendering.
```

**Bad examples:**

```
Fixed stuff  ❌ Too vague
Update README  ❌ No type prefix
feat: Added new feature for users.  ❌ Past tense, period at end
```

### 7.4 Commit Body

**Use body to explain WHY, not WHAT:**

```
refactor: Extract backup logic into separate role

The backup configuration was embedded in the standardnotes role,
making it difficult to reuse for other services. Extracting it
into a dedicated role improves modularity and allows backup
configuration to be applied independently.

This refactoring maintains identical functionality - no behavior
changes for end users.
```

### 7.5 Commit Footer

**Reference issues:**

```
Fixes #123          # Closes issue
Closes #123         # Closes issue
Resolves #123       # Closes issue
Relates to #456     # Related but doesn't close
See #789            # Reference only
```

**Breaking changes:**

```
BREAKING CHANGE: Remove support for Ubuntu 22.04

Ubuntu 22.04 reaches EOL and will no longer receive security
updates. All deployments must upgrade to Ubuntu 24.04.

Migration guide: docs/MIGRATION.md
```

### 7.6 Atomic Commits

**One logical change per commit:**

```
# Good - Separate commits
git commit -m "feat: Add MySQL 9.0 support"
git commit -m "docs: Update MySQL version in ARCHITECTURE.md"
git commit -m "test: Add MySQL 9.0 to test matrix"

# Bad - Multiple unrelated changes
git commit -m "Add MySQL 9.0 and fix typo and update dependencies"
```

## 8. Code Review Standards

### 8.1 Review Checklist

Before approving a pull request, verify:

- [ ] Code follows all style guide rules
- [ ] Tests pass (syntax check, linting, deployment test)
- [ ] Documentation updated to reflect changes
- [ ] No hardcoded secrets or credentials
- [ ] Idempotency verified for Ansible tasks
- [ ] Commit messages follow standards
- [ ] No merge conflicts with main branch

### 8.2 Providing Feedback

**Be constructive and specific:**

```
# Good
"This task should use `ansible.builtin.template` instead of `ansible.builtin.copy` 
since the file contains Jinja2 variables. See line 45."

# Bad
"Wrong module."
```

**Suggest improvements, don't just criticize:**

```
# Good
"Consider adding a health check here to ensure the service is actually
running before proceeding. Example:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000"]
```
"

# Bad
"Missing health check."
```

### 8.3 Security Review

**Always check for:**

- Secrets in version control
- Unsafe file permissions
- Missing input validation
- Insecure default configurations
- Deprecated cryptography
- Unnecessary privilege escalation

## 9. Exceptions

### 9.1 When to Deviate

Style rules can be broken when:

1. **External compatibility required** - Third-party tools expect specific format
2. **Performance critical** - Proven performance impact (document justification)
3. **Technical limitation** - Tool/platform limitation prevents compliance

### 9.2 Documenting Exceptions

Use inline comments to explain deviations:

```yaml
# ansible-lint disable=package-latest
# We intentionally use :latest for Standard Notes to get security patches
# automatically. This is documented in ARCHITECTURE.md section 3.1.
- name: Pull latest Standard Notes image
  community.docker.docker_image:
    name: standardnotes/server
    tag: latest
    source: pull
```

```bash
# shellcheck disable=SC2046
# We intentionally use word splitting here to pass multiple files
rm $(find /tmp -name "*.log" -mtime +7)
```

---

> [!IMPORTANT]
> Consistency is more important than individual preferences. Follow the project style even if you disagree with specific choices.

**Questions about style?** Open a GitHub Discussion for clarification or propose changes via pull request.

# Contributing to Standard Notes IaC

Thank you for your interest in contributing to this project! This Infrastructure-as-Code (IaC) solution helps people deploy self-hosted Standard Notes instances with security and operational best practices built in.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Documentation Standards](#documentation-standards)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Security Vulnerabilities](#security-vulnerabilities)
- [Community](#community)

## Code of Conduct

This project follows the principles of respectful, inclusive collaboration:

- **Be respectful:** Treat all contributors with respect and professionalism
- **Be constructive:** Provide helpful feedback focused on improvement
- **Be inclusive:** Welcome contributors of all skill levels and backgrounds
- **Be collaborative:** Work together toward shared goals
- **Be patient:** Remember that everyone is learning and improving

Unacceptable behavior includes harassment, discrimination, personal attacks, or other conduct that creates a hostile environment.

## How Can I Contribute?

### Reporting Bugs

Found a bug? Help us fix it:

1. **Check existing issues** - Search [GitHub Issues](https://github.com/yourusername/standard-notes-iac/issues) to avoid duplicates
2. **Create detailed bug report** - Use the bug report template
3. **Include reproduction steps** - Tell us exactly how to reproduce the issue
4. **Provide context** - Include OS, Ansible version, error messages, logs

**What makes a good bug report:**

- Clear, descriptive title
- Steps to reproduce (numbered list)
- Expected behavior vs actual behavior
- Environment details (Ubuntu version, VPS provider, etc.)
- Relevant logs or error messages (use code blocks)
- Screenshots if applicable

### Suggesting Enhancements

Have an idea for improvement?

1. **Check existing issues and PRs** - Your idea may already be proposed
2. **Open a discussion** - Use GitHub Discussions for feature ideas
3. **Explain the use case** - Why is this enhancement valuable?
4. **Consider scope** - Does this align with project goals? (See [PRD.md](docs/PRD.md))

**Enhancement proposal should include:**

- Problem statement (what pain point does this solve?)
- Proposed solution
- Alternative approaches considered
- Implementation complexity estimate (simple/moderate/complex)
- Breaking changes (if any)

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear wording
- Add missing examples or clarifications
- Improve diagrams or visual aids
- Add troubleshooting tips from your experience
- Translate documentation (future)

Documentation contributions follow the same pull request process as code changes.

### Writing Code

Code contributions should:

- Solve a real problem or add valuable functionality
- Follow project standards (see [STYLE_GUIDE.md](STYLE_GUIDE.md))
- Include tests where applicable
- Update documentation to reflect changes
- Not introduce breaking changes without discussion

## Getting Started

### Prerequisites

To contribute, you need:

- **Git** - Version control
- **GitHub account** - For pull requests
- **Text editor** - VS Code recommended (with Ansible extension)
- **Ansible 2.14+** - For testing playbooks locally
- **Test environment** - Ubuntu 24.04 VM or VPS for testing

Optional but helpful:

- **Docker** - For local container testing
- **Vagrant** - For reproducible test environments
- **ShellCheck** - For shell script linting

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/yourusername/standard-notes-iac.git
   cd standard-notes-iac
   ```
3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/originalowner/standard-notes-iac.git
   ```
4. **Verify remotes:**
   ```bash
   git remote -v
   # origin    https://github.com/yourusername/standard-notes-iac.git (fetch)
   # origin    https://github.com/yourusername/standard-notes-iac.git (push)
   # upstream  https://github.com/originalowner/standard-notes-iac.git (fetch)
   # upstream  https://github.com/originalowner/standard-notes-iac.git (push)
   ```

### Development Setup

1. **Install Ansible:**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ansible
   
   # macOS
   brew install ansible
   
   # Via pip
   pip install ansible
   ```

2. **Install Ansible collections:**
   ```bash
   ansible-galaxy collection install community.general
   ansible-galaxy collection install community.docker
   ansible-galaxy collection install ansible.posix
   ```

3. **Install development tools:**
   ```bash
   # ansible-lint for playbook linting
   pip install ansible-lint
   
   # yamllint for YAML validation
   pip install yamllint
   
   # ShellCheck for shell scripts
   sudo apt install shellcheck  # Ubuntu
   brew install shellcheck      # macOS
   ```

4. **Set up test environment:**
   - Create Ubuntu 24.04 VM (VirtualBox, VMware, or cloud VPS)
   - Configure SSH access
   - Add to local inventory for testing

## Development Workflow

### Branch Strategy

- **main** - Production-ready code, protected branch
- **feature/\*** - Feature branches (e.g., `feature/add-monitoring`)
- **fix/\*** - Bug fix branches (e.g., `fix/firewall-rules`)
- **docs/\*** - Documentation-only changes (e.g., `docs/improve-quickstart`)

### Making Changes

1. **Sync with upstream:**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes:**
   - Edit code following [STYLE_GUIDE.md](STYLE_GUIDE.md)
   - Test changes in test environment
   - Update documentation if needed
   - Add/update tests

4. **Commit changes:**
   ```bash
   git add .
   git commit -m "Add feature: brief description
   
   Longer explanation of what changed and why. Reference any
   related issues (e.g., Fixes #123, Relates to #456).
   
   - Specific change 1
   - Specific change 2"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Guidelines

Good commit messages help reviewers and future maintainers understand changes.

**Format:**

```
<type>: <short summary> (max 50 chars)

<optional longer description explaining WHY, not WHAT>

<optional footer with issue references>
```

**Types:**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style/formatting (no logic change)
- `refactor:` - Code refactoring (no behavior change)
- `test:` - Adding/updating tests
- `chore:` - Maintenance tasks, dependency updates

**Examples:**

```
feat: Add Fail2Ban jail for Standard Notes

Adds custom Fail2Ban filter to detect and block repeated failed
login attempts to Standard Notes application. Reduces risk of
brute force attacks.

Fixes #42
```

```
fix: Correct UFW rule ordering for Docker

Docker manipulates iptables directly, bypassing UFW rules added
after Docker starts. This fix ensures UFW rules are applied in
correct order relative to Docker chains.

Relates to #38
```

```
docs: Add troubleshooting section for TLS issues

Common problem users encounter is TLS certificate not issuing
due to DNS not propagated. Added troubleshooting steps and
verification commands.
```

## Documentation Standards

All documentation changes must follow the standards in [STYLE_GUIDE.md](STYLE_GUIDE.md).

### Key Requirements

- **Real markdown headers** - Use `##`, `###`, not bold text
- **Explanatory text** - Every section header needs descriptive text before subsections/lists
- **Blank lines** - All markdown elements need blank lines above and below
- **GitHub admonitions** - Use `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`
- **Code comments** - Explain WHY, not WHAT
- **Single source of truth** - Each factual detail must live in one canonical document. Other docs should summarize and link back to that source.

### Documentation Structure

When adding new documentation:

1. **Add navigation breadcrumb** - Include doc navigation at top
2. **Clear section hierarchy** - Logical flow from high-level to details
3. **Cross-reference related docs** - Link to ARCHITECTURE.md, SECURITY_DESIGN.md, etc.
4. **Include examples** - Show, don't just tell
5. **Update table of contents** - If document has TOC

## Code Standards

### Ansible Playbooks and Roles

Follow these conventions for Ansible code:

**File naming:**
- Playbooks: `kebab-case.yml` (e.g., `deploy-standard-notes.yml`)
- Roles: `kebab-case` directories (e.g., `roles/ssh-hardening/`)
- Variables: `snake_case` (e.g., `mysql_root_password`)

**YAML formatting:**
- 2-space indentation (no tabs)
- No trailing whitespace
- Use `ansible-lint` to validate

**Task structure:**
```yaml
- name: Clear, descriptive task name in present tense
  ansible.builtin.apt:
    name: package-name
    state: present
    update_cache: true
  become: true
  tags:
    - packages
```

**Best practices:**
- Always use FQCN (Fully Qualified Collection Names): `ansible.builtin.apt`, not just `apt`
- Add `name:` to every task (required for readability)
- Use `become:` explicitly when privilege escalation needed
- Add tags for selective execution
- Use variables for values that might change
- Never hardcode secrets - always use variables

### Shell Scripts

**Formatting:**
```bash
#!/bin/bash
# Script description

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Constants in UPPER_CASE
BACKUP_DIR="/var/backups/standard-notes"
RETENTION_DAYS="${1:-30}"

# Functions use snake_case
create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    
    # Implementation
}

# Main script logic
main() {
    create_backup
}

main "$@"
```

**Best practices:**
- Use `shellcheck` to validate all scripts
- Always set `set -euo pipefail` for safety
- Quote all variables: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Add comments explaining WHY, not WHAT
- Make scripts idempotent where possible

### Docker Compose

**Formatting:**
```yaml
services:
  servicename:
    image: image:tag
    container_name: container-name
    restart: unless-stopped
    environment:
      ENV_VAR: value
    volumes:
      - /host/path:/container/path
    networks:
      - network-name
    healthcheck:
      test: ["CMD", "command"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

**Best practices:**
- Always include health checks
- Use explicit container names
- Set restart policies
- Use named networks (not default bridge)
- Bind mounts for application data (per project architecture)
- Pin image versions for production (`:latest` for testing acceptable)

## Testing Requirements

### What Needs Testing

**Required tests before submitting PR:**

1. **Ansible playbook syntax validation:**
   ```bash
   ansible-playbook --syntax-check src/site.yml
   ```

2. **Ansible linting:**
   ```bash
   ansible-lint src/
   ```

3. **Full deployment test:**
   - Deploy to fresh Ubuntu 24.04 VM
   - Verify all containers start healthy
   - Verify HTTPS access works
   - Verify backup script executes successfully

4. **Idempotency test:**
   ```bash
   # Run playbook twice, second run should show 0 changes
   ansible-playbook -i inventory src/site.yml
   ansible-playbook -i inventory src/site.yml
   # Second run should show: ok=X changed=0 ...
   ```

5. **ShellCheck validation:**
   ```bash
   shellcheck src/scripts/*.sh
   ```

### Test Environment Setup

Create reproducible test environment:

**Option 1: Vagrant (recommended for local testing)**

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/noble64"  # Ubuntu 24.04
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end
end
```

**Option 2: Cloud VPS**

Use cheap VPS for testing (destroy after testing to minimize cost):
- DigitalOcean droplet ($6/month, destroy after testing)
- Linode Nanode ($5/month)
- Vultr Cloud Compute ($2.50-$5/month)

### Documenting Test Results

Include test results in PR description:

```markdown
## Test Results

**Environment:**
- OS: Ubuntu 24.04.1 LTS
- Ansible: 2.14.2
- Test method: Vagrant VM

**Tests performed:**
- [x] Syntax validation passed
- [x] ansible-lint passed (0 errors)
- [x] Full deployment successful
- [x] Idempotency verified (changed=0 on second run)
- [x] All containers healthy
- [x] HTTPS access verified
- [x] Backup script tested

**Notable observations:**
- Deployment took 8m 32s
- No warnings or errors in logs
```

## Pull Request Process

### Before Submitting PR

- [ ] Code follows [STYLE_GUIDE.md](STYLE_GUIDE.md)
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Commit messages follow guidelines
- [ ] Branch is up to date with upstream main
- [ ] No merge conflicts

### Creating Pull Request

1. **Push changes to your fork**
2. **Open PR on GitHub** against `main` branch
3. **Fill out PR template** (if provided)
4. **Provide clear description:**
   - What problem does this solve?
   - What changes were made?
   - How was it tested?
   - Any breaking changes?
   - Related issues?

### PR Title Format

```
<type>: <clear description>

Examples:
feat: Add support for MySQL 9.0
fix: Correct Traefik health check configuration
docs: Improve backup restore procedure documentation
```

### Review Process

**What to expect:**

1. **Automated checks** - GitHub Actions runs linting and validation
2. **Maintainer review** - A maintainer reviews code and tests
3. **Feedback** - You may receive change requests
4. **Iteration** - Make requested changes and push to same branch
5. **Approval** - Once approved, maintainer will merge

**Review timeframe:**
- Simple fixes/docs: Usually within 1-3 days
- Features/complex changes: May take 1-2 weeks
- Large architectural changes: May require extended discussion

### After PR is Merged

1. **Delete your branch** (GitHub offers this option)
2. **Sync your fork with upstream:**
   ```bash
   git checkout main
   git fetch upstream
   git merge upstream/main
   git push origin main
   ```
3. **Celebrate!** 🎉 You've contributed to open source!

## Security Vulnerabilities

**Do NOT open public issues for security vulnerabilities.**

Please report security vulnerabilities using GitHub's security advisory feature:

**[Report a vulnerability](https://github.com/robertsinfosec/standard-notes-iac/security/advisories/new)**

For complete security policy and reporting guidelines, see [SECURITY.md](SECURITY.md).

## Community

### Communication Channels

- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - Questions, ideas, general discussion
- **Pull Requests** - Code contributions and review

### Getting Help

- **Documentation** - Check [QUICKSTART.md](QUICKSTART.md), [ARCHITECTURE.md](docs/ARCHITECTURE.md), [OPERATIONS.md](docs/OPERATIONS.md)
- **Search issues** - Your question may already be answered
- **Ask in Discussions** - For questions not covered in docs
- **Be specific** - Include error messages, logs, environment details

### Recognition

Contributors are recognized in several ways:

- **CONTRIBUTORS.md** - All contributors listed (auto-generated from Git history)
- **Release notes** - Significant contributions highlighted
- **GitHub contributors graph** - Visible on repository

## Questions?

- **General questions:** GitHub Discussions
- **Bug reports:** GitHub Issues
- **Security issues:** See [SECURITY.md](SECURITY.md)
- **Pull request questions:** Comment on the PR

---

**Thank you for contributing!** Every contribution, no matter how small, helps make this project better for everyone. 🙏

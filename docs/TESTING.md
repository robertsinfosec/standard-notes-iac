> **Documentation:** [Quick Start](../QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Security Design](SECURITY_DESIGN.md) | [Operations](OPERATIONS.md) | **Testing** | [PRD](PRD.md)

---

# Testing Guide: Ansible Playbooks and Roles

This document defines how to test Ansible playbooks and roles for the Standard Notes IaC project. The goal is predictable, repeatable validation without relying on manual inspection.

## 1. Testing Principles

Testing focuses on correctness, idempotency, and safety for production environments.

### 1.1 Requirements

All changes must meet these requirements:

- Idempotent execution with no unexpected changes on re-run.

- No hardcoded secrets or environment-specific values.

- Consistent behavior across supported environments.

- Clear and actionable failure output.

### 1.2 Scope

This guide covers tests for:

- Ansible playbooks and roles in src/.

- Supporting YAML files.

- Shell scripts that accompany Ansible automation.

It does not cover application-level tests inside Standard Notes itself.

## 2. Tooling

These tools are required for local validation and CI.

### 2.1 Required Tools

- Ansible 2.14+.

- ansible-lint.

- yamllint.

- ShellCheck.

### 2.2 Recommended Tools

- jq for structured log filtering.

- Docker Engine for container-level verification in a test VPS.

## 3. Test Types

This project uses multiple test types to catch different classes of problems.

### 3.1 Linting

Linting enforces conventions and catches structural issues early.

Run these checks from the repository root:

```bash
ansible-lint src/site.yml

yamllint src/

shellcheck src/scripts/*.sh
```

### 3.2 Syntax Validation

Syntax checks detect parsing issues before any remote execution.

```bash
ansible-playbook --syntax-check -i src/inventory src/site.yml
```

### 3.3 Dry Run (Check Mode)

Dry run verifies planned changes without mutating the target system.

```bash
ansible-playbook --check -i src/inventory src/site.yml
```

> [!IMPORTANT]
> Check mode is not a complete substitute for a real run. Some modules cannot fully simulate changes.

### 3.4 Idempotency Verification

Idempotency is validated by running the playbook twice in a row on a fresh system and confirming that the second run reports no changes.

```bash
ansible-playbook -i src/inventory src/site.yml

ansible-playbook -i src/inventory src/site.yml
```

Expected result on the second run:

- No failed tasks.

- No unexpected changed tasks.

### 3.5 Integration Smoke Test

Smoke testing validates that the full stack starts and responds after deployment.

Minimum verification steps on the VPS:

- Check systemd service status.

- Confirm Docker containers are healthy.

- Verify HTTPS endpoints return expected responses.

Example commands:

```bash
sudo systemctl status standard-notes

docker compose ps

docker compose logs --tail=50
```

### 3.6 Backup and Restore Verification

Backup scripts and restore steps must be tested on a non-production system before release.

Required checks:

- Backup creation completes without errors.

- Backup archive contains database dump, uploads, and acme.json. Secrets are restored separately from a password manager or secrets vault.

- Restore procedure successfully brings the service back online.

## 4. Test Environments

Testing must be performed on environments that match production assumptions.

### 4.1 Supported Test Target

- Ubuntu 24.04 LTS (fresh install).

- Public IPv4 or valid SSH-accessible host.

- DNS records configured for the test domain.

### 4.2 Inventory Hygiene

Use a dedicated test inventory and avoid production values.

```ini
[standardnotes]
VPS_HOST ansible_user=service-deployer ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

Replace VPS_HOST with your test host.

## 5. CI Expectations

CI must enforce all non-destructive checks and block merges on failure.

### 5.1 Required CI Checks

- ansible-lint.

- yamllint.

- ShellCheck.

- Ansible syntax check.

### 5.2 Optional CI Checks

- Check mode against a disposable test host.

- Idempotency run on a disposable test host.

## 6. Test Reporting

Test results must be captured in CI logs and summarized in pull requests.

Minimum report items:

- Lint results.

- Syntax check results.

- Any deviations from expected idempotency behavior.

## 7. Release Gate

A change is release-eligible only when:

- All required CI checks pass.

- Idempotency is confirmed on a fresh target.

- Integration smoke test succeeds.

- Backup and restore verification completes on a non-production target.

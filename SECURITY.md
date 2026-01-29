# Security Policy

## Supported Versions

This project is currently in early development. Security updates will be provided for:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

Once version 1.0 is released, we will maintain security updates for the latest stable release.

## Reporting a Vulnerability

**Do NOT open public issues for security vulnerabilities.**

Public disclosure of security issues puts all users at risk. We practice responsible coordinated disclosure.

### How to Report

Please report security vulnerabilities privately using one of these methods:

**Option 1: GitHub Security Advisories (Preferred)**

[Report a vulnerability](https://github.com/robertsinfosec/standard-notes-iac/security/advisories/new)

**Option 2: Email**

Send details to: **security@bitsynotes.com**

### What to Include

When reporting a vulnerability, please include:

- **Description** - Clear description of the vulnerability
- **Impact** - What could an attacker do with this vulnerability?
- **Affected versions** - Which versions are affected?
- **Reproduction steps** - Detailed steps to reproduce the issue
- **Proof of concept** - Code or configuration demonstrating the issue (if applicable)
- **Suggested fix** - Proposed remediation (if you have one)

### Response Timeline

We take security seriously and will respond promptly:

- **Acknowledgment** - Within 48 hours of report
- **Initial assessment** - Within 1 week
- **Fix timeline** - Depends on severity:
  - Critical vulnerabilities: Days
  - High severity: 1-2 weeks
  - Medium/Low severity: 2-4 weeks

### Disclosure Policy

We follow coordinated disclosure practices:

1. **Private fix** - Security fix developed privately
2. **User notification** - Advance notice to users via security advisory
3. **Public release** - Fix released publicly with CVE (if applicable)
4. **Public disclosure** - Vulnerability details disclosed after fix is widely available

We request that reporters:
- Allow reasonable time for fixes before public disclosure
- Avoid exploiting the vulnerability beyond proof-of-concept
- Keep vulnerability details confidential until coordinated disclosure

### Security Best Practices

While using this project, follow these security practices:

- **Keep updated** - Run the latest version
- **Strong secrets** - Use cryptographically secure random secrets
- **Monitor logs** - Watch for suspicious activity
- **Regular backups** - Maintain tested backups
- **Review changes** - Understand what you're deploying

### Scope

**In scope for security reports:**

- Authentication bypass
- Authorization flaws
- Secrets leakage (hardcoded credentials, etc.)
- Command injection vulnerabilities
- Privilege escalation
- Deployment of malicious code
- Infrastructure misconfigurations creating vulnerabilities

**Out of scope:**

- Vulnerabilities in upstream dependencies (report to upstream projects)
- Social engineering attacks
- Physical security
- Denial of Service (DoS) attacks on public infrastructure

### Hall of Fame

Security researchers who responsibly disclose vulnerabilities will be acknowledged here (with their permission):

- *None yet - be the first!*

---

Thank you for helping keep this project and its users safe! 🔒

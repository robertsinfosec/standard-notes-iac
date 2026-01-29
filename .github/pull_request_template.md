## Pull Request Checklist

Thank you for contributing! Please ensure your PR meets these requirements before submitting.

### Pre-Submission Checklist

- [ ] I have read [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] My code follows the [STYLE_GUIDE.md](../STYLE_GUIDE.md)
- [ ] I have tested my changes in a real environment
- [ ] Documentation has been updated to reflect changes
- [ ] Commit messages follow conventional commit format
- [ ] No merge conflicts with main branch

### Type of Change

Please check the type of change your PR introduces:

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring (no functional changes)
- [ ] Security improvement
- [ ] Performance improvement

### Description

**What problem does this PR solve?**

<!-- Clearly describe the problem or feature request this addresses -->

**What changes were made?**

<!-- Summarize the changes made in this PR -->

**How was it tested?**

<!-- Describe your testing process -->

### Related Issues

Closes #<!-- issue number -->
Relates to #<!-- issue number -->

### Test Results

**Environment:**
- OS: <!-- e.g., Ubuntu 24.04 LTS -->
- Ansible version: <!-- e.g., 2.14.2 -->
- Test method: <!-- e.g., Vagrant VM, Cloud VPS -->

**Tests performed:**
- [ ] Syntax validation (`ansible-playbook --syntax-check`)
- [ ] Linting (`ansible-lint`)
- [ ] Full deployment test
- [ ] Idempotency verified (changed=0 on second run)
- [ ] All containers healthy
- [ ] HTTPS access verified
- [ ] ShellCheck passed (if shell scripts modified)

**Test output:**

```
<!-- Paste relevant test output here -->
```

### Screenshots (if applicable)

<!-- Add screenshots to help explain your changes -->

### Breaking Changes

**Does this PR introduce breaking changes?**

- [ ] Yes
- [ ] No

If yes, describe the breaking changes and migration path:

<!-- Explain what breaks and how users should migrate -->

### Security Considerations

**Does this PR have security implications?**

- [ ] Yes
- [ ] No

If yes, describe security considerations:

<!-- Explain security impact, new attack surface, mitigations, etc. -->

### Additional Notes

<!-- Any additional information reviewers should know -->

---

## For Reviewers

### Review Checklist

- [ ] Code follows project style guide
- [ ] Documentation is clear and accurate
- [ ] Tests are sufficient and passing
- [ ] No security issues introduced
- [ ] No hardcoded secrets or credentials
- [ ] Changes are well-scoped and focused
- [ ] Commit messages are clear and conventional

### Reviewer Notes

<!-- Reviewer comments go here -->

# Contributing to Shark OS

Cảm ơn bạn quan tâm đến việc đóng góp cho Shark OS! 🦈

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/Shark-OS.git`
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Development Setup

```bash
# Clone repository
git clone https://github.com/Seread335/Shark-OS.git
cd Shark-OS

# Setup build environment
bash scripts/setup-build-env.sh

# Create feature branch
git checkout -b feature/your-feature
```

## Code Style

### Shell Scripts
```bash
#!/bin/bash
set -e

# Use meaningful variable names
readonly MY_CONSTANT="value"
local my_variable="value"

# Error handling
if ! command -v something &>/dev/null; then
    log_error "Required tool not found"
    exit 1
fi

# Comment complex logic
# Brief description of what this does
code_here
```

### APKBUILD Packages
```bash
# Follow Alpine Linux conventions
# Use lowercase package names
# Pin versions explicitly
# Include proper checksums
```

## Testing

Before submitting a PR:

```bash
# Validate shell scripts
for f in $(find . -name "*.sh"); do
    bash -n "$f" || exit 1
done

# Build test
bash scripts/setup-build-env.sh
bash build.sh

# Check output
ls -lh dist/
```

## Pull Request Process

1. **Title**: Be descriptive (e.g., "Add eBPF monitoring support")
2. **Description**: Explain what and why
3. **Changes**: List files modified
4. **Testing**: How did you test?
5. **Screenshots/Logs**: If applicable

### Template

```markdown
## Description
Brief description of changes

## Related Issues
Fixes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement
- [ ] Security improvement

## Testing
How to test these changes

## Checklist
- [ ] Code compiles
- [ ] No new warnings
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Commits are well-structured
```

## Commit Guidelines

Use conventional commits:

```bash
# Format: <type>(<scope>): <subject>

# Examples:
git commit -m "feat(kernel): add PREEMPT_RT support"
git commit -m "fix(cli): resolve partition switcher issue"
git commit -m "docs: update installation guide"
git commit -m "test: add A/B partitioning tests"
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Code style (no logic change)
- `refactor` - Refactoring
- `test` - Tests
- `chore` - Build, dependencies, etc.

## Areas for Contribution

### Priority Areas

**Tier 1: Base OS**
- Kernel optimization
- Security hardening
- AppArmor profiles
- Read-only rootfs improvements

**Tier 2: Container Platform**
- K3s integration
- Cilium networking
- Container security
- Storage solutions

**Tier 3: Enterprise Add-ons**
- Monitoring (Prometheus/Grafana)
- Logging (Loki)
- Service Mesh (Istio)
- Runtime Security (Falco)

### Documentation
- Installation guides
- Configuration examples
- Troubleshooting
- API documentation
- Tutorial and walkthroughs

### Quality
- Bug fixes
- Performance improvements
- Security improvements
- Testing

## Reporting Issues

### For Bugs
1. Check if issue already exists
2. Use bug report template
3. Include environment details
4. Provide reproduction steps
5. Attach logs if possible

### For Features
1. Use feature request template
2. Explain use case
3. Describe solution
4. Indicate impact (Tier 1/2/3)

## Code Review

- Reviews by maintainers
- May request changes
- Respectful, constructive feedback
- Approval before merge

## Licensing

By contributing, you agree:
- Code is licensed under GPL v3.0
- You have rights to code
- No external licenses conflict

## Code of Conduct

### Our Pledge
Be respectful, inclusive, and constructive.

### Expected Behavior
- Be professional and kind
- Give credit to others
- Welcome different perspectives
- Report issues responsibly

### Unacceptable Behavior
- Harassment or discrimination
- Disrespectful language
- Spam or promotional content
- Violations of privacy

## Questions?

- GitHub Issues: [Bug reports & features](https://github.com/Seread335/Shark-OS/issues)
- Discussions: [General questions](https://github.com/Seread335/Shark-OS/discussions)
- Wiki: [Documentation](https://github.com/Seread335/Shark-OS/wiki)

---

**Thank you for contributing to Shark OS! 🦈**

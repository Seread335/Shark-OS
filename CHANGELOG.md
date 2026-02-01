# Changelog

Tất cả các thay đổi đáng chú ý của dự án này được ghi lại trong file này.

## [0.1.0-alpha] - 2024-01-31

### Added
- **Initial Release**
  - Alpine Linux-based OS kernel
  - Base system with musl libc + gcompat
  - OpenRC init system
  - AppArmor security framework
  - Podman container runtime support
  - K3s Kubernetes integration
  - Cilium eBPF-based networking
  - A/B partitioning scheme for immutable updates
  - Shark CLI management tool
  - Build system (abuild + mkimage)
  - GitHub Actions CI/CD pipeline

- **Features**
  - Read-only rootfs in production mode
  - Custom kernel with eBPF and cgroup v2
  - Prometheus Node Exporter integration
  - Cloud-init support
  - ZFS and LVM support
  - WireGuard kernel module
  - DPDK-ready configuration

- **Tools & Scripts**
  - mkimage/mkimg.shark.sh - ISO image builder
  - scripts/setup-build-env.sh - Build environment setup
  - scripts/ab-partition-setup.sh - Partition configuration
  - shark-cli/shark - System management tool
  - .github/workflows/build.yml - CI/CD automation

- **Documentation**
  - README.md - Project overview
  - docs/build-guide.md - Build instructions
  - docs/installation.md - Installation guide
  - CONTRIBUTING.md - Contribution guidelines
  - LICENSE - GPL v3.0

### Changed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Removed
- N/A (initial release)

### Security
- Initial AppArmor profiles for core services
- Read-only root filesystem architecture
- Kernel hardening options enabled
- Secure boot considerations documented

### Known Issues
- A/B update mechanism is in alpha (testing phase)
- Some systemd compatibility shims still in development
- Enterprise tier packages need testing with full workloads
- Documentation for advanced K8s/Istio integration pending

## [0.2.0] - Planned

### Planned Features
- [ ] Automated update mechanism (full A/B rollback)
- [ ] Corosync/Pacemaker HA cluster support
- [ ] Istio service mesh integration
- [ ] HashiCorp Vault integration
- [ ] Falco runtime security monitoring
- [ ] Loki distributed logging
- [ ] Advanced networking (DPDK optimization)
- [ ] Performance tuning (PREEMPT_RT option)
- [ ] ARM64/ARMv7 architecture support
- [ ] Cloud provider specific drivers (AWS, GCP, Azure)

### Documentation
- [ ] Architecture decision records (ADRs)
- [ ] Performance tuning guides
- [ ] Security hardening guide
- [ ] Cluster setup guide
- [ ] Migration guide from other distros

### Testing
- [ ] Unit tests for Shark CLI
- [ ] Integration tests for container runtime
- [ ] A/B partitioning tests
- [ ] Kubernetes cluster tests

## [1.0.0] - Production Ready

### Goals
- Stable, production-ready release
- Full enterprise feature support
- Comprehensive documentation
- Community-driven improvements
- Long-term support commitment

---

## Version Format

This project uses [Semantic Versioning](https://semver.org/):
- MAJOR version for incompatible API changes
- MINOR version for backwards-compatible functionality additions
- PATCH version for backwards-compatible bug fixes

Additional labels:
- `-alpha` for early development versions
- `-beta` for feature-complete testing versions
- No suffix for stable releases

## Support Timeline

| Version | Release | End of Support |
|---------|---------|----------------|
| 0.1.x | 2024-01 | 2024-06 |
| 0.2.x | 2024-03 | 2024-09 |
| 1.0.x | 2024-06 | 2026-06 |

## Contributing

Want to contribute to Shark OS?
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Feedback

- Report bugs: https://github.com/Seread335/Shark-OS/issues
- Feature requests: https://github.com/Seread335/Shark-OS/issues
- Discussions: https://github.com/Seread335/Shark-OS/discussions

# Alpine Ports Repository

Tập hợp các package tùy chỉnh cho Shark OS.

## Cấu trúc

- **core/** - Core packages cho Shark OS
- **community/** - Community packages
- **shark-main/** - Shark OS specific packages (kernel, base, cli)

## Building Packages

```bash
cd shark-main/
abuild -r
```

## Package Descriptions

### shark-linux
Custom Linux kernel với:
- eBPF support (CONFIG_DEBUG_INFO_BTF)
- cgroup v2
- PREEMPT_RT (optional)
- DPDK modules

### shark-base
Base system packages:
- OpenRC init
- musl libc + gcompat
- System tools
- AppArmor

### shark-cli
Management tool:
- System control
- Container management
- K8s integration
- Configuration management

## References

- [Alpine Packaging](https://wiki.alpinelinux.org/wiki/Creating_an_alpine_package)
- [APKBUILD Format](https://git.alpinelinux.org/cgit/abuild/tree/APKBUILD.in)

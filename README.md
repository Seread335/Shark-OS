# Shark OS - Hệ Điều Hành Chuyên Biệt cho Cloud & Edge

Shark OS là một hệ điều hành server-oriented được xây dựng trên nền tảng Alpine Linux, tối ưu cho containerization, microservices và edge computing.

## 🎯 Đặc điểm Chính

- **Nhẹ và Nhanh**: Image cơ bản dưới 50MB, boot dưới 5 giây
- **Bảo mật**: Rootfs read-only, AppArmor, eBPF integration
- **Hiệu suất**: Tối ưu kernel, eBPF, DPDK support
- **Mở rộng**: K3s/Kubernetes native, Cilium CNI
- **Bất biến**: A/B partitioning cho cập nhật an toàn

## 📋 Cấu trúc Dự án

```
Shark OS/
├── aports/                    # Alpine Port Repos
│   ├── core/                 # Core packages
│   ├── community/            # Community packages
│   └── shark-main/           # Shark OS specific
├── mkimage/                  # Image building
│   └── mkimg.shark.sh       # Shark profile
├── shark-cli/                # CLI tool
├── scripts/                  # Utility scripts
├── overlays/                 # System overlays
│   └── base/                # Base OS overlay
├── .github/workflows/        # CI/CD
├── docs/                     # Documentation
└── tests/                    # Testing
```

## 🚀 Quick Start

### Yêu cầu
- Alpine Linux build environment
- Docker/Podman
- abuild, mkimage
- Git

### Build Shark OS Image

```bash
# 1. Setup build environment
cd scripts
./setup-build-env.sh

# 2. Build kernel
cd ../aports/shark-main
abuild -r

# 3. Create ISO
cd ../../mkimage
./mkimg.shark.sh

# 4. Output: dist/shark-os-latest.iso
```

## 📦 Hệ thống Phân lớp (Tiering System)

### Tier 1: Base OS (Core)
- Kernel tối ưu (eBPF, cgroup v2)
- musl libc + gcompat
- OpenRC init system
- Podman/Buildah container runtime
- Prometheus Node Exporter

### Tier 2: Container Platform
- K3s (mặc định) / Kubernetes
- Cilium CNI
- ZFS/LVM support
- Cloud-init

### Tier 3: Enterprise Add-ons
- Corosync/Pacemaker (HA)
- Istio (Service Mesh)
- HashiCorp Vault
- Falco (Runtime Security)
- Loki Agent

## 🔐 Bảo mật

- **MAC**: AppArmor profiles
- **Kernel Hardening**: CONFIG_FORTIFY_SOURCE, ROP/JOP protection
- **Read-Only Rootfs**: /var phân vùng riêng
- **Automatic Updates**: cron + A/B partitioning

## 🔄 Cơ chế Cập nhật (A/B Partitioning)

```
Disk Layout:
├── Boot (Fat32)         → GRUB/systemd-boot
├── Root A (ext4, RO)   → Active OS
├── Root B (ext4, RO)   → Backup OS
└── Data (ext4, RW)      → /var/lib/shark (logs, configs)

Update Flow:
1. Apply update → Root B
2. Set boot flag → Root B
3. Reboot
4. If fail → Auto-rollback to Root A
```

## 🛠️ Công cụ Chính

| Công cụ | Mục đích | Phiên bản |
|---------|---------|----------|
| abuild | Alpine build tool | - |
| mkimage | ISO image creator | - |
| Shark CLI | OS management | v0.1.0 |
| apk | Package manager | - |
| OpenRC | Init system | - |
| Podman | Container runtime | v4.0+ |
| K3s | Kubernetes (light) | v1.27+ |

## 📚 Tài liệu

- [Thiết kế Kiến trúc](docs/architecture.md)
- [Hướng dẫn Build](docs/build-guide.md)
- [Cài đặt & Triển khai](docs/deployment-guide.md)
- [Shark CLI](docs/shark-cli.md)
- [AppArmor Profiles](docs/apparmor-profiles.md)

## 🔗 Tài liệu Tham khảo

- [Alpine Linux](https://alpinelinux.org/)
- [Linux Kernel - eBPF](https://kernel.org/)
- [Cilium](https://cilium.io/)
- [K3s](https://k3s.io/)
- [Podman](https://podman.io/)

## 📝 Giấy phép

GPL v3.0 - Open Source

## 👥 Đóng góp

Contributions welcome! Vui lòng xem [CONTRIBUTING.md](CONTRIBUTING.md)

## 📞 Liên hệ & Hỗ trợ

- Issues: GitHub Issues
- Wiki: GitHub Wiki
- Community: GitHub Discussions
- Enterprise Support: contact@sharkoq.io

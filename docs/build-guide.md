# Build Guide - Shark OS

Hướng dẫn xây dựng Shark OS từ mã nguồn.

## Yêu cầu

### Hệ thống
- **Alpine Linux** 3.18+ (hoặc Docker/Podman với Alpine image)
- **4GB+ RAM**
- **10GB+ disk space** cho build

### Công cụ
- `abuild` - Alpine build tool
- `mkimage` - ISO image builder
- `git` - Version control
- `make`, `gcc`, `musl-dev`

## Quick Start

### 1. Clone dự án

```bash
git clone https://github.com/Seread335/Shark-OS.git
cd Shark-OS
```

### 2. Setup build environment

```bash
# On Alpine Linux
bash scripts/setup-build-env.sh

# Or using Docker
docker run -it -v $(pwd):/shark \
  alpine:latest \
  /shark/scripts/setup-build-env.sh
```

### 3. Build Shark OS

```bash
# Build and create ISO
bash build.sh

# Or step-by-step:

# Build kernel
cd aports/shark-main
abuild -r

# Create ISO image
cd ../../mkimage
./mkimg.shark.sh

# Output: dist/shark-os-*.iso
```

## Build Steps Explained

### Step 1: Setup Build Environment

```bash
bash scripts/setup-build-env.sh
```

**Làm gì:**
- Cài đặt dependencies (abuild, alpine-sdk, etc.)
- Thiết lập abuild keys
- Tạo thư mục build

**Output:**
- `~/.abuild/` - abuild configuration
- `dist/` - Output directory

### Step 2: Build Custom Packages

```bash
cd aports/shark-main
abuild -r
```

**Thành phần được build:**

| Package | Mục đích |
|---------|---------|
| `shark-linux` | Custom kernel với eBPF, cgroup v2 |
| `shark-base` | Base system packages |
| `shark-cli` | System management tool |

**Output:**
- APK packages in `~/packages/`
- Logs in `build.log`

### Step 3: Create ISO Image

```bash
cd mkimage
./mkimg.shark.sh
```

**Quá trình:**
1. Tải packages từ Alpine repos
2. Xây dựng rootfs
3. Tạo overlays (config, security)
4. Đóng gói thành ISO

**Output:**
- `dist/shark-os-VERSION.iso`
- `dist/MANIFEST.txt`
- `dist/build.log`

## Build Configuration

### Shark Kernel Config

File: `aports/shark-main/config-shark-x86_64`

**Key options:**
```bash
CONFIG_eBPF=y                    # Enable eBPF
CONFIG_DEBUG_INFO_BTF=y          # BTF for eBPF
CONFIG_CGROUP_V2=y               # cgroup v2 support
CONFIG_OVERLAY_FS=y              # overlay filesystem
CONFIG_ZSWAP=y                   # Memory swap compression
```

### Packages

File: `mkimage/profile.sh`

**Tiers:**

**Tier 1: Base OS**
```
alpine-base, linux, ca-certificates, openssh,
curl, wget, apparmor, audit, supervisor
```

**Tier 2: Container Platform**
```
podman, buildah, k3s, cilium, kubeadm, kubectl
```

**Tier 3: Enterprise (optional)**
```
corosync, istio, vault, falco, loki
```

## Customization

### Add Custom Package

1. Tạo APKBUILD:
```bash
mkdir -p aports/shark-main/mypackage
cat > aports/shark-main/mypackage/APKBUILD << 'EOF'
pkgname=my-package
pkgver=1.0.0
pkgrel=0
pkgdesc="My custom package"
url="https://example.com"
arch="all"
makedepends="build-base"

build() {
    # Build commands
}

package() {
    # Install commands
}
EOF
```

2. Build:
```bash
cd aports/shark-main/mypackage
abuild -r
```

### Modify Kernel Config

```bash
# Edit config
vi aports/shark-main/config-shark-x86_64

# Then rebuild
cd aports/shark-main
abuild clean
abuild -r
```

### Custom Overlays

File: `scripts/create-overlay.sh`

Add system files:
```bash
mkdir -p overlays/base/etc
mkdir -p overlays/base/var/lib/shark

# Add your files
cp myconfig.yml overlays/base/etc/
cp -r mydata overlays/base/var/lib/shark/
```

## Troubleshooting

### Build fails with "Permission denied"

**Solução:**
```bash
# Make sure you're in Alpine Linux
# Or use Docker:
docker run -v $(pwd):/shark alpine:latest \
  sh -c "cd /shark && bash scripts/setup-build-env.sh && bash build.sh"
```

### Out of space

**Solution:**
```bash
# Clean build cache
abuild clean
rm -rf dist/*
```

### Signature verification failed

**Solution:**
```bash
# Regenerate keys
abuild-keygen -a -i -n
```

## CI/CD

### GitHub Actions

File: `.github/workflows/build.yml`

**Triggers:**
- Push to `main`, `develop`
- Pull requests
- Tag push (`v*`)

**Jobs:**
- Validate (lint, markdown)
- Build ISO
- Build CLI
- Build Docker image
- Security scanning

**Artifacts:**
- ISO image
- CLI binary
- Docker image (GHCR)

### Local Testing CI/CD

```bash
# Simulate GitHub Actions locally
docker run -it \
  -v $(pwd):/workspace \
  -w /workspace \
  alpine:latest \
  /bin/sh -c "bash scripts/setup-build-env.sh && bash build.sh"
```

## Performance Tips

### Speed up builds

```bash
# Use ccache
apk add ccache
export CC="ccache gcc"
export CXX="ccache g++"
```

### Parallel jobs

```bash
# Set in ~/.abuild/abuild.conf
JOBS=$(nproc)
MAKEFLAGS="-j${JOBS}"
```

### Cache packages

```bash
# Pre-download packages
apk cache download
```

## Size Optimization

### Check image size

```bash
ls -lh dist/shark-os-*.iso
```

### Reduce package dependencies

```bash
# Remove unnecessary packages from profile.sh
# Use --no-cache flag
apk add --no-cache <package>
```

### Enable compression

```bash
# In profile.sh
export COMPRESS=xz    # Better compression
# or
export COMPRESS=gzip  # Faster
```

## Next Steps

After building:

1. **Test image:**
   ```bash
   qemu-system-x86_64 -cdrom dist/shark-os-*.iso -m 2G
   ```

2. **Install on hardware:**
   - Write to USB: `dd if=dist/shark-os-*.iso of=/dev/sdX`
   - Boot and follow installation

3. **Deploy to cloud:**
   - Convert to cloud image format
   - Upload to AWS/GCP/Azure
   - Launch instances

## Resources

- [Alpine Linux](https://alpinelinux.org)
- [Alpine Packaging](https://wiki.alpinelinux.org/wiki/Creating_an_alpine_package)
- [abuild Documentation](https://git.alpinelinux.org/cgit/abuild/tree/)
- [Linux Kernel eBPF](https://ebpf.io/)

## Support

- GitHub Issues: [Seread335/Shark-OS/issues](https://github.com/Seread335/Shark-OS/issues)
- Wiki: [Shark OS Wiki](https://github.com/Seread335/Shark-OS/wiki)
- Community: GitHub Discussions

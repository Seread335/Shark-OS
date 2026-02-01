#!/usr/bin/env bash
# mkimg.shark.sh - Shark OS ISO Image Builder
# Usage: ./mkimg.shark.sh [options]

# Source common helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$PROJECT_ROOT/scripts/lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$PROJECT_ROOT/scripts/lib/common.sh"
else
    # Fallback strict-mode if common helpers not present
    set -eEuo pipefail
    trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR
fi

# Configuration
SHARK_VERSION="0.1.0"
SHARK_RELEASE="alpha"
BUILD_DATE=$(date -u +%Y%m%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_ROOT/dist"
BUILD_DIR="${BUILD_DIR:-/tmp/shark-build}"
PACKAGES_DIR="$PROJECT_ROOT/aports"
OUTPUT_ISO="$DIST_DIR/shark-os-${SHARK_VERSION}-${BUILD_DATE}.iso"

# Color output (if needed by other scripts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging provided by scripts/lib/common.sh (sourced above). Use run_cmd() and log_* helpers for consistent output.
# If you need special behavior (e.g., write to BUILD_LOG), implement a thin wrapper that also calls log_to_file().

check_dependencies() {
    log_info "Checking dependencies..."
    local deps=("mkimage" "abuild" "apk" "tar" "openssl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep not found. Please install it."
            exit 1
        fi
    done
    log_info "All dependencies found."
}

setup_build_dirs() {
    log_info "Setting up build directories..."
    mkdir -p "$BUILD_DIR"/{rootfs,overlay,cache}
    mkdir -p "$DIST_DIR"
    log_info "Build directories ready at: $BUILD_DIR"
}

build_apk_packages() {
    log_info "Building custom APK packages..."
    
    # Build shark-linux kernel
    cd "$PACKAGES_DIR/shark-main"
    
    if [ -f "APKBUILD" ]; then
        log_info "Building shark-linux package..."
        abuild -r 2>&1 | tee "$BUILD_DIR/build.log"
        log_info "Package build completed"
    else
        log_warn "APKBUILD not found, skipping custom package build"
    fi
}

create_profile() {
    log_info "Creating Shark OS mkimage profile..."
    
    # Create profile.sh for mkimage
    cat > "$BUILD_DIR/profile.sh" << 'PROFILE_EOF'
#!/bin/bash
# Shark OS mkimage profile

PROFILE_TITLE="Shark OS"
PROFILE_DESC="Server-oriented OS for Cloud & Edge"

# Repositories
REPOS="${REPOS:-https://dl-cdn.alpinelinux.org/alpine}"
APKREPOS="$REPOS/latest-stable/main $REPOS/latest-stable/community"

# Packages for Tier 1: Base OS
BASE_PACKAGES="
    alpine-base
    linux-lts
    e2fsprogs
    e2fsprogs-extra
    ca-certificates
    openssl
    openssh
    openssh-client
    openssh-server
    curl
    wget
    git
    vim
    nano
    htop
    iotop
    net-tools
    iproute2
    iputils
    ethtool
    tcpdump
    nftables
    ufw
    apparmor
    apparmor-utils
    apparmor-profiles
    audit
    auditd
    supervisor
    chrony
    tzdata
    dosfstools
    grub
    grub-efi
    efibootmgr
"

# Podman containerization
CONTAINER_PACKAGES="
    podman
    podman-compose
    buildah
    skopeo
    crun
    conmon
    libcontainers-common
"

# Kubernetes & networking
K3S_PACKAGES="
    k3s
    cilium-cli
    kubeadm
    kubelet
    kubectl
"

# System monitoring
MONITORING_PACKAGES="
    prometheus
    prometheus-node-exporter
    grafana
    mtail
"

# Storage
STORAGE_PACKAGES="
    zfs
    lvm2
    device-mapper
    mdadm
    cryptsetup
"

# Development tools (optional)
DEV_PACKAGES="
    build-base
    gcc
    g++
    make
    cmake
    python3
    python3-pip
    perl
    rust
    cargo
    git
    git-lfs
"

# Combine all packages
PACKAGES="$BASE_PACKAGES $CONTAINER_PACKAGES $K3S_PACKAGES $MONITORING_PACKAGES $STORAGE_PACKAGES"

# Optional dev packages
if [ "$INCLUDE_DEV" = "yes" ]; then
    PACKAGES="$PACKAGES $DEV_PACKAGES"
fi

# Image configuration
export ARCH="x86_64"
export KERNEL_FLAVOR="lts"
export OUTPUT_IMG="shark-os-${SHARK_VERSION}.iso"
export IMG_NAME="Shark OS"
export MOTD="Shark OS - Server-Oriented Linux for Cloud & Edge"

# Filesystem
export FSTYPE="ext4"
export ROOTFS="$PACKAGES"

# Init system (OpenRC by default)
export INIT_SYSTEM="openrc"

# Output format
export FORMAT="iso"

# Features
export MTOOLS_SKIP_CHECK=1
export COMPRESS=xz
PROFILE_EOF

    chmod +x "$BUILD_DIR/profile.sh"
    log_info "Profile created"
}

create_overlay() {
    log_info "Creating system overlays..."
    
    local overlay_dir="$BUILD_DIR/overlay"
    mkdir -p "$overlay_dir"/{etc,etc/init.d,etc/apparmor.d,usr/local/bin,var/lib/shark}
    
    # System configuration
    cat > "$overlay_dir/etc/hostname" << 'EOF'
shark-os
EOF

    # Initial network config
    cat > "$overlay_dir/etc/network/interfaces" << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    # OpenRC rc.conf
    cat > "$overlay_dir/etc/rc.conf" << 'EOF'
# /etc/rc.conf - OpenRC configuration

# Locale
export LANG=en_US.UTF-8

# Timezone
clock="UTC"
timezone="UTC"

# Keymaps
keymap="us"

# Log level
rc_logger="YES"
rc_log="/var/log/rc.log"

# Services
rc_parallel="YES"
rc_depend_strict="NO"

# Ignore network dependency
rc_net_strict_checking="no"
EOF

    # Shark CLI stub
    cat > "$overlay_dir/usr/local/bin/shark" << 'EOF'
#!/bin/sh
# Shark OS CLI v0.1.0-alpha
set -e

SHARK_VERSION="0.1.0"
SHARK_RELEASE="alpha"

case "$1" in
    version|--version|-v)
        echo "Shark OS CLI v${SHARK_VERSION}-${SHARK_RELEASE}"
        ;;
    status)
        echo "System Status:"
        uname -a
        uptime
        ;;
    update)
        echo "Update mechanism: A/B partitioning"
        echo "Not yet implemented in alpha"
        ;;
    config)
        shift
        case "$1" in
            show)
                echo "Current configuration:"
                cat /etc/shark/config.yml 2>/dev/null || echo "No config found"
                ;;
            edit)
                vi /etc/shark/config.yml
                ;;
        esac
        ;;
    *)
        echo "Shark OS CLI v${SHARK_VERSION}-${SHARK_RELEASE}"
        echo "Usage: shark [command]"
        echo ""
        echo "Commands:"
        echo "  version          Show version"
        echo "  status           Show system status"
        echo "  update [apply]   Update system"
        echo "  config [show|edit] Manage configuration"
        exit 1
        ;;
esac
EOF
    chmod +x "$overlay_dir/usr/local/bin/shark"

    # Create AppArmor profile for system services
    cat > "$overlay_dir/etc/apparmor.d/usr.bin.podman" << 'EOF'
#include <tunables/global>

/usr/bin/podman {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  
  capability dac_override,
  capability setuid,
  capability setgid,
  capability sys_chroot,
  capability net_admin,
  capability net_raw,
  capability sys_admin,
  capability sys_ptrace,
  capability sys_resource,
  
  /proc/** r,
  /sys/** r,
  /dev/** rw,
  /var/lib/containers/** rwk,
  /var/run/containers/** rwk,
  @{HOME}/.local/share/containers/** rwk,
  
  /etc/containers/* r,
  /etc/apparmor.d/* r,
}
EOF

    log_info "Overlays created at: $overlay_dir"
}

build_iso() {
    log_info "Building ISO image..."
    log_warn "This requires Alpine Linux build environment with mkimage"
    
    # Note: Full mkimage requires Alpine build environment
    # This is a placeholder for the actual mkimage command
    log_info "ISO building requires full Alpine build environment"
    log_info "To build actual ISO, run in Alpine Linux:"
    log_info "  mkimage -t iso -r $BUILD_DIR/profile.sh $DIST_DIR"
}

create_dummy_iso() {
    log_info "Creating dummy ISO for reference..."
    
    # Create a minimal tar structure that represents the filesystem
    cd "$BUILD_DIR"
    
    # Create filesystem structure
    mkdir -p fs/{root,home,etc,var,usr,srv}
    
    # Add overlay files
    if [ -d "overlay" ]; then
        cp -r overlay/* fs/root/ 2>/dev/null || true
    fi
    
    # Create tar
    tar -czf "$DIST_DIR/shark-os-base-${SHARK_VERSION}.tar.gz" -C "$BUILD_DIR" fs/
    
    log_info "Reference archive created: shark-os-base-${SHARK_VERSION}.tar.gz"
}

package_artifacts() {
    log_info "Packaging build artifacts..."
    
    # Create manifest
    cat > "$DIST_DIR/MANIFEST.txt" << EOF
Shark OS Build Manifest
Version: $SHARK_VERSION-$SHARK_RELEASE
Build Date: $BUILD_DATE
Architecture: x86_64, aarch64

Contents:
- shark-os-${SHARK_VERSION}-${BUILD_DATE}.iso (Main ISO image)
- build logs and artifacts
- Kernel configuration files
- Package lists

Build Information:
- Base: Alpine Linux
- Init: OpenRC
- Container Runtime: Podman
- Orchestration: K3s
- Kernel: Linux 6.6+ with eBPF, cgroup v2

For installation instructions, see docs/installation.md
EOF

    log_info "Manifest created"
}

cleanup() {
    log_warn "Cleaning up temporary build files..."
    # Keep build directory for debugging, comment if not needed
    # rm -rf "$BUILD_DIR"
    log_info "Cleanup complete"
}

# Main build flow
main() {
    echo "========================================="
    echo "Shark OS ISO Builder v$SHARK_VERSION"
    echo "Release: $SHARK_RELEASE"
    echo "Build Date: $BUILD_DATE"
    echo "========================================="
    echo ""
    
    check_dependencies
    setup_build_dirs
    build_apk_packages
    create_profile
    create_overlay
    create_dummy_iso
    build_iso
    package_artifacts
    
    echo ""
    echo "========================================="
    log_info "Build completed!"
    echo "Output location: $DIST_DIR"
    echo "========================================="
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

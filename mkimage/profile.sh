#!/bin/sh
# Shark OS mkimage profile
# Defines how to build the Shark OS ISO image

PROFILE="shark"
TITLE="Shark OS - Server-Oriented OS for Cloud & Edge"
DESC="Lightweight, fast, powerful, and secure operating system"

# ==============================================
# PACKAGES TO INCLUDE IN BASE IMAGE
# ==============================================

# Core system packages
PKGS="
alpine-base
alpine-baselayout
musl
libc6-compat
busybox
openrc
openrc-services
runit
"

# Kernel and bootloader
PKGS="$PKGS
linux-generic
grub
grub-efi
efibootmgr
"

# Networking
PKGS="$PKGS
iproute2
iptables
iptables-legacy
nftables
dhcpcd
"

# Container runtime
PKGS="$PKGS
podman
podman-docker
buildah
skopeo
"

# Kubernetes/K3s
PKGS="$PKGS
k3s
k3s-openrc
"

# Service mesh and networking
PKGS="$PKGS
cilium
cilium-cli
"

# System utilities
PKGS="$PKGS
util-linux
e2fsprogs
dosfstools
lvm2
parted
"

# Monitoring and logging
PKGS="$PKGS
prometheus
grafana
loki
promtail
"

# Development tools (can be removed in production)
PKGS="$PKGS
bash
curl
wget
git
openssh-client
nano
vim
"

# Security tools
PKGS="$PKGS
apparmor
apparmor-utils
apparmor-profiles
audit
"

# Performance monitoring
PKGS="$PKGS
sysstat
iotop
htop
"

# ==============================================
# OVERLAY DIRECTORIES
# ==============================================

# Base system overlay
OVERLAY_DIRS="base"

# ==============================================
# INSTALLATION SCRIPT
# ==============================================

install_shark_profile() {
    # Create necessary directories
    mkdir -p "$1/etc/shark"
    mkdir -p "$1/var/lib/shark"
    mkdir -p "$1/var/log/shark"
    mkdir -p "$1/etc/apparmor.d"
    mkdir -p "$1/etc/containers"
    mkdir -p "$1/etc/kubernetes"
    
    # Copy init script
    if [ -f "overlays/base/init-shark.sh" ]; then
        cp "overlays/base/init-shark.sh" "$1/etc/shark/init.sh"
        chmod +x "$1/etc/shark/init.sh"
    fi
    
    # Copy Shark CLI
    if [ -f "shark-cli/shark" ]; then
        cp "shark-cli/shark" "$1/usr/local/bin/shark"
        chmod +x "$1/usr/local/bin/shark"
    fi
    
    # Create default configuration
    cat > "$1/etc/shark/config.yml" << 'EOF'
---
# Shark OS Default Configuration

# System
system:
  version: "0.1.0-alpha"
  hostname: "shark-os"
  timezone: "UTC"

# Container runtime
containers:
  runtime: "podman"
  data_dir: "/var/lib/containers"
  
# Kubernetes
kubernetes:
  enabled: true
  controller: "k3s"
  data_dir: "/var/lib/k3s"

# Networking
network:
  cni: "cilium"
  ipv4_forward: true
  enable_bpf: true

# Security
security:
  apparmor: true
  selinux: false
  audit: true

# Monitoring
monitoring:
  prometheus: true
  grafana: true
  prometheus_data_dir: "/var/lib/prometheus"

# Logging
logging:
  enabled: true
  driver: "json-file"
  log_level: "info"

# Storage
storage:
  default_driver: "overlay2"
  data_root: "/var/lib/shark/storage"

EOF
    
    # Create AppArmor profiles
    cat > "$1/etc/apparmor.d/usr.bin.podman" << 'EOF'
#include <tunables/global>

/usr/bin/podman {
  #include <abstractions/base>
  
  capability dac_override,
  capability setfcap,
  capability setuid,
  capability setgid,
  capability sys_admin,
  
  /proc/sys/kernel/apparmor/profiles r,
  /sys/kernel/security/apparmor/ r,
  
  /var/lib/containers/** rw,
}
EOF
    
    cat > "$1/etc/apparmor.d/usr.bin.k3s" << 'EOF'
#include <tunables/global>

/usr/bin/k3s {
  #include <abstractions/base>
  
  capability sys_admin,
  capability sys_chroot,
  capability dac_override,
  capability setfcap,
  capability setuid,
  capability setgid,
  
  /var/lib/k3s/** rw,
  /proc/sys/kernel/** rw,
  /sys/kernel/security/apparmor/ r,
}
EOF
    
    # Create Podman configuration
    mkdir -p "$1/etc/containers/registries.d"
    mkdir -p "$1/etc/containers/registries.conf.d"
    
    cat > "$1/etc/containers/registries.conf" << 'EOF'
unqualified-search-registries = ["docker.io", "quay.io"]

[[registry]]
location = "docker.io"
insecure = false
EOF
    
    # Create K3s configuration
    cat > "$1/etc/kubernetes/k3s-config.yaml" << 'EOF'
---
# K3s Configuration for Shark OS

node-ip: "0.0.0.0"
node-external-ip: "0.0.0.0"
listen-port: 6443

# Container runtime
container-runtime-endpoint: "unix:///var/run/podman/podman.sock"

# Networking
flannel-backend: "none"  # Use Cilium instead
disable-metrics-server: false

# Security
service-account-issuer: "https://kubernetes.default.svc.cluster.local"
api-audit-log-path: "/var/log/kubernetes/audit.log"

# ETCD
etcd-expose-metrics: false

EOF
    
    # Create system service files
    mkdir -p "$1/etc/init.d"
    
    # Shark OS init service
    cat > "$1/etc/init.d/shark-init" << 'EOF'
#!/sbin/openrc-run

description="Shark OS Initialization Service"
command="/etc/shark/init.sh"
command_background=false

depend() {
    need localmount
}
EOF
    chmod +x "$1/etc/init.d/shark-init"
}

# Install profile
install_shark_profile "$@"

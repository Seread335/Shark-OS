#!/bin/sh
# Shark OS Init System Setup
# This script initializes the Shark OS system at boot time

VERSION="0.1.0"
SHARK_HOME="/etc/shark"
SHARK_LIBDIR="/var/lib/shark"
SHARK_LOGDIR="/var/log/shark"

# Create necessary directories
mkdir -p "$SHARK_LIBDIR" "$SHARK_LOGDIR"

# Initialize system hostname
if [ ! -f /etc/hostname ]; then
    echo "shark-os-$(date +%s)" > /etc/hostname
fi

# Setup logging
setup_logging() {
    echo "[INIT] Shark OS $(cat /etc/hostname) initializing at $(date)" >> "$SHARK_LOGDIR/init.log"
}

# Initialize network
init_network() {
    echo "[INIT] Initializing network interfaces..." >> "$SHARK_LOGDIR/init.log"
    
    # Bring up loopback
    ip link set lo up
    ip addr add 127.0.0.1/8 dev lo
    
    # DHCP on eth0 if available
    if [ -d /sys/class/net/eth0 ]; then
        ip link set eth0 up
        udhcpc -i eth0 2>/dev/null || true
    fi
}

# Initialize container runtime
init_containers() {
    echo "[INIT] Initializing container subsystem..." >> "$SHARK_LOGDIR/init.log"
    
    # Ensure cgroup directories
    mkdir -p /sys/fs/cgroup/{cpuset,cpu,memory,devices,freezer,net_cls,blkio}
    
    # Check for podman
    if command -v podman &>/dev/null; then
        echo "[INIT] Podman runtime available" >> "$SHARK_LOGDIR/init.log"
    fi
}

# Initialize security
init_security() {
    echo "[INIT] Initializing security subsystems..." >> "$SHARK_LOGDIR/init.log"
    
    # AppArmor
    if [ -d /sys/kernel/security/apparmor ]; then
        echo "[INIT] AppArmor security module loaded" >> "$SHARK_LOGDIR/init.log"
    fi
    
    # Set secure kernel parameters
    sysctl -w kernel.yama.ptrace_scope=2 2>/dev/null || true
    sysctl -w kernel.unprivileged_userns_clone=0 2>/dev/null || true
}

# Main init sequence
main() {
    setup_logging
    init_network
    init_containers
    init_security
    
    echo "[INIT] Shark OS initialization complete" >> "$SHARK_LOGDIR/init.log"
}

main "$@"

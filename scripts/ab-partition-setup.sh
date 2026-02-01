
#!/bin/bash
# ============================================================================
#  Shark OS - A/B Partitioning Setup Script
#
#  File:    ab-partition-setup.sh
#  Purpose: Thiết lập, quản lý, và kiểm soát update/rollback hệ thống phân vùng A/B
#           cho Shark OS (immutable update, auto-rollback, atomic switch).
#
#  Usage:
#    sudo bash scripts/ab-partition-setup.sh <command> [options]
#    Ví dụ:
#      scripts/ab-partition-setup.sh layout
#      scripts/ab-partition-setup.sh create /dev/sda
#      scripts/ab-partition-setup.sh grub /dev/sda /mnt
#      scripts/ab-partition-setup.sh switcher /usr/local/sbin
#
#  Liên hệ: github.com/Seread335/Shark-OS | Maintainer: Seread335
#  License: MIT
# ============================================================================

# Global error handler
set -eEuo pipefail
trap 'log_error "Lỗi không mong muốn tại dòng $LINENO. Script dừng."; exit 1' ERR

VERSION="0.1.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { printf '%b
' '\1'; }
log_warn() { printf '%b
' '\1'; }
log_error() { printf '%b
' '\1'; }

# Configuration constants
BOOT_SIZE="500M"           # EFI/BIOS boot partition
ROOT_SIZE="4G"             # Each root partition (A and B)
DATA_SIZE="remaining"      # Data partition uses remaining space


#=============================================================================
# A/B PARTITION LAYOUT
#=============================================================================

##############################################################################
# create_partition_table(device)
#   - Tạo bảng phân vùng GPT chuẩn A/B cho thiết bị (4 phân vùng: boot, rootA, rootB, data)
#   - Kiểm tra device tồn tại, xóa bảng cũ, tạo mới, đặt label, flag boot
#   - Dùng parted, dd, tính toán size động
##############################################################################
#
# Disk Layout:
# ┌─────────────────────────────────────────────────────────────────┐
# │ Partition 1: Boot (500MB)  - FAT32 EFI/MBR                      │
# │ ├─ GRUB bootloader                                              │
# │ └─ Kernel images (temporary)                                    │
# ├─────────────────────────────────────────────────────────────────┤
# │ Partition 2: Root A (4GB)  - ext4 (Read-Only in production)    │
# │ ├─ Active rootfs (/)                                            │
# │ └─ Kernel modules in /lib/modules                               │
# ├─────────────────────────────────────────────────────────────────┤
# │ Partition 3: Root B (4GB)  - ext4 (Read-Only in production)    │
# │ ├─ Backup rootfs (/)                                            │
# │ └─ Kernel modules in /lib/modules                               │
# ├─────────────────────────────────────────────────────────────────┤
# │ Partition 4: Data (remaining) - ext4 (Read-Write)              │
# │ ├─ /var/lib/shark (configuration)                               │
# │ ├─ /var/log (system logs)                                       │
# │ ├─ /var/lib/containers (container images/data)                  │
# │ ├─ /srv (application data)                                      │
# │ └─ /home (user data)                                            │
# └─────────────────────────────────────────────────────────────────┘
#
# Boot Flow:
# 1. GRUB reads boot partition
# 2. Bootloader checks which partition is active (via flag/env)
# 3. Boots into Root A or Root B
# 4. Root mounts Data partition for variable data
# 5. System initializes
#
# Update Flow:
# 1. Inactive partition (Root B) receives new image
# 2. Bootloader sets Root B as default
# 3. System reboots
# 4. If boot successful, Root A becomes backup
# 5. If boot fails, GRUB auto-reverts to Root A
#
#=============================================================================

create_partition_table() {
    local device="$1"
    
    if [ -z "$device" ]; then
        log_error "No device specified"
        exit 1
    fi
    
    log_info "Creating partition table on $device"
    
    # Check if device exists
    if [ ! -b "$device" ]; then
        log_error "Device not found: $device"
        exit 1
    fi
    
    # Clear existing partition table
    log_warn "Clearing existing partition table on $device"
    sudo dd if=/dev/zero of="$device" bs=512 count=2048 2>/dev/null || true
    
    # Create new GPT partition table
    log_info "Creating GPT partition table..."
    sudo parted -s "$device" mklabel gpt
    
    # Calculate partition sizes
    local total_size=$(sudo parted -s "$device" unit B print | grep "$device" | awk '{print $3}' | sed 's/B//')
    local data_size=$((total_size - 500*1024*1024 - 4*1024*1024*1024 - 4*1024*1024*1024))
    
    log_info "Total disk size: $((total_size / 1024 / 1024))MB"
    
    # Create partitions
    log_info "Creating Boot partition (500MB)..."
    sudo parted -s "$device" unit MB mkpart primary fat32 1 500
    
    log_info "Creating Root A partition (4GB)..."
    sudo parted -s "$device" unit MB mkpart primary ext4 500 4500
    
    log_info "Creating Root B partition (4GB)..."
    sudo parted -s "$device" unit MB mkpart primary ext4 4500 8500
    
    log_info "Creating Data partition (remaining)..."
    sudo parted -s "$device" unit MB mkpart primary ext4 8500 -1
    
    # Set labels
    sudo parted -s "$device" name 1 "boot"
    sudo parted -s "$device" name 2 "shark-root-a"
    sudo parted -s "$device" name 3 "shark-root-b"
    sudo parted -s "$device" name 4 "shark-data"
    
    # Set boot flag on boot partition
    sudo parted -s "$device" set 1 boot on
    
    log_info "Partition table created successfully"
    sudo parted -s "$device" print
}

##############################################################################
# format_partitions(device)
#   - Định dạng từng phân vùng theo chuẩn Shark OS
#   - Boot: FAT32, RootA/B: ext4, Data: ext4
#   - Tự động nhận diện prefix (nvme vs sd)
##############################################################################
format_partitions() {
    local device="$1"
    
    if [ -z "$device" ]; then
        log_error "No device specified"
        exit 1
    fi
    
    log_info "Formatting partitions..."
    
    # Detect partition naming convention (nvme vs sd)
    local part_prefix
    if [[ "$device" == *"nvme"* ]]; then
        part_prefix="${device}p"
    else
        part_prefix="${device}"
    fi
    
    # Boot partition - FAT32
    log_info "Formatting boot partition (${part_prefix}1) as FAT32..."
    sudo mkfs.vfat -F 32 -n "SHARK-BOOT" "${part_prefix}1"
    
    # Root A partition - ext4 with disabled journal for faster I/O
    log_info "Formatting Root A partition (${part_prefix}2) as ext4..."
    sudo mkfs.ext4 -F -L "shark-root-a" -m 0 "${part_prefix}2"
    
    # Root B partition - ext4
    log_info "Formatting Root B partition (${part_prefix}3) as ext4..."
    sudo mkfs.ext4 -F -L "shark-root-b" -m 0 "${part_prefix}3"
    
    # Data partition - ext4
    log_info "Formatting Data partition (${part_prefix}4) as ext4..."
    sudo mkfs.ext4 -F -L "shark-data" "${part_prefix}4"
    
    log_info "Partitions formatted successfully"
}

##############################################################################
# setup_grub(device, mount_point)
#   - Cài đặt GRUB bootloader lên phân vùng boot
#   - Sinh file cấu hình GRUB cho A/B, hỗ trợ EFI/BIOS
#   - Mount boot, cài grub, tạo menuentry cho rootA/B
##############################################################################
setup_grub() {
    local device="$1"
    local mount_point="$2"
    
    if [ -z "$device" ] || [ -z "$mount_point" ]; then
        log_error "Usage: setup_grub <device> <mount_point>"
        exit 1
    fi
    
    log_info "Setting up GRUB bootloader..."
    
    # Detect partition prefix
    local part_prefix
    if [[ "$device" == *"nvme"* ]]; then
        part_prefix="${device}p"
    else
        part_prefix="${device}"
    fi
    
    # Mount boot partition
    sudo mkdir -p "$mount_point/boot"
    sudo mount "${part_prefix}1" "$mount_point/boot"
    
    # Install GRUB
    log_info "Installing GRUB to $device..."
    sudo grub-install --target=x86_64-efi --efi-directory="$mount_point/boot" \
        --bootloader-id="SharkOS" --no-nvram "$device" 2>&1 || \
    sudo grub-install --target=i386-pc "$device" 2>&1
    
    # Create GRUB configuration
    log_info "Creating GRUB configuration..."
    
    local grub_cfg="$mount_point/boot/grub/grub.cfg"
    sudo mkdir -p "$(dirname "$grub_cfg")"
    
    sudo tee "$grub_cfg" > /dev/null << 'GRUB_EOF'
### Shark OS GRUB Configuration ###
# A/B Partitioning with automatic rollback

# Default boot timeout
set timeout=10
set default='Shark OS A'

# Shark OS A (Primary)
menuentry 'Shark OS A (Primary)' {
    set root='(hd0,gpt2)'
    echo 'Loading Shark OS from Root A...'
    linux /boot/vmlinuz-shark root=/dev/sda2 ro rootfstype=ext4
    initrd /boot/initrd.img-shark
}

# Shark OS B (Backup)
menuentry 'Shark OS B (Backup)' {
    set root='(hd0,gpt3)'
    echo 'Loading Shark OS from Root B...'
    linux /boot/vmlinuz-shark root=/dev/sda3 ro rootfstype=ext4
    initrd /boot/initrd.img-shark
}

# Fallback to UEFI firmware setup
menuentry 'UEFI Firmware Settings' {
    fwsetup
}

# Fallback to BIOS
menuentry 'Reboot' {
    reboot
}

menuentry 'Shutdown' {
    halt
}
GRUB_EOF

    log_info "GRUB configuration created"
}

##############################################################################
# create_partition_switcher(target_dir)
#   - Sinh script shark-switch-root cho phép chuyển đổi root A <-> B
#   - Ghi trạng thái update/rollback vào marker, hỗ trợ auto-rollback
#   - Đảm bảo atomicity khi update hệ thống
##############################################################################
create_partition_switcher() {
    local target_dir="$1"
    
    if [ -z "$target_dir" ]; then
        target_dir="/usr/local/sbin"
    fi
    
    log_info "Creating partition switching utility..."
    
    sudo tee "$target_dir/shark-switch-root" > /dev/null << 'SWITCHER_EOF'
#!/usr/bin/env bash
# shark-switch-root - Switch between Root A and Root B partitions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/lib/common.sh"
else
    set -eEuo pipefail
    trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR
fi

VERSION="0.1.0"
ROOT_A="/dev/disk/by-label/shark-root-a"
ROOT_B="/dev/disk/by-label/shark-root-b"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { printf '%b
' '\1'; }
log_warn() { printf '%b
' '\1'; }
log_error() { printf '%b
' '\1'; }

check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This script requires root privileges"
        exit 1
    fi
}

get_current_root() {
    # Detect current root partition from /proc/cmdline
    local cmdline=$(cat /proc/cmdline)
    if [[ "$cmdline" == *"root=/dev/sda2"* ]]; then
        echo "A"
    elif [[ "$cmdline" == *"root=/dev/sda3"* ]]; then
        echo "B"
    else
        echo "unknown"
    fi
}

show_status() {
    local current=$(get_current_root)
    local next
    if [ "$current" = "A" ]; then
        next="B"
    elif [ "$current" = "B" ]; then
        next="A"
    else
        next="unknown"
    fi
    
    echo "Current root: $current"
    echo "Backup root: $next"
}

do_switch() {
    check_root
    
    local current=$(get_current_root)
    local target
    
    if [ "$current" = "A" ]; then
        target="B"
    elif [ "$current" = "B" ]; then
        target="A"
    else
        log_error "Cannot determine current root partition"
        exit 1
    fi
    
    log_info "Switching from Root $current to Root $target..."
    log_warn "Next reboot will use Root $target"
    
    # Update GRUB to boot from new partition
    if command -v grub-set-default &>/dev/null; then
        grub-set-default "Shark OS $target"
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
    log_info "Switch scheduled. Please reboot to apply."
}

# Main
case "${1:-status}" in
    status)
        show_status
        ;;
    switch)
        do_switch
        ;;
    confirm)
        # Xác nhận boot thành công, ghi success vào marker
        status_file="/boot/shark-update.status"
        if [ -f "$status_file" ]; then
            sed -i 's/^pending:/success:/' "$status_file"
            echo "Update confirmed: system booted successfully."
        else
            echo "No pending update found."
        fi
        ;;
    rollback)
        # Rollback về root cũ nếu boot thất bại
        status_file="/boot/shark-update.status"
        if [ -f "$status_file" ]; then
            sed -i 's/^pending:/fail:/' "$status_file"
            # Đảo lại root về phân vùng trước
            current=$(get_current_root)
            if [ "$current" = "A" ]; then
                target="B"
            elif [ "$current" = "B" ]; then
                target="A" 
            else
                echo "Unknown root, cannot rollback."
                exit 1
            fi
            if command -v grub-set-default &>/dev/null; then
                grub-set-default "Shark OS $target"
                grub-mkconfig -o /boot/grub/grub.cfg
            fi
            echo "Rollback scheduled: will boot $target on next reboot."
        else
            echo "No pending update found."
        fi
        ;;
    *)
        echo "Shark OS Root Partition Switcher v${VERSION}"
        echo "Usage: shark-switch-root [status|switch|confirm|rollback]"
        exit 1
        ;;
esac
SWITCHER_EOF
    
    sudo chmod +x "$target_dir/shark-switch-root"
    log_info "Partition switcher created: $target_dir/shark-switch-root"
}

##############################################################################
# create_ab_fstab(root_mount, root_partition, data_partition)
#   - Sinh file /etc/fstab phù hợp cho hệ thống A/B
#   - Mount root, data, boot đúng label, hỗ trợ recovery
##############################################################################
create_ab_fstab() {
    local root_mount="$1"
    local root_partition="$2"
    local data_partition="$3"
    
    if [ -z "$root_mount" ] || [ -z "$root_partition" ] || [ -z "$data_partition" ]; then
        log_error "Usage: create_ab_fstab <root_mount> <root_partition> <data_partition>"
        exit 1
    fi
    
    log_info "Creating fstab for A/B system..."
    
    local fstab_file="$root_mount/etc/fstab"
    sudo mkdir -p "$(dirname "$fstab_file")"
    
    sudo tee "$fstab_file" > /dev/null << FSTAB_EOF
# /etc/fstab - Shark OS A/B Partitioning Layout

# Boot partition (optional, usually mounted by bootloader)
LABEL=SHARK-BOOT    /boot           vfat    defaults,ro     0   1

# Root partition (detected at boot, usually RO)
$root_partition     /               ext4    ro,errors=remount-ro 0   1

# Data partition (read-write for /var and /home)
$data_partition     /var/lib/shark  ext4    defaults        0   2

# Bind mounts for writable /var paths
/var/lib/shark/log          /var/log        none    bind,defaults   0   0
/var/lib/shark/containers   /var/lib/containers none bind,defaults  0   0
/var/lib/shark/home         /home           none    bind,defaults   0   0

# tmpfs for temporary files
tmpfs               /tmp            tmpfs   mode=1777,size=512M 0   0
tmpfs               /var/tmp        tmpfs   mode=1777,size=512M 0   0
tmpfs               /var/run        tmpfs   mode=1777,size=256M 0   0

# Kernel virtual filesystems
proc                /proc           proc    defaults        0   0
sysfs               /sys            sysfs   defaults        0   0
cgroup              /sys/fs/cgroup  cgroup  defaults        0   0
tmpfs               /dev            tmpfs   size=10M,mode=755 0 0
devpts              /dev/pts        devpts  gid=5,mode=620  0   0
FSTAB_EOF

    log_info "fstab created: $fstab_file"
}

# Function: Show disk layout diagram
show_layout() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                 Shark OS A/B Partitioning Scheme                           ║
╚════════════════════════════════════════════════════════════════════════════╝

Device Layout:
┌─────────────────────────────────────────────────────────────────────────┐
│ /dev/sda1 (500MB)                                                       │
│ FAT32 - Boot Partition                                                  │
│ ├─ GRUB Bootloader                                                      │
│ ├─ EFI system partition                                                 │
│ └─ Kernel images (vmlinuz-shark, initrd-shark)                         │
├─────────────────────────────────────────────────────────────────────────┤
│ /dev/sda2 (4GB) - Root A                 [ACTIVE/BACKUP]               │
│ ext4 - Read-Only Rootfs (in production)                                │
│ ├─ /bin, /sbin, /usr, /lib                                             │
│ ├─ /etc (read-only configs from data layer)                           │
│ ├─ /lib/modules (kernel modules)                                       │
│ ├─ /opt (application binaries)                                         │
│ └─ System binaries and libraries                                       │
├─────────────────────────────────────────────────────────────────────────┤
│ /dev/sda3 (4GB) - Root B                 [BACKUP/ACTIVE]               │
│ ext4 - Read-Only Rootfs (in production)                                │
│ └─ Mirror of Root A (switched during updates)                         │
├─────────────────────────────────────────────────────────────────────────┤
│ /dev/sda4 (Remaining)                                                   │
│ ext4 - Data Partition (Read-Write)                                     │
│ ├─ /var/lib/shark/               (Configuration, state)                │
│ │  ├─ config.yml                                                       │
│ │  ├─ cluster-config/                                                  │
│ │  └─ update-state/                                                    │
│ ├─ /var/log/                     (System logs)                         │
│ ├─ /var/lib/containers/          (Container storage)                   │
│ │  ├─ podman/                    (Podman data)                         │
│ │  └─ k3s/                       (K3s data)                            │
│ ├─ /home/                        (User data)                           │
│ ├─ /srv/                         (Service data)                        │
│ └─ /var/tmp/                     (Temporary files)                     │
└─────────────────────────────────────────────────────────────────────────┘

Mount Points at Runtime:
/                  → /dev/sda2 or /dev/sda3 (RO, current active root)
/boot              → /dev/sda1 (RO, boot files)
/var/lib/shark     → /dev/sda4 (RW, mounted from data partition)
/var/log           → bind mount to /var/lib/shark/log
/var/lib/containers → bind mount to /var/lib/shark/containers
/home              → bind mount to /var/lib/shark/home
/tmp               → tmpfs (512MB)
/var/tmp           → tmpfs (512MB)
/var/run           → tmpfs (256MB)

Update Process:
1. System running on Root A
2. Download new image
3. Write to Root B
4. Update GRUB boot parameter
5. Reboot
6. If Root B boot fails → Auto-rollback to Root A
7. If Root B succeeds → Root A becomes backup, Root B active

Benefits:
✓ Atomic updates (no partial state)
✓ Instant rollback capability
✓ Read-only rootfs prevents accidental changes
✓ Separation of OS and user data
✓ Reduced storage for container data
✓ Easy backup and recovery

EOF
}

# Main command handler
main() {
    case "${1:-help}" in
        layout)
            show_layout
            ;;
        
        create)
            if [ -z "$2" ]; then
                log_error "Usage: $(basename $0) create <device>"
                exit 1
            fi
            create_partition_table "$2"
            format_partitions "$2"
            ;;
        
        format)
            if [ -z "$2" ]; then
                log_error "Usage: $(basename $0) format <device>"
                exit 1
            fi
            format_partitions "$2"
            ;;
        
        grub)
            if [ -z "$2" ] || [ -z "$3" ]; then
                log_error "Usage: $(basename $0) grub <device> <mount_point>"
                exit 1
            fi
            setup_grub "$2" "$3"
            ;;
        
        switcher)
            create_partition_switcher "${2:-/usr/local/sbin}"
            ;;
        
        *)
            cat << EOF
Shark OS A/B Partitioning Setup Tool v${VERSION}

Usage: $(basename $0) <command> [options]

Commands:
  layout                           Show disk layout diagram
  create <device>                  Create A/B partition scheme on device
  format <device>                  Format partitions on device
  grub <device> <mount_point>     Setup GRUB bootloader
  switcher [target_dir]           Create root partition switcher tool

Examples:
  $(basename $0) layout                              # Show partition layout
  $(basename $0) create /dev/sda                     # Setup on /dev/sda
  $(basename $0) grub /dev/sda /mnt                  # Install GRUB
  $(basename $0) switcher /usr/local/sbin            # Install switcher tool

EOF
            exit 0
            ;;
    esac
}

main "$@"

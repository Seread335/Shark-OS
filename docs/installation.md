# Installation & Deployment Guide - Shark OS

Hướng dẫn cài đặt và triển khai Shark OS.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Post-Installation Setup](#post-installation-setup)
4. [Configuration](#configuration)
5. [Deployment](#deployment)

## System Requirements

### Minimum Hardware

| Thành phần | Yêu cầu tối thiểu |
|-----------|------------------|
| CPU | 1 core, 1GHz |
| RAM | 512MB |
| Storage | 2GB (+ dung lượng cho data) |
| Network | Ethernet (DHCP hoặc static) |

### Recommended Hardware

| Thành phần | Đề xuất |
|-----------|--------|
| CPU | 4+ cores, 2GHz+ |
| RAM | 4GB+ |
| Storage | 20GB+ NVMe |
| Network | 1Gbps+ |

### Supported Architectures

- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (ARMv8, Raspberry Pi 4+)
- **ARMv7** (32-bit ARM, Raspberry Pi 3)

## Installation Methods

### Method 1: USB Installation (Recommended)

**Yêu cầu:**
- USB drive 8GB+
- `dd` hoặc Rufus (Windows)
- Computer with UEFI/BIOS

**Bước:**

#### 1. Download ISO

```bash
wget https://github.com/Seread335/Shark-OS/releases/download/v0.1.0/shark-os-0.1.0.iso
# or
curl -L -o shark-os-0.1.0.iso https://...
```

#### 2. Write to USB

**Linux/Mac:**
```bash
# Find USB device
lsblk
# or
diskutil list

# Unmount USB
sudo umount /dev/sdX*
# or
diskutil unmountDisk /dev/diskX

# Write ISO
sudo dd if=shark-os-0.1.0.iso of=/dev/sdX bs=4M status=progress
sudo sync

# Eject
sudo eject /dev/sdX
```

**Windows (using Rufus):**
1. Download Rufus: https://rufus.ie/
2. Select USB drive
3. Select shark-os-0.1.0.iso
4. Click "Start"

#### 3. Boot from USB

1. Insert USB into target machine
2. Power on
3. Press boot menu key (F12, ESC, DEL, etc.)
4. Select USB drive
5. Boot from UEFI or Legacy

#### 4. Install Shark OS

```bash
# At boot menu, select "Install Shark OS"

# Follow interactive installer:
# 1. Select target disk
# 2. Configure partitioning (A/B automatic)
# 3. Set hostname
# 4. Configure network
# 5. Set root password
# 6. Select packages (Tiers)
# 7. Install

# System will reboot when complete
```

### Method 2: Network Boot (PXE)

**Yêu cầu:**
- DHCP server
- TFTP/HTTP server
- PXE-capable network card

**Setup:**

```bash
# 1. Extract kernel and initrd from ISO
mkdir -p /var/lib/tftp/shark
cd /tmp
mount -o loop shark-os-0.1.0.iso /mnt
cp /mnt/boot/vmlinuz-shark /var/lib/tftp/shark/
cp /mnt/boot/initrd.img-shark /var/lib/tftp/shark/
umount /mnt

# 2. Configure TFTP server (dnsmasq)
cat > /etc/dnsmasq.d/pxe.conf << 'EOF'
dhcp-boot=pxelinux.0
pxe-service=x86PC,"Boot Shark OS",pxelinux

# DHCP options
dhcp-option=3,192.168.1.1      # gateway
dhcp-option=6,8.8.8.8          # DNS
EOF

# 3. Create PXE menu
mkdir -p /var/lib/tftp/pxelinux.cfg
cat > /var/lib/tftp/pxelinux.cfg/default << 'EOF'
DEFAULT shark-install
PROMPT 0
TIMEOUT 50

LABEL shark-install
    KERNEL shark/vmlinuz-shark
    APPEND initrd=shark/initrd.img-shark root=/dev/nfs:192.168.1.10:/srv/shark
EOF

# 4. Boot client and select "Boot Shark OS"
```

### Method 3: Cloud Deployment

**AWS:**

```bash
# Convert ISO to AMI format
qemu-img convert -f iso -O qcow2 shark-os-0.1.0.iso shark-os.qcow2
qemu-img convert -f qcow2 -O vpc shark-os.qcow2 shark-os.vpc

# Upload to S3
aws s3 cp shark-os.vpc s3://my-bucket/

# Import as AMI
aws ec2 import-image \
  --cli-input-json file://import-image.json
```

**Azure:**

```bash
# Convert to VHD
qemu-img convert -f iso -O vpc shark-os-0.1.0.iso shark-os.vhd

# Upload to storage
az storage blob upload \
  --account-name myaccount \
  --container-name images \
  --name shark-os.vhd \
  --file shark-os.vhd

# Create image
az image create \
  --resource-group mygroup \
  --name shark-os \
  --source shark-os.vhd
```

**GCP:**

```bash
# Convert to GCP format
qemu-img convert -O qcow2 shark-os-0.1.0.iso shark-os.qcow2
tar czf shark-os.tar.gz shark-os.qcow2

# Upload to Cloud Storage
gsutil cp shark-os.tar.gz gs://my-bucket/

# Create image
gcloud compute images create shark-os \
  --source-uri=gs://my-bucket/shark-os.tar.gz
```

## Post-Installation Setup

### 1. First Boot

```bash
# System loads from Root A partition
# SSH available on port 22 (if installed)

# Login as root
# ssh root@<ip-address>
# or local console
```

### 2. Network Configuration

**DHCP (default):**
```bash
# Already configured, just needs network connectivity
ip addr show
ping 8.8.8.8
```

**Static IP:**

```bash
# Edit network config
vi /etc/shark/config.yml

# Update section:
network:
  hostname: "shark-01"
  interfaces:
    eth0:
      address: 192.168.1.10
      netmask: 255.255.255.0
      gateway: 192.168.1.1
      dns:
        - 8.8.8.8
        - 8.8.4.4

# Apply
shark config edit

# Or manually edit
vi /etc/network/interfaces
rc-service networking restart
```

### 3. Hostname Configuration

```bash
# Set hostname
shark config set hostname shark-prod-01

# Or manually
echo "shark-prod-01" > /etc/hostname
hostname -F /etc/hostname

# Verify
hostname
```

### 4. System Clock

```bash
# Set timezone
TZ=Asia/Ho_Chi_Minh
date

# Enable NTP service
rc-service chrony start
rc-update add chrony

# Verify
timedatectl  # or date
```

### 5. Storage Setup (A/B Partitions)

**Verify A/B layout:**
```bash
# Check partitions
lsblk
# or
parted -l

# Expected:
# sda1  boot   (500MB, FAT32)
# sda2  root-a (4GB, ext4, current)
# sda3  root-b (4GB, ext4, backup)
# sda4  data   (remaining, ext4)
```

**Check data partition:**
```bash
df -h /var/lib/shark
# Should show data partition

# Check mounts
mount | grep shark
```

## Configuration

### Shark CLI Setup

**Initialize configuration:**
```bash
shark config init

# or use default
cat /etc/shark/config.yml
```

**Edit configuration:**
```bash
shark config edit

# Or with editor
export EDITOR=vim
shark config edit
```

**Configuration file location:**
```bash
/etc/shark/config.yml
```

### Container Runtime (Podman)

**Check installation:**
```bash
podman --version
podman ps
podman images
```

**Test container:**
```bash
podman run --rm alpine:latest echo "Hello Shark OS!"

# Expected: Hello Shark OS!
```

**Enable rootless mode (optional):**
```bash
# Add user
adduser appuser

# Configure rootless
podman system migrate

# Test as user
su - appuser
podman ps
```

### Kubernetes (K3s)

**Check installation:**
```bash
k3s --version
k3s check-config
```

**Initialize cluster (single node):**
```bash
shark kubernetes init

# or manually
k3s server --node-name=shark-01

# In another terminal
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

**Join worker nodes:**

On control plane:
```bash
cat /var/lib/rancher/k3s/server/node-token
```

On worker:
```bash
k3s agent --server https://<control-plane-ip>:6443 \
  --token <token>
```

### AppArmor Security

**Check profiles:**
```bash
aa-status
```

**Load profiles:**
```bash
apparmor_parser -r /etc/apparmor.d/podman
apparmor_parser -r /etc/apparmor.d/k3s
```

**Create custom profile:**
```bash
cat > /etc/apparmor.d/myapp << 'EOF'
#include <tunables/global>

/path/to/myapp {
  #include <abstractions/base>
  
  capability dac_override,
  
  /etc/** r,
  /var/lib/myapp/** rwk,
}
EOF

apparmor_parser -r /etc/apparmor.d/myapp
```

## Deployment

### 1. Cluster Setup

**Multi-node K3s cluster:**

```bash
# Node 1 - Control Plane
k3s server --node-name=shark-cp-01 \
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16 \
  --bind-address=<CP_IP>

# Get token
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# Node 2-N - Workers
k3s agent \
  --server https://<CP_IP>:6443 \
  --token $TOKEN \
  --node-name=shark-worker-01

# Verify cluster
kubectl get nodes
```

### 2. Container Deployment

**Using Podman:**
```bash
# Pull image
podman pull docker.io/library/nginx:latest

# Run container
podman run -d \
  --name web \
  -p 80:80 \
  nginx:latest

# Check status
podman ps
podman logs web
```

**Using Kubernetes:**
```bash
cat > nginx-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

kubectl apply -f nginx-deployment.yaml
kubectl get pods
kubectl port-forward svc/nginx-web 8080:80
```

### 3. Monitoring

**Enable monitoring:**
```bash
# Check Node Exporter
curl localhost:9100/metrics

# In K3s, deploy Prometheus
kubectl apply -f prometheus-helm-chart.yaml

# Deploy Grafana
kubectl apply -f grafana-helm-chart.yaml
```

### 4. Updates

**Check for updates:**
```bash
shark update info
shark update check
```

**Apply update:**
```bash
# Download and stage update to Root B
shark update apply

# Reboot to new version
shark system reboot

# Automatic rollback if fails
```

**Rollback (if needed):**
```bash
# Switch back to Root A
shark-switch-root switch

# Reboot
shark system reboot
```

## Troubleshooting

### Can't connect to network

```bash
# Check interface
ip link show
ip addr show

# Test DHCP
dhclient eth0

# Or configure static IP
vi /etc/network/interfaces
rc-service networking restart
```

### SSH not working

```bash
# Check SSH service
rc-service sshd status

# Start if needed
rc-service sshd start
rc-update add sshd

# Check config
cat /etc/ssh/sshd_config
```

### Kubernetes not initializing

```bash
# Check k3s service
rc-service k3s status

# Check logs
cat /var/log/k3s.log

# Or start manually with verbose
k3s server --debug
```

### Storage issues

```bash
# Check partition status
lsblk
df -h

# Check journald
journalctl -xe

# Remount read-write if needed (ROOT A)
mount -o remount,rw /
```

## Support & Resources

- Documentation: https://github.com/Seread335/Shark-OS/wiki
- Issues: https://github.com/Seread335/Shark-OS/issues
- Community: GitHub Discussions
- Enterprise Support: contact@sharkoq.io

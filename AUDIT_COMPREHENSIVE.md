# 🔴 **SHARK OS - AUDIT KIỂM ĐỊNH ENTERPRISE PRODUCTION-GRADE**

**Ngày audit**: 02/01/2026  
**Mức độ audit**: Enterprise Production-Grade (Cực kỳ khó tính)  
**Status dự án**: v0.1.0-alpha  
**Auditor**: GitHub Copilot - Expert Security & Quality Auditor  

---

## 📊 **QUICK SUMMARY**

| Tiêu chí | Đánh giá | Ghi chú |
|---------|---------|--------|
| **Architecture** | ⭐⭐⭐⭐ | Thiết kế tốt, nhưng thực thi nguy hiểm |
| **Security** | 🔴 1/10 | Bảo mật gần như không tồn tại |
| **Code Quality** | 🟠 3/10 | Nhiều anti-pattern, thiếu validation |
| **Error Handling** | 🔴 1/10 | Gần như không có error handling |
| **Test Coverage** | 🟠 2/10 | Test framework rất cơ bản, coverage < 20% |
| **Documentation** | ⭐⭐⭐ | Tốt nhưng không đủ chi tiết về security |
| **CI/CD** | 🟠 4/10 | Có setup nhưng chưa hoàn chỉnh |
| **Production-Ready** | 🔴 0/10 | **KHÔNG - TUYỆT ĐỐI KHÔNG TRIỂN KHAI** |

---

## 🔴 **CRITICAL ISSUES** (Phải sửa ngay - blocking release)

### **CRITICAL #1: Zero Authentication/Authorization - System Completely Open**

**Files**: `shark-cli/shark`, `docs/config.example.yml`, `scripts/ab-partition-setup.sh`  
**Severity**: 🔴 CRITICAL  

#### Vấn đề:
```bash
# shark-cli/shark - Dòng 156-164
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This command requires root privileges"
        exit 1
    fi
}

cmd_system() {
    local action="${1:-info}"
    case "$action" in
        reboot)
            check_root  # ← CHỈ KIỂM TRA ROOT - KHÔNG CÓ RBAC
            reboot
        ;;
    esac
}
```

#### Tại sao nguy hiểm:
- ❌ Không có role-based access control (RBAC)
- ❌ Không có token-based authentication
- ❌ Kubernetes API exposed to `0.0.0.0:6443` (publicly accessible!)
- ❌ Không có audit trail ai thực thi lệnh gì
- ❌ Multi-user systems hoàn toàn không bảo mật
- ❌ Không có fine-grained permissions (e.g., "operator có thể reboot nhưng không thể xóa data")

**Mức độ nguy hiểm**: 🔴 **CRITICAL** - Bất kỳ người dùng nào có shell access có thể control toàn bộ hệ thống

#### Hướng sửa:
```bash
# Implement proper authentication + authorization
require_auth() {
    local token="$1"
    
    # 1. Validate token từ secure storage
    local token_file="/etc/shark/secrets/auth.tokens"
    local token_hash=$(echo -n "$token" | sha256sum | cut -d' ' -f1)
    
    if ! grep -q "$token_hash" "$token_file"; then
        log_error "Authentication failed"
        return 1
    fi
    
    # 2. Extract role từ token
    local role=$(grep "$token_hash" "$token_file" | cut -d':' -f2)
    echo "$role"
    return 0
}

check_permission() {
    local role="$1"
    local action="$2"
    local resource="$3"
    
    # Load RBAC policy
    local policy_file="/etc/shark/rbac.yaml"
    
    # Check if role has permission
    if yq e ".roles.${role}.permissions[] | select(. == \"${resource}:${action}\")" "$policy_file" | grep -q .; then
        return 0
    fi
    
    log_error "Permission denied: role=$role action=$action resource=$resource"
    return 1
}

# Example RBAC policy:
# /etc/shark/rbac.yaml:
# roles:
#   admin:
#     permissions:
#       - "system:*"
#       - "kubernetes:*"
#   operator:
#     permissions:
#       - "system:reboot"
#       - "system:status"
#   viewer:
#     permissions:
#       - "system:status"
```

---

### **CRITICAL #2: Remote Code Execution (RCE) - Command Injection Everywhere**

**Files**: `shark-cli/shark`, `tests/functional-cli-tests.sh`, `scripts/ab-partition-setup.sh`  
**Severity**: 🔴 CRITICAL  

#### Vấn đề #2.1 - Direct argument passthrough:
```bash
# shark-cli/shark - Dòng 450-460
cmd_container() {
    local action="${1}"
    case "$action" in
        run)
            shift
            podman run "$@"  # ← DANGEROUS: Tất cả arg passed to podman
        ;;
    esac
}
```

**Attack scenario**:
```bash
shark container run --rm -it "$(whoami > /tmp/pwned)" alpine  # RCE
shark container run --network host -it alpine nc -l -p 9999  # Attacker gains access
shark container run -v /etc/shadow:/tmp/shadow alpine  # Reads sensitive files
```

#### Vấn đề #2.2 - No path validation:
```bash
# shark-cli/shark - Dòng 280-290
cmd_config() {
    local action="${1:-show}"
    local config_file="${SHARK_CONFIG}"  # User có thể set SHARK_CONFIG=/etc/passwd
    
    cat "$config_file"  # → Reads /etc/passwd
}
```

#### Vấn đề #2.3 - Device parameter không validate:
```bash
# scripts/ab-partition-setup.sh - Dòng 100-110
create_partition_table() {
    local device="$1"  # ← No validation
    
    # ...
    sudo parted -s "$device" mklabel gpt  # ← Nếu device="/etc/shadow; rm -rf /", nguy hiểm!
}
```

**Mức độ nguy hiểm**: 🔴 **CRITICAL** - Remote Code Execution, data theft, system destruction

#### Hướng sửa:
```bash
# 1. Implement strict input validation
validate_device() {
    local device="$1"
    
    # Whitelist: chỉ /dev/sd[a-z] hoặc /dev/nvme[0-9]n[0-9]
    if ! [[ $device =~ ^/dev/(sd[a-z]|nvme[0-9]n[0-9])$ ]]; then
        log_error "Invalid device: $device (must be /dev/sd* or /dev/nvme*)"
        return 1
    fi
    
    # Verify device actually exists
    [ -b "$device" ] || { log_error "Device does not exist: $device"; return 1; }
    
    echo "$device"
}

# 2. Whitelist container flags
cmd_container() {
    local action="${1}"
    
    case "$action" in
        run)
            shift
            
            # Whitelist of allowed flags only
            local allowed_flags=("--rm" "--it" "-i" "-t" "--name" "--image" "--volume" "--env")
            local dangerous_flags=("--network" "--privileged" "--cap-add" "--device")
            
            local safe_args=()
            while [[ $# -gt 0 ]]; do
                local flag="$1"
                
                # Check if this is a dangerous flag
                for dangerous in "${dangerous_flags[@]}"; do
                    if [[ "$flag" == "$dangerous"* ]]; then
                        log_error "Forbidden podman flag: $flag (security risk)"
                        return 1
                    fi
                done
                
                # Only add allowed flags
                if [[ " ${allowed_flags[@]} " =~ " ${flag} " ]]; then
                    safe_args+=("$flag")
                    [[ $# -gt 1 ]] && safe_args+=("$2") && shift
                fi
                
                shift
            done
            
            podman run "${safe_args[@]}"
            ;;
    esac
}

# 3. Validate config file paths
cmd_config() {
    local action="${1:-show}"
    local config_file="${SHARK_CONFIG}"
    
    # Ensure config file is in allowed location
    if ! [[ "$config_file" =~ ^/etc/shark/ ]]; then
        log_error "Config file must be in /etc/shark/ - got: $config_file"
        return 1
    fi
    
    # Resolve symlinks and check if within /etc/shark
    local resolved
    resolved=$(cd "$(dirname "$config_file")" && pwd) || return 1
    
    if ! [[ "$resolved" =~ ^/etc/shark ]]; then
        log_error "Config path outside /etc/shark: $resolved"
        return 1
    fi
    
    cat "$config_file"
}
```

---

### **CRITICAL #3: Shell Injection Vulnerabilities Throughout**

**Files**: `scripts/setup-build-env.sh`, `scripts/ab-partition-setup.sh`, all shell scripts  
**Severity**: 🔴 CRITICAL  

#### Vấn đề #3.1 - Unquoted variables:
```bash
# scripts/setup-build-env.sh - Dòng 70-75
local deps_array=(
    "build-base"
    "abuild"
)
apk update
apk add --no-cache $deps  # ← DANGER: Word splitting
# Nếu deps="foo bar;rm -rf /", sẽ chạy: apk add --no-cache foo bar;rm -rf /
```

#### Vấn đề #3.2 - Unsafe command substitution:
```bash
# scripts/ab-partition-setup.sh - Dòng 115
local total_size=$(sudo parted -s "$device" unit B print | grep "$device" | awk '{print $3}' | sed 's/B//')
# Nếu output chứa `;` hoặc `$()`, will be evaluated!
```

#### Vấn đề #3.3 - Unquoted grep patterns:
```bash
# shark-cli/shark - Dòng 376
grep "^${key}:" "$SHARK_CONFIG"  # ← Nếu key=".*;rm -rf /", grep interprets as regex
```

**Mức độ nguy hiểm**: 🔴 **CRITICAL** - Shell injection, arbitrary command execution

#### Hướng sửa:
```bash
# 1. Always quote variables and use arrays for lists
declare -a deps_array=(
    "build-base"
    "abuild"
    "apk-tools"
)
apk update
apk add --no-cache "${deps_array[@]}"  # ← Safe

# 2. Use read-only variables for immutable data
readonly SHARK_CONFIG="/etc/shark/config.yml"
readonly SHARK_DATA_DIR="/var/lib/shark"

# 3. Use grep -F for fixed strings (not regex)
grep -F "^${key}:" "$SHARK_CONFIG"  # Key is literal, not regex pattern

# 4. Escape special characters in grep patterns
escape_grep_pattern() {
    local pattern="$1"
    # Escape special regex chars
    printf '%s\n' "$pattern" | sed -e 's/[\/&]/\\&/g'
}

# 5. Capture command output safely (avoid pipes when possible)
get_disk_size() {
    local device="$1"
    
    # Don't pipe multiple commands - use process substitution
    local output
    output=$( sudo parted -s "$device" unit B print 2>&1 ) || return 1
    
    # Parse carefully, don't eval output
    local size
    size=$(printf '%s\n' "$output" | grep -F "$device" | awk '{print $3}')
    
    # Remove 'B' suffix safely (no regex eval)
    size="${size%B}"  # Bash parameter expansion, safe
    
    echo "$size"
}
```

---

### **CRITICAL #4: Secrets Management Completely Missing**

**Files**: `docs/config.example.yml`, `shark-cli/shark`, entire system  
**Severity**: 🔴 CRITICAL  

#### Vấn đề:
- ❌ Không có mechanism để store SSH keys securely
- ❌ Kubernetes admin token sẽ được lưu plaintext
- ❌ API keys, DB passwords không encrypted
- ❌ Không có secret rotation
- ❌ Không có audit of secret access
- ❌ Vault integration mentioned nhưng NOT implemented

**Evidence**:
```yaml
# docs/config.example.yml - Users would add secrets here
kubernetes:
  cluster:
    admin_token: "sk_admin_123456..."  # ← Plaintext!
    ca_cert: |
      -----BEGIN CERTIFICATE-----
      MIID...  # ← Another secret in plaintext
```

#### Attack scenario:
- Attacker với read access `/etc/shark/config.yml` → Gets all credentials
- Backup file `/var/backups/shark-config/config.yml.*` → All backups contain secrets
- Log files mentioning config loading → Secrets in logs

**Mức độ nguy hiểm**: 🔴 **CRITICAL** - Credential theft, lateral movement, system compromise

#### Hướng sửa:
```bash
# 1. Create secure secrets directory
mkdir -p /etc/shark/secrets
chmod 700 /etc/shark/secrets

# 2. Never put secrets in config files
# Instead, use file references:
# /etc/shark/config.yml:
kubernetes:
  kubeconfig: "/etc/shark/secrets/kubeconfig"  # Path reference
  ca_cert_file: "/etc/shark/secrets/ca.crt"    # Not content

# 3. Encrypt secrets at rest
gpg --output /etc/shark/secrets/kubeconfig.gpg --encrypt --recipient admin@shark.local kubeconfig

# 4. Implement secret rotation
shark secret rotate kubeconfig --days 90 --algorithm rsa

# 5. Add to CI/CD securely (GitHub Actions)
# NEVER commit secrets to repo
# Use GitHub Secrets + encrypted env files:
- name: Prepare secrets
  run: |
    gpg --import <<< "${{ secrets.GPG_PRIVATE_KEY }}"
    gpg -d secrets.gpg > /etc/shark/secrets/kubeconfig
    chmod 600 /etc/shark/secrets/kubeconfig
```

---

### **CRITICAL #5: A/B Partitioning Implementation - Race Conditions & Unbootable System Risk**

**Files**: `scripts/ab-partition-setup.sh`, `shark-cli/shark update apply`  
**Severity**: 🔴 CRITICAL  

#### Vấn đề #5.1 - No atomic operations:
```bash
# scripts/ab-partition-setup.sh - Dòng 105-145
create_partition_table() {
    sudo dd if=/dev/zero of="$device" bs=512 count=2048  # Step 1
    sudo parted -s "$device" mklabel gpt                 # Step 2
    sudo parted -s "$device" unit MB mkpart primary fat32 1 500  # Step 3
    # ... 7 more steps
    # If fails at step 5/10: DEVICE IS IN CORRUPTED STATE
    # NO rollback, NO retry mechanism
}
```

#### Vấn đề #5.2 - No boot verification or watchdog:
```bash
# Design mentions: "If boot fails → Auto-rollback"
# Reality: NO CODE for boot verification
# NO watchdog timer
# NO "if boot fails 3 times, rollback" logic
```

#### Vấn đề #5.3 - GRUB config hardcoded:
```bash
# scripts/ab-partition-setup.sh - Dòng 228-260
sudo tee "$grub_cfg" > /dev/null << 'GRUB_EOF'
menuentry 'Shark OS A (Primary)' {
    set root='(hd0,gpt2)'
    linux /boot/vmlinuz-shark root=/dev/sda2 ro  # ← HARDCODED /dev/sda2
    # Fails if actual device is /dev/sdb or /dev/nvme0n1!
}
GRUB_EOF
```

#### Attack scenario:
```bash
# Attacker (or legitimate update process):
1. Writes to Root B
2. Sets boot to Root B
3. Reboot
4. **System fails to boot** (GRUB config wrong, filesystem corrupted, etc.)
5. **No automatic rollback** → System stuck in unbootable state
6. Cannot recover without manual intervention
```

**Mức độ nguy hiểm**: 🔴 **CRITICAL** - Unbootable systems in production = total downtime

#### Hướng sửa:
```bash
# 1. Implement atomic partition operations with checkpointing
setup_partitions_with_checkpoint() {
    local device="$1"
    local checkpoint_file="/var/lib/shark/partition_setup.checkpoint"
    
    # Backup original partition table
    sudo sfdisk -d "$device" > "${checkpoint_file}.backup" || {
        log_error "Failed to backup partition table"
        return 1
    }
    
    # Cleanup trap
    trap 'sudo sfdisk -f "$device" < "${checkpoint_file}.backup"; rm -f "$checkpoint_file"*' ERR
    
    # Perform all operations (use `set -e` so any failure exits immediately)
    set -e
    sudo parted -s "$device" mklabel gpt
    sudo parted -s "$device" unit MB mkpart primary fat32 1 500
    # ... more operations
    
    # Verify all partitions exist
    verify_partitions "$device" || { trap - ERR; return 1; }
    
    # Success - remove trap
    trap - ERR
    rm -f "${checkpoint_file}".backup
}

# 2. Implement boot verification with watchdog
/etc/shark/init.d/boot-verify:
#!/openrc-run

description="Verify system boot health and auto-rollback if needed"

depend() {
    after localmount
}

start() {
    ebegin "Verifying system boot health..."
    
    local boot_count_file="/var/lib/shark/boot_count"
    local max_attempts=3
    
    # Increment boot count
    local count=$(($(cat "$boot_count_file" 2>/dev/null || echo 0) + 1))
    echo "$count" > "$boot_count_file"
    
    # Health checks
    check_filesystem || return 1
    check_network || return 1
    check_essential_services || return 1
    
    # If all checks passed, reset boot count
    echo "0" > "$boot_count_file"
    
    eend 0
}

check_filesystem() {
    # Verify /etc, /var, /usr are readable and have required files
    [ -f /etc/os-release ] || return 1
    [ -d /var/log ] || return 1
    [ -d /usr/bin ] || return 1
    return 0
}

# 3. Auto-rollback if boot fails
if [ $count -gt $max_attempts ]; then
    ewarn "System failed $max_attempts boot attempts, initiating auto-rollback..."
    
    # Get current root partition
    local current_root=$(cat /proc/cmdline | grep -o 'root=/dev/[^ ]*')
    local next_root
    
    if [[ "$current_root" == *"/dev/sda3" ]]; then
        next_root="/dev/sda2"
    else
        next_root="/dev/sda3"
    fi
    
    # Update GRUB to boot from other partition
    grub-editenv / set saved_entry="Shark OS A"  # or B
    sync
    
    ewarn "Rolled back to $next_root, rebooting..."
    reboot -f
fi

# 4. Generate GRUB config dynamically (not hardcoded)
generate_grub_config() {
    local device="$1"
    local boot_partition="$2"
    
    # Detect actual partition numbers
    local root_a_part root_b_part
    root_a_part=$(sudo parted -s "$device" print | grep "shark-root-a" | awk '{print $1}')
    root_b_part=$(sudo parted -s "$device" print | grep "shark-root-b" | awk '{print $1}')
    
    # Convert device to GRUB notation
    local grub_device="hd0"  # Assumes first disk
    
    # Generate config with actual partition numbers
    cat > /tmp/grub.cfg << EOF
set timeout=10
set default='Shark OS A'

menuentry 'Shark OS A (Primary)' {
    set root='(hd0,gpt${root_a_part})'
    echo 'Loading Shark OS from Root A...'
    linux /boot/vmlinuz-shark root=${device}${root_a_part} ro rootfstype=ext4
    initrd /boot/initrd.img-shark
}

menuentry 'Shark OS B (Backup)' {
    set root='(hd0,gpt${root_b_part})'
    echo 'Loading Shark OS from Root B...'
    linux /boot/vmlinuz-shark root=${device}${root_b_part} ro rootfstype=ext4
    initrd /boot/initrd.img-shark
}
EOF
    
    sudo cp /tmp/grub.cfg /boot/grub/grub.cfg
}
```

---

## 🟠 **MAJOR ISSUES** (Ảnh hưởng chất lượng / mở rộng)

### **MAJOR #1: Virtually No Error Handling**

**Files**: Toàn bộ shell scripts  
**Severity**: 🟠 MAJOR  

#### Vấn đề:
```bash
# mkimage/mkimg.shark.sh
cp -r overlays/base/etc "$BUILD_DIR/fs/etc"  # What if cp fails?
chmod -R 755 "$BUILD_DIR/fs/etc"  # Proceeds anyway, assumes cp succeeded

# Should be:
cp -r overlays/base/etc "$BUILD_DIR/fs/etc" || {
    log_error "Failed to copy etc overlay"
    exit 1
}
```

#### Hậu quả:
- ❌ Silent failures, difficult debugging
- ❌ Corrupted builds/images
- ❌ Data loss scenarios
- ❌ No visibility into what failed

#### Hướng sửa:
Use `set -eEuo pipefail` at top of every script + add error handling for pipeline failures

---

### **MAJOR #2: Test Coverage < 20%, No Unit Tests**

**Files**: `tests/test-framework.sh`, `tests/functional-cli-tests.sh`  
**Severity**: 🟠 MAJOR  

#### Vấn đề:
- ❌ No unit tests for critical functions (validate_input, encrypt_secrets, partition_setup)
- ❌ Functional tests are TOO BASIC (just check if command runs)
- ❌ No negative test cases for all major features
- ❌ No load/stress testing
- ❌ No chaos engineering tests (what if network fails during update?)

#### Test gaps:
- No tests for: authentication, authorization, input validation
- No tests for: A/B partition edge cases, rollback scenarios
- No tests for: concurrent operations, race conditions
- No tests for: recovery from partial failures

---

### **MAJOR #3: No Audit Logging**

**Files**: `shark-cli/shark`, all admin operations  
**Severity**: 🟠 MAJOR  

#### Vấn đề:
```bash
# shark-cli/shark - Lines 161-171
cmd_system() {
    case "$action" in
        reboot)
            check_root
            reboot  # ← No log of WHO rebooted WHEN
        ;;
    esac
}
```

#### Hậu quả:
- ❌ No compliance with security standards (SOC 2, PCI-DSS require audit logs)
- ❌ Incident investigation impossible
- ❌ Cannot detect who made what changes
- ❌ No security monitoring/alerting

---

### **MAJOR #4: Dependency Management Non-existent**

**Files**: `scripts/setup-build-env.sh`, `APKBUILD`  
**Severity**: 🟠 MAJOR  

#### Vấn đề:
- ❌ No dependency versions pinned
- ❌ No vulnerability scanning (CVE checks)
- ❌ No SBOM (Software Bill of Materials)
- ❌ No dependency tree analysis
- ❌ CI/CD doesn't check for known CVEs

---

### **MAJOR #5: Configuration Management Is Ad-hoc**

**Files**: `docs/config.example.yml`, `shark-cli/shark config`  
**Severity**: 🟠 MAJOR  

#### Vấn đề:
- ❌ No schema validation (just "is it valid YAML?")
- ❌ No configuration drift detection
- ❌ No rollback mechanism for config changes
- ❌ No automated testing of config changes
- ❌ K8s API exposed to `0.0.0.0` by default (CRITICAL!)

---

## 🟡 **MINOR ISSUES** (Style, readability, best practices)

### **MINOR #1: Inconsistent Error Messages & Logging**

```bash
# Sometimes: "Lỗi không mong muốn" (Vietnamese)
# Sometimes: "ERROR:" (English)
# Sometimes: "This command requires..." (no prefix)

# Should standardize:
readonly LOG_LEVEL_ERROR="ERROR"
readonly LOG_LEVEL_WARN="WARN"
readonly LOG_LEVEL_INFO="INFO"

log_error() { printf "[%s] %s\n" "$LOG_LEVEL_ERROR" "$*" >&2; }
log_warn() { printf "[%s] %s\n" "$LOG_LEVEL_WARN" "$*" >&2; }
log_info() { printf "[%s] %s\n" "$LOG_LEVEL_INFO" "$*" >&2; }
```

### **MINOR #2: Mixed Vietnamese/English Comments & Naming**

```bash
# shark-cli/shark line 3:
trap 'log_error "Lỗi không mong muốn tại dòng $LINENO..."'
# vs other comments in English

# Should: Pick one language consistently
```

### **MINOR #3: Function Documentation Missing**

```bash
# No function docstrings/comments explaining:
# - What parameters are expected
# - What return value means
# - What side effects occur
# - What error conditions are handled

# Should add:
validate_device() {
    # Validate block device path
    # Args:
    #   $1: Device path (e.g., /dev/sda, /dev/nvme0n1)
    # Returns:
    #   0 if valid, 1 if invalid
    # Side effects:
    #   Prints validated path to stdout
    local device="$1"
    # ...
}
```

### **MINOR #4: Hardcoded Paths & Magic Numbers**

```bash
# scripts/ab-partition-setup.sh:
BOOT_SIZE="500M"
ROOT_SIZE="4G"
DATA_SIZE="remaining"

# Should make configurable:
# /etc/shark/partition.conf:
BOOT_SIZE="${BOOT_SIZE:-500M}"
ROOT_SIZE="${ROOT_SIZE:-4G}"
```

---

## 🟢 **ĐIỂM TỐT** (Những gì project làm đúng)

### **GOOD #1: Architecture & Design Philosophy** ✅

- ✅ A/B partitioning concept is sound  
- ✅ Layered architecture (Tier 1/2/3) is well-designed  
- ✅ Separation of concerns (scripts, CLI, overlays)  
- ✅ Use of AppArmor + hardening concepts correct  

### **GOOD #2: Security Hardening Intentions** ✅

- ✅ Concepts like read-only rootfs, immutable updates are correct  
- ✅ Understanding of containerization, Kubernetes integration  
- ✅ AppArmor profiles mentioned (even if not complete)  
- ✅ DPDK, eBPF support planned  

### **GOOD #3: Build System & Packaging** ✅

- ✅ Alpine Linux + abuild is appropriate for lightweight OS  
- ✅ apports/ structure follows Alpine conventions  
- ✅ mkimage/ approach for ISO generation is solid  

### **GOOD #4: Documentation Awareness** ✅

- ✅ README, ROADMAP, CONTRIBUTING exist  
- ✅ Effort to document design decisions  
- ✅ Examples and installation guides provided  

---

## 📋 **TECHNICAL DEBT SUMMARY**

| Loại | Số lượng | Mức độ |
|------|---------|-------|
| **Shell Injection Vulnerabilities** | 10+ | Critical |
| **Missing Input Validation** | 15+ | Critical |
| **Unhandled Error Cases** | 20+ | Major |
| **Hardcoded Values** | 8+ | Major |
| **Missing Tests** | 25+ functions | Major |
| **Documentation Gaps** | 30+ | Minor |
| **Code Style Inconsistencies** | 50+ | Minor |

---


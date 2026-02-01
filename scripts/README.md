# Scripts

Tiện ích và script giúp xây dựng và quản lý Shark OS.

## Các Scripts

### setup-build-env.sh
Cài đặt build environment trên Alpine Linux.

```bash
bash setup-build-env.sh
```

**Làm gì:**
- Cài dependencies (abuild, alpine-sdk, etc.)
- Thiết lập abuild keys
- Tạo thư mục build
- Cấu hình git hooks

### ab-partition-setup.sh
Thiết lập A/B partitioning scheme cho ổ đĩa.

---
#### ⚠️ HƯỚNG DẪN SỬ DỤNG AN TOÀN

**CẢNH BÁO:**
- Script này sẽ xóa và ghi lại toàn bộ bảng phân vùng trên thiết bị chỉ định. **Mọi dữ liệu trên thiết bị sẽ bị mất vĩnh viễn!**
- Chỉ sử dụng trên thiết bị test hoặc thiết bị đã backup toàn bộ dữ liệu.
- Luôn xác thực đường dẫn thiết bị (ví dụ: /dev/sda, /dev/nvme0n1) trước khi thao tác.
- Chạy script với quyền root (`sudo`).
- Không chạy trên máy chủ đang hoạt động hoặc chứa dữ liệu quan trọng.

**Các bước sử dụng:**
```bash
# 1. Hiển thị sơ đồ phân vùng (chỉ tham khảo, không thay đổi gì)
bash ab-partition-setup.sh layout

# 2. Tạo bảng phân vùng A/B (XÓA TOÀN BỘ DỮ LIỆU!)
bash ab-partition-setup.sh create /dev/sdX

# 3. Định dạng các phân vùng
bash ab-partition-setup.sh format /dev/sdX

# 4. Cài đặt GRUB bootloader
bash ab-partition-setup.sh grub /dev/sdX /mnt

# 5. Cài đặt công cụ chuyển đổi root A/B
bash ab-partition-setup.sh switcher /target/dir
```

**Lưu ý bảo mật:**
- Không truyền biến thiết bị từ input không kiểm soát.
- Script đã kiểm tra input, validate device, chống shell injection, log mọi thao tác và dừng khi có lỗi.
- Sau khi thao tác, kiểm tra lại phân vùng và boot thử nghiệm trước khi đưa vào sản xuất.

---

## AppArmor profile cho Shark CLI

Shark OS cung cấp sẵn profile AppArmor mẫu cho shark-cli tại:
```
/etc/apparmor.d/shark-cli
```

**Cách sử dụng:**
```bash
# Nạp profile (sau khi cài đặt hoặc cập nhật)
sudo apparmor_parser -r /etc/apparmor.d/shark-cli

# Kiểm tra trạng thái
aa-status | grep shark-cli

# Nếu muốn enforce (bắt buộc), đảm bảo profile ở chế độ enforce:
sudo aa-enforce /etc/apparmor.d/shark-cli
```

**Lưu ý:**
- Có thể tùy chỉnh rule cho phù hợp thực tế (ví dụ: cho phép network, hạn chế quyền ghi, ...)
- Nếu shark-cli thay đổi vị trí cài đặt, cần sửa lại path trong profile.

---

## Build Scripts

### build.sh
Main build script (được tạo trong setup).

```bash
bash build.sh
```

Xây dựng toàn bộ Shark OS ISO.

## Utilities

### create-overlay.sh
(Sẽ được tạo) - Tạo custom overlays.

### test-iso.sh
(Sẽ được tạo) - Test ISO bằng QEMU.

```bash
bash test-iso.sh dist/shark-os-*.iso
```

## CI/CD Scripts

Scripts được dùng trong GitHub Actions:
- Build automation
- Testing
- Release management

**Makefile**: dùng `make lint|test|clean` để chạy các tác vụ phổ biến.

Xem `.github/workflows/build.yml` để chi tiết.

## Development

Tạo script mới (áp dụng strict-mode):

```bash
#!/usr/bin/env bash
set -eEuo pipefail
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

# Your script here
```

Làm executable:
```bash
chmod +x scripts/my-script.sh
```

Kiểm tra lint (ShellCheck) trước commit:

```bash
# Local helper: sẽ sử dụng shellcheck nếu đã cài, hoặc Docker fallback nếu có daemon
bash scripts/ci/run-shellcheck.sh

# Syntax check
bash -n scripts/my-script.sh
```

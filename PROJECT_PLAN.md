# Kế hoạch hoàn thiện Shark OS

## 1. Quản lý người dùng & phân quyền
- Script/CLI cho useradd, userdel, passwd, groupadd, phân quyền file.
- Tích hợp xác thực PAM hoặc module auth riêng cho CLI.

## 2. Quản lý dịch vụ (Service Management)
- Bộ script quản lý dịch vụ (start/stop/restart/status) cho OpenRC.
- Tài liệu và ví dụ service custom (ví dụ: sharkd, agent, monitoring).

## 3. Quản lý gói & cập nhật (Package & Update Management)
- Script tạo, ký số, và publish gói APK (aports/core/community/shark-main).
- Script update hệ thống (kiểm tra, tải, xác thực, chuyển A/B, rollback).
- Tích hợp kiểm tra integrity (hash, signature) sau update.

## 4. Quản lý cấu hình (Configuration Management)
- Module CLI cho shark config (init, edit, validate, backup/restore).
- Schema validation cho file cấu hình YAML.
- Script tự động backup cấu hình định kỳ.

## 5. Quản lý log & giám sát (Logging & Monitoring)
- Script thu thập log hệ thống, ứng dụng, bảo mật (logrotate, forwarding).
- Tích hợp Prometheus Node Exporter, script push metrics/logs về server.

## 6. Quản lý mạng (Networking)
- Script cấu hình IP, bridge, VLAN, firewall (iptables/nftables).
- Module CLI cho shark network (list, set, test, reload).
- Script kiểm tra, khôi phục mạng khi lỗi.

## 7. Quản lý phân vùng & storage
- Script quản lý phân vùng động (add/remove/resize data, snapshot).
- Script kiểm tra, sửa lỗi, backup/restore phân vùng data.

## 8. Bảo mật & hardening
- Bộ profile AppArmor cho toàn bộ dịch vụ chính (k3s, podman, sshd, sharkd).
- Script kiểm tra, reload, enforce profile AppArmor.
- Script kiểm tra trạng thái hardening kernel/userland.

## 9. Tài liệu vận hành & khôi phục
- Tài liệu recovery, reset root password, rescue mode, backup/restore toàn hệ thống.
- Script tạo snapshot, rollback toàn bộ OS.

## 10. Tự động hóa & test
- Bộ test tích hợp (integration test) cho update, rollback, service, network, security.
- Script CI/CD tự động build, test, publish image/gói.

---

**Lưu ý:**
- Mỗi mục sẽ được triển khai lần lượt, bổ sung mã nguồn, script, tài liệu, và test tương ứng.
- Sau khi hoàn thành từng module, cập nhật lại file này để đánh dấu tiến độ.

---

## Tiến độ & Các bước tiếp theo (ngắn hạn)

**Hoàn thành:**
- User management scripts (add/del/passwd)
- Service management scripts (OpenRC wrapper)
- Package/update scripts (check/apply mock, signing demo)
- Configuration management (init/edit/validate/backup/restore)
- Logging & monitoring helpers (logrotate, forward)
- Networking helpers (set/test/reload)
- Storage helpers (add/remove/resize/snapshot)
- Security/hardening script (sysctl/apparmor checks)
- Recovery tools (reset-root, rescue, backup/restore)
- Integration test harness (basic checks)
- AppArmor sample for `shark-cli`

**Còn làm/ưu tiên tiếp theo:**
1. **Static analysis & linting**: Bật ShellCheck trong CI, sửa cảnh báo hiện có.
2. **AppArmor profiles**: Thêm profile cứng cho `k3s`, `podman`, `sshd`, `shark-service`.
3. **A/B update flow**: Triển khai thực tế cho `shark update apply` + verification + watchdog rollback; viết test QEMU cho kịch bản update/rollback.

**AppArmor work:**
- [x] Thêm profile mẫu cho `shark-cli`
- [x] Thêm profile mẫu cho `k3s` và `podman` (starter profiles)
- [ ] Tuning: review & harden profiles based on runtime observations
- [ ] Add CI job to validate profiles loadable (complain mode) and add tests that run in privileged environment / runner with AppArmor support
4. **Package repo & signing**: Tự động ký và publish APK vào repo nội bộ, tích hợp verification khi update.
5. **CI/CD & Tests**: Thêm SAST (CodeQL), dependency scanning, SBOM generation, và test matrix (x86_64 + aarch64) trong GitHub Actions.
6. **Hardening & Monitoring**: Tích hợp seccomp profiles, AppArmor enforce checks, alerting (Prometheus Alertmanager).
7. **Documentation**: Hoàn thiện Operational Runbook, Recovery Playbook, và Security Response Playbook.

**Đề xuất hành động ngay:**
- (1) Thêm ShellCheck vào pipeline và chạy trên toàn bộ scripts. (Khuyến nghị: block PR nếu có lỗi SC- warnings>=1).
- (2) Triển khai AppArmor profile cho `podman` và `k3s` (mẫu trong `overlays/base/etc/apparmor.d/`).
- (3) Tối ưu hoá hệ thống: tập trung centralize logging, add Makefile, add maintenance scripts, update pre-commit hooks để ngăn build artifacts. (Hoàn thành: central logging, Makefile, clean script, pre-commit)
- (4) Bắt tay vào `shark update apply` (phần thực tế) và viết test QEMU.

---

Nếu đồng ý với thứ tự ưu tiên trên, tôi sẽ: (A) bật ShellCheck vào CI và sửa cảnh báo hiện có, (B) tạo AppArmor profiles cho `k3s` và `podman`, (C) tối ưu hóa script & dọn dẹp repo (Makefile, common helpers, clean scripts, pre-commit), và (D) bắt triển khai `shark update apply` với test QEMU cho kịch bản cập nhật/rollback.

# Shark OS Security & Hardening Scripts

Các script kiểm tra, enforce, reload profile bảo mật cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-harden.sh` : Kiểm tra & hardening bảo mật (check, enforce, apparmor, kernel)

## Hướng dẫn sử dụng

### Kiểm tra trạng thái bảo mật
```bash
sudo ./shark-harden.sh check
```

### Áp dụng hardening kernel & sysctl
```bash
sudo ./shark-harden.sh enforce
```

### Reload toàn bộ profile AppArmor
```bash
sudo ./shark-harden.sh apparmor
```

### Kiểm tra kernel config hardening
```bash
sudo ./shark-harden.sh kernel
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/security_mgmt.log.
- Cần cài đặt AppArmor, kernel phải bật các option hardening.
- Kiểm tra kernel config thủ công nếu không có /proc/config.gz.

## TODO
- Bổ sung kiểm tra seccomp, capabilities, auditd.
- Tích hợp kiểm tra userland hardening.
- Viết test tự động cho các script này.

---

## AppArmor tuning & collection

This directory contains scripts to help tune AppArmor profiles for Shark OS.

- `check-apparmor.sh` — syntax/load checks (safe complain-mode load attempts).
- `collect-apparmor-denials.sh` — run workloads on a runner that supports AppArmor, collect dmesg/audit denials and run `aa-logprof` suggestions.

How to use (recommended on self-hosted runner with AppArmor enabled):

1. Ensure AppArmor and apparmor-utils are installed, and kernel supports AppArmor.
2. Place profiles under `/etc/apparmor.d/` and load them in complain mode:

   sudo apparmor_parser -r --complain /etc/apparmor.d/your-profile

3. Run the collection script:

   mkdir -p reports/apparmor
   sudo bash scripts/security/collect-apparmor-denials.sh

4. Inspect `reports/apparmor/*` for denials (dmesg/ausearch) and suggestions (`aa-logprof` output).

5. Use `aa-logprof` interactively to accept/reject suggested lines and iterate.

6. Once tuned, switch profile to enforce mode:

   sudo aa-enforce /etc/apparmor.d/your-profile

Notes:
- Running k3s and podman workloads may require additional capabilities or configuration on the runner.
- Use a disposable test VM to avoid impacting production systems.



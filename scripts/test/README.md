# Shark OS Automation & Integration Test Scripts

Các script tự động hóa kiểm thử tích hợp cho Shark OS, kiểm tra toàn diện các module cốt lõi.

## Danh sách script
- `shark-integration-test.sh` : Bộ test tích hợp (user, service, pkg, config, log, net, storage, security, recovery)

## Hướng dẫn sử dụng

### Chạy toàn bộ test tích hợp
```bash
sudo ./shark-integration-test.sh all
```

### Chạy test cho từng module
```bash
sudo ./shark-integration-test.sh <user|service|pkg|config|log|net|storage|security|recovery>
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log kết quả vào /var/log/shark/test_integration.log.
- Cần cài đặt đầy đủ các công cụ phụ thuộc (yq, logrotate, AppArmor, ...).
- Có thể mở rộng thêm test cho từng module chuyên sâu.

## TODO
- Bổ sung test cho update A/B thực tế.
- Tích hợp CI/CD tự động build, test, publish image/gói.
- Viết test bảo mật chuyên sâu (fuzz, pentest, privilege escalation).

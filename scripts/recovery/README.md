# Shark OS Recovery & Operation Scripts

Các script khôi phục hệ thống, reset root, backup/restore cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-recovery.sh` : Khôi phục hệ thống (reset-root, rescue, backup, restore)

## Hướng dẫn sử dụng

### Reset mật khẩu root
```bash
sudo ./shark-recovery.sh reset-root
```

### Vào rescue shell
```bash
sudo ./shark-recovery.sh rescue
```

### Backup hệ thống (etc, var, home)
```bash
sudo ./shark-recovery.sh backup
```

### Khôi phục hệ thống từ backup mới nhất
```bash
sudo ./shark-recovery.sh restore
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/recovery_mgmt.log.
- Backup chỉ là tar.gz cơ bản, production nên dùng giải pháp chuyên nghiệp.

## TODO
- Bổ sung snapshot/rollback toàn bộ OS (A/B).
- Tích hợp kiểm tra, khôi phục phân vùng boot.
- Viết test tự động cho các script này.

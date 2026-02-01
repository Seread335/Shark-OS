# Shark OS Configuration Management Scripts

Các script quản lý cấu hình hệ thống cho Shark OS, hỗ trợ init, edit, validate, backup/restore file cấu hình YAML.

## Danh sách script
- `shark-config.sh` : Quản lý cấu hình (init, edit, validate, backup, restore)

## Hướng dẫn sử dụng

### Khởi tạo file cấu hình mẫu
```bash
sudo ./shark-config.sh init
```

### Sửa file cấu hình
```bash
sudo ./shark-config.sh edit
```

### Kiểm tra hợp lệ YAML
```bash
sudo ./shark-config.sh validate
```

### Backup cấu hình
```bash
sudo ./shark-config.sh backup
```

### Khôi phục cấu hình từ backup mới nhất
```bash
sudo ./shark-config.sh restore
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/config_mgmt.log.
- Cần cài đặt `yq` để validate YAML.
- File cấu hình mặc định: /etc/shark/config.yml
- Backup lưu tại: /var/backups/shark-config/

## TODO
- Bổ sung schema validation nâng cao.
- Tích hợp tự động backup định kỳ.
- Viết test tự động cho các script này.

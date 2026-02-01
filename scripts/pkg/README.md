# Shark OS Package & Update Management Scripts

Các script quản lý cập nhật hệ thống, ký số gói APK cho Shark OS, hướng server-oriented, hỗ trợ A/B partition.

## Danh sách script
- `shark-pkg-update.sh` : Kiểm tra/cập nhật hệ thống (A/B, integrity, log)
- `shark-pkg-sign.sh`   : Ký số gói APK (demo, log)

## Hướng dẫn sử dụng

### Kiểm tra update
```bash
sudo ./shark-pkg-update.sh --check
```

### Áp dụng update (A/B)
```bash
sudo ./shark-pkg-update.sh --apply
```

### Ký số gói APK
```bash
sudo ./shark-pkg-sign.sh <apk-file> <private-key>
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/pkg_update.log hoặc pkg_sign.log.
- Cần bổ sung logic thực tế cho update A/B, ký số (hiện tại là khung mẫu an toàn).

## TODO
- Bổ sung script publish package lên repo.
- Tích hợp kiểm tra integrity thực tế (hash, signature).
- Viết test tự động cho các script này.

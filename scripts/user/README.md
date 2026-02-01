# Shark OS User Management Scripts

Các script quản lý user cơ bản cho Shark OS, đảm bảo an toàn, kiểm tra input, log đầy đủ.

## Danh sách script

- `shark-useradd.sh`  : Thêm user mới (tùy chọn group, shell, home)
- `shark-userdel.sh`  : Xóa user (xác nhận, log)
- `shark-passwd.sh`   : Đặt lại mật khẩu cho user

## Hướng dẫn sử dụng

### Thêm user mới
```bash
sudo ./shark-useradd.sh <username> [--group <group>] [--shell <shell>] [--home <dir>]
```

### Xóa user
```bash
sudo ./shark-userdel.sh <username>
```

### Đặt lại mật khẩu
```bash
sudo ./shark-passwd.sh <username>
```

## Lưu ý bảo mật
- Chỉ chạy script với quyền root.
- Script kiểm tra input, log mọi thao tác vào /var/log/shark/user_mgmt.log.
- Không dùng cho user hệ thống đặc biệt (root, daemon, ...).

## TODO
- Bổ sung script groupadd, groupdel, usermod.
- Tích hợp xác thực 2 lớp (2FA) cho CLI.
- Viết test tự động cho các script này.

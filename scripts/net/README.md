# Shark OS Networking Scripts

Các script quản lý mạng cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-net.sh` : Quản lý mạng (list, set, test, reload)

## Hướng dẫn sử dụng

### Liệt kê cấu hình mạng
```bash
sudo ./shark-net.sh list
```

### Đặt địa chỉ IP tĩnh cho interface
```bash
sudo ./shark-net.sh set <iface> <ip> <mask> <gateway>
# Ví dụ:
sudo ./shark-net.sh set eth0 192.168.1.10 24 192.168.1.1
```

### Kiểm tra kết nối mạng
```bash
sudo ./shark-net.sh test [target_ip]
# Mặc định target_ip là 8.8.8.8
```

### Reload dịch vụ mạng
```bash
sudo ./shark-net.sh reload
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/net_mgmt.log.
- Cần kiểm tra kỹ interface trước khi set IP để tránh mất kết nối SSH.

## TODO
- Bổ sung cấu hình VLAN, bridge, firewall.
- Tích hợp kiểm tra, khôi phục mạng tự động khi lỗi.
- Viết test tự động cho các script này.

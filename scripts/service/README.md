# Shark OS Service Management Scripts

Các script quản lý dịch vụ (OpenRC) cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-service.sh` : Quản lý dịch vụ OpenRC (start/stop/restart/status/enable/disable/list)

## Hướng dẫn sử dụng

### Liệt kê tất cả dịch vụ
```bash
sudo ./shark-service.sh list
```

### Quản lý dịch vụ
```bash
sudo ./shark-service.sh <start|stop|restart|status|enable|disable> <service>
```

Ví dụ:
```bash
sudo ./shark-service.sh start sshd
sudo ./shark-service.sh status k3s
sudo ./shark-service.sh enable podman
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/service_mgmt.log.
- Dịch vụ phải có file init OpenRC hợp lệ trong /etc/init.d/.

## TODO
- Bổ sung script tạo service mới (template OpenRC).
- Tích hợp kiểm tra health/service monitoring.
- Viết test tự động cho các script này.

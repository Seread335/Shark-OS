# Shark OS Logging & Monitoring Scripts

Các script quản lý log, logrotate, forwarding log cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-logrotate.sh`   : Quản lý logrotate cho log hệ thống
- `shark-log-forward.sh`: Forward log tới server tập trung (demo)

## Hướng dẫn sử dụng

### Quay vòng log (logrotate)
```bash
sudo ./shark-logrotate.sh
sudo ./shark-logrotate.sh --force  # ép quay vòng ngay
```

### Forward log tới server tập trung
```bash
sudo ./shark-log-forward.sh <server:port>
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/log_mgmt.log.
- Forward log chỉ là demo, nên dùng syslog-ng/rsyslog/loki cho production.
- File cấu hình logrotate: /etc/logrotate.d/shark

## TODO
- Bổ sung script thu thập metrics Prometheus.
- Tích hợp cảnh báo (alerting) khi log có lỗi nghiêm trọng.
- Viết test tự động cho các script này.

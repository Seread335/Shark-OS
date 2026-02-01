# Shark OS Storage Management Scripts

Các script quản lý phân vùng & storage cho Shark OS, tối ưu cho môi trường server-oriented.

## Danh sách script
- `shark-storage.sh` : Quản lý phân vùng (list, add, remove, resize, snapshot, restore)

## Hướng dẫn sử dụng

### Liệt kê phân vùng và dung lượng
```bash
sudo ./shark-storage.sh list
```

### Thêm phân vùng mới
```bash
sudo ./shark-storage.sh add <device> <mountpoint>
# Ví dụ:
sudo ./shark-storage.sh add /dev/sdb1 /mnt/data
```

### Xóa phân vùng (unmount)
```bash
sudo ./shark-storage.sh remove <mountpoint>
```

### Resize phân vùng
```bash
sudo ./shark-storage.sh resize <device> <new_size>
# Ví dụ:
sudo ./shark-storage.sh resize /dev/sdb1 20G
```

### Tạo snapshot phân vùng
```bash
sudo ./shark-storage.sh snapshot <device>
```

### Khôi phục từ snapshot
```bash
sudo ./shark-storage.sh restore <device> <snapshot_file>
```

## Lưu ý
- Chỉ chạy script với quyền root.
- Script log mọi thao tác vào /var/log/shark/storage_mgmt.log.
- Snapshot dùng dd, chỉ phù hợp cho test/lab, production nên dùng LVM/ZFS.

## TODO
- Bổ sung quản lý LVM, ZFS, Ceph client.
- Tích hợp kiểm tra, sửa lỗi phân vùng tự động.
- Viết test tự động cho các script này.

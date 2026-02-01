# Tài liệu Thiết kế Hệ điều hành Shark OS

---

## Mục lục

1. [Tóm tắt Điều hành](#1-tóm-tắt-điều-hành)
2. [Mục tiêu và Triết lý Thiết kế](#2-mục-tiêu-và-triết-lý-thiết-kế)
3. [Kiến trúc Hệ thống Cốt lõi](#3-kiến-trúc-hệ-thống-cốt-lõi)
4. [Tối ưu hóa Hiệu suất](#4-tối-ưu-hóa-hiệu-suất)
5. [Các Tính năng Chính](#5-các-tính-năng-chính)
6. [Bảo mật và Độ tin cậy](#6-bảo-mật-và-độ-tin-cậy)
7. [Chiến lược Triển khai](#7-chiến-lược-triển-khai-và-phát-triển)
8. [Phụ lục: Giải quyết Vấn đề](#phụ-lục)

---

## 1. Tóm tắt Điều hành (Executive Summary)

Shark OS là một hệ điều hành (HĐH) chuyên biệt, **hướng máy chủ (server-oriented)**, được xây dựng trên nền tảng Alpine Linux. Triết lý thiết kế cốt lõi của Shark OS là **nhẹ, nhanh, mạnh, và bảo mật**, tập trung vào việc cung cấp một môi trường tối ưu cho các tác vụ **container hóa, microservices, và điện toán biên (Edge Computing)** ở quy mô lớn. Bằng cách sử dụng **musl libc** và loại bỏ các thành phần không cần thiết, Shark OS đạt được kích thước image cơ bản cực kỳ nhỏ (dưới 50MB) và thời gian khởi động nhanh (dưới 5 giây), đồng thời tích hợp các công nghệ tiên tiến như **eBPF** và **Podman** để đảm bảo hiệu suất và bảo mật vượt trội cho các ứng dụng hiện đại.

## 2. Mục tiêu và Triết lý Thiết kế (Goals and Design Philosophy)

Mục tiêu chính của Shark OS là trở thành HĐH nền tảng được lựa chọn cho các môi trường sản xuất yêu cầu hiệu suất cao và độ tin cậy tuyệt đối.

### 2.1 Các Tiêu chí Thiết kế
| --- | --- | --- |
| **Minimalism & Lightweight** | Xây dựng từ Alpine Linux, sử dụng musl libc, và loại bỏ mọi package không cần thiết. Image cơ bản dưới 50MB (uncompressed). | Giảm thiểu bề mặt tấn công (attack surface), tiết kiệm tài nguyên, và tăng tốc độ triển khai. |
| **Performance & Speed** | Tối ưu hóa kernel, sử dụng I/O bất đồng bộ, và hỗ trợ các công nghệ mạng tốc độ cao như DPDK và eBPF. | Đảm bảo độ trễ thấp (dưới 1ms cho internal calls) và thông lượng cao (trên 10Gbps). |
| **Security First** | Rootfs **chỉ đọc (read-only)**, sử dụng **AppArmor** cho kiểm soát truy cập bắt buộc, và ưu tiên các công cụ không daemon như **Podman**. | Tăng cường bảo mật hệ thống cốt lõi và cô lập workload. |
| **Scalability** | Hỗ trợ mở rộng ngang (horizontal scaling) với các công cụ clustering và orchestration tích hợp sẵn. | Dễ dàng quản lý hàng nghìn node trong môi trường Cloud và Edge. |
| **Immutability** | Áp dụng mô hình **A/B Partitioning** cho cập nhật hệ thống. | Đảm bảo khả năng rollback tức thì và độ tin cậy cao cho các bản cập nhật. |

### 2.2 Điểm yếu và Rủi ro (Weaknesses and Risks)

Việc theo đuổi triết lý tối giản và sử dụng các công nghệ thay thế (như musl libc và OpenRC) mang lại lợi ích về hiệu suất và kích thước, nhưng cũng đi kèm với những rủi ro và điểm yếu cần được nhận thức sớm:

| Rủi ro | Mô tả Chi tiết | Giải pháp Giảm thiểu |
| --- | --- | --- |
| **OpenRC vs. Systemd** | Mặc dù OpenRC nhẹ, việc tích hợp các hệ thống phức tạp như Kubernetes (full distribution) hoặc Service Mesh (Istio) có thể dẫn đến chi phí bảo trì cao do sự khác biệt về API và giả định của các công cụ bên thứ ba về sự tồn tại của systemd. Rủi ro này chủ yếu nằm ở **nhân lực vận hành** (tìm kiếm kỹ sư có kinh nghiệm OpenRC + Kubernetes). | **Định vị rõ ràng**: Shark OS được tối ưu hóa cho **K3s + Cilium** (sử dụng ít tính năng systemd hơn). Hỗ trợ Kubernetes full/Istio được coi là **best-effort support** (hỗ trợ tốt nhất có thể), yêu cầu đội ngũ vận hành có chuyên môn cao. |
| **Tương thích musl libc** | Việc sử dụng `musl` thay vì `glibc` có thể gây ra lỗi tương thích với một số binary thương mại hoặc các ứng dụng phức tạp, ngay cả khi có lớp `gcompat`. Việc debug core dump trên `musl` cũng khó khăn hơn. | **Khuyến nghị nghiêm ngặt**: 100% workload của người dùng nên được **container hóa**. Cung cấp danh sách **"known incompatible software"** và hướng dẫn biên dịch lại hoặc sử dụng các binary được biên dịch tĩnh. |
| **Phạm vi Tính năng Quá rộng** | Việc tích hợp quá nhiều công cụ phức tạp (Ceph, Corosync, Istio, Vault, Falco, Loki, Prometheus) vào một HĐH tối giản có thể làm tăng độ phức tạp và mâu thuẫn với triết lý "Minimalism". | **Phân lớp Hệ thống**: Tách biệt rõ ràng các tính năng thành các lớp (Tier) để người dùng có thể tùy chọn cài đặt, giảm thiểu "bloat" cho Base OS. |

---

## 3. Kiến trúc Hệ thống Cốt lõi (Core System Architecture)

Kiến trúc của Shark OS được thiết kế để tối đa hóa hiệu suất và giảm thiểu chi phí vận hành.

### 3.1 Kernel và Base System

Shark OS sử dụng kernel Linux được tùy chỉnh từ Alpine Linux, tập trung vào các tính năng cần thiết cho môi trường server và container:

- **Tối ưu hóa Kernel**: Kích hoạt **cgroup v2** để quản lý tài nguyên container hiệu quả hơn. Hỗ trợ **eBPF** (Extended Berkeley Packet Filter) với **BTF (BPF Type Format)** để tăng cường khả năng quan sát (observability) và mạng hiệu suất cao. Tùy chọn tích hợp **PREEMPT_RT** cho các phiên bản Edge yêu cầu độ trễ thời gian thực.

- **musl libc**: Sử dụng musl libc thay vì glibc để giảm kích thước và dependency. Để giải quyết vấn đề tương thích với các ứng dụng yêu cầu glibc, Shark OS sẽ cung cấp một lớp tương thích **gcompat** hoặc hướng dẫn sử dụng các binary được biên dịch tĩnh.

- **Quản lý Bộ nhớ**: Sử dụng **zswap** (thay vì chỉ zram) để nén và quản lý bộ nhớ swap hiệu quả hơn, giảm thiểu I/O đĩa.

### 3.2 Init System và Quản lý Package

| Thành phần | Công nghệ | Lý do Lựa chọn |
| --- | --- | --- |
| **Init System** | **OpenRC** | Nhẹ hơn systemd, phù hợp với triết lý Alpine. Cung cấp các script tương thích để hỗ trợ các ứng dụng dựa trên systemd. |
| **Package Manager** | **apk** | Trình quản lý package mặc định của Alpine, nhanh và hiệu quả. Repository tùy chỉnh chỉ chứa các package tối thiểu và đã được kiểm định. |
| **File System** | **ext4** (mặc định) / **overlayfs** | ext4 cho độ ổn định. overlayfs cho các lớp container. Rootfs là **read-only** để tăng cường bảo mật và tốc độ. |
| **Công cụ Cấu hình** | **Shark CLI** | Lớp trừu tượng (abstraction layer) hợp nhất để quản lý cấu hình, cập nhật, và vòng đời cluster (xem Mục 3.3). |

---

## 4. Tối ưu hóa Hiệu suất (Performance Optimization)

Shark OS được tinh chỉnh để đạt hiệu suất tối đa trong các môi trường điện toán đám mây và biên.

### 4.1 Tối ưu hóa I/O và Mạng

- **I/O**: Sử dụng các hoạt động I/O bất đồng bộ. Tối ưu hóa I/O đĩa bằng cách sử dụng **tmpfs** cho `/tmp` và `/var/run`.

- **Mạng**: Hỗ trợ **DPDK (Data Plane Development Kit)** và **SR-IOV** thông qua các module kernel tùy chỉnh để xử lý hàng triệu gói tin mỗi giây, giảm tải CPU cho các tác vụ mạng.

- **Độ trễ**: Kernel được tinh chỉnh để đạt độ trễ mạng (latency) dưới 1ms cho các cuộc gọi nội bộ (internal calls) trong cluster.

### 4.2 Khả năng Mở rộng và Đồng thời (Scalability and Concurrency)

- **Clustering**: Các công cụ HA như Corosync/Pacemaker được chuyển vào lớp **Enterprise Add-ons** (xem Mục 5.4). Base OS chỉ cung cấp các kernel module và thư viện cơ bản để hỗ trợ.

- **Giới hạn Hệ thống**: Tăng giới hạn mặc định của kernel cho các thông số quan trọng như `max open files` (>1M) và `TCP backlog` (>10K) để xử lý lượng kết nối đồng thời lớn.

- **Giám sát**: Tích hợp sẵn **Prometheus Node Exporter** để cung cấp các chỉ số hiệu suất hệ thống theo thời gian thực.

---

## 5. Các Tính năng Chính (Key Features)

Shark OS cung cấp các tính năng cốt lõi cho các trường hợp sử dụng hiện đại.

### 5.1 Containerization và Microservices

| Tính năng | Công nghệ | Mô tả |
| --- | --- | --- |
| **Container Runtime** | **Podman & Buildah** | Mặc định sử dụng **rootless** và **daemon-less** để tăng cường bảo mật và giảm overhead so với Docker. Tương thích OCI. |
| **Orchestration** | **K3s** (mặc định) / **Kubernetes** | **Tối ưu hóa cho K3s** (lightweight, Edge). Hỗ trợ Kubernetes full được coi là **best-effort support** (xem Mục 2.3). |
| **Service Mesh** | **Istio** (tùy chọn) | Thuộc lớp **Enterprise Add-ons** (xem Mục 5.4). Hỗ trợ cấu hình Istio cho các dịch vụ microservices phức tạp. |
| **Networking** | **Cilium** (eBPF-based) | CNI (Container Network Interface) sử dụng eBPF để thực thi chính sách mạng và khám phá dịch vụ (service discovery) với độ trễ cực thấp. |
| **Logging** | **Loki Agent** | Thuộc lớp **Enterprise Add-ons** (xem Mục 5.4). Tích hợp agent của Loki để thu thập và tổng hợp log phân tán. |

### 5.2 Điện toán Đám mây và Biên (Cloud and Edge Computing)

- **Cloud Native**: Hỗ trợ driver và cấu hình native cho các nhà cung cấp đám mây lớn (AWS EC2, GCP Compute, Azure VMs) thông qua **cloud-init** tùy chỉnh.

- **Edge Computing**: Hỗ trợ kiến trúc **ARM64** và **x86_64**. K3s được cấu hình để boot nhanh vào chế độ cluster. Hỗ trợ khả năng hoạt động ngoại tuyến (offline capabilities) với caching cục bộ cho images và dữ liệu.

- **Secret Management**: Hỗ trợ tích hợp với các giải pháp quản lý bí mật như **HashiCorp Vault** (thuộc lớp Enterprise Add-ons). Base OS chỉ cung cấp các thư viện cần thiết.

### 5.3 Lưu trữ và Mạng

- **Lưu trữ Phân tán**: Shark OS được định vị là **Ceph-ready client**. Tích hợp các công cụ Ceph Client (`ceph-common`) tối ưu để kết nối và sử dụng các cluster Ceph có sẵn (RBD, CephFS).

- **Lưu trữ Tại chỗ**: Hỗ trợ **ZFS on Linux** và **LVM** cho các cấu hình lưu trữ cục bộ hiệu suất cao.

- **Mạng Zero Trust**: Tích hợp **WireGuard** ở cấp độ kernel để thiết lập các kết nối VPN an toàn, hiệu suất cao giữa các node.

### 5.4 Phân lớp Hệ thống (System Tiering)

Để cân bằng giữa triết lý tối giản và nhu cầu doanh nghiệp, Shark OS được phân lớp rõ ràng thành ba cấp độ, cho phép người dùng tùy chọn cài đặt các thành phần phức tạp:

| Lớp (Tier) | Mô tả | Các Thành phần Chính |
| --- | --- | --- |
| **1. Base OS (Core)** | Cốt lõi HĐH tối thiểu, chỉ chứa các thành phần cần thiết để boot, quản lý mạng cơ bản, và chạy container runtime. | Kernel (eBPF, cgroup v2), musl libc, OpenRC, Podman/Buildah, Shark CLI, Prometheus Node Exporter. |
| **2. Container Platform** | Các công cụ cần thiết để vận hành một cluster container hiệu suất cao. | K3s (hoặc Kubernetes full), Cilium CNI, ZFS/LVM support. |
| **3. Enterprise Add-ons** | Các công cụ phức tạp, yêu cầu tài nguyên và chuyên môn cao, dành cho môi trường sản xuất quy mô lớn (Large-Scale Production). | Corosync/Pacemaker (HA), Istio (Service Mesh), HashiCorp Vault (Secret Management), Falco (Runtime Security), Loki Agent (Distributed Logging). |

---

## 6. Bảo mật và Độ tin cậy (Security and Reliability)

### 6.1. Bảo mật (Security)

- **Kiểm soát Truy cập Bắt buộc (MAC)**: Sử dụng **AppArmor** profiles cho mọi dịch vụ để cô lập và hạn chế quyền truy cập.

- **Kernel Hardening**: Áp dụng các tùy chọn biên dịch kernel tăng cường bảo mật như `CONFIG_FORTIFY_SOURCE` và các biện pháp chống tấn công ROP/JOP.

- **Cập nhật Tự động**: Sử dụng cron job của `apk` để tự động cập nhật các bản vá bảo mật quan trọng, kết hợp với mô hình **A/B Partitioning** để đảm bảo khả năng rollback an toàn (xem Mục 6.3).

- **Runtime Security**: Hỗ trợ tích hợp với các công cụ phát hiện xâm nhập runtime như **Falco** (thuộc lớp Enterprise Add-ons). Base OS chỉ cung cấp các hook eBPF cần thiết.

### 6.2 Độ tin cậy (Reliability)

- **Ghi nhật ký (Logging)**: Sử dụng **Journald** với cấu hình nén để quản lý log hiệu quả (xem Mục 6.2.1).

#### 6.2.1 Logging với Journald trên Rootfs Read-Only

Shark OS sử dụng **Journald** (từ `systemd-shim` hoặc một implementation tương đương) thay vì các giải pháp syslog truyền thống như `syslog-ng` hoặc `rsyslog` vì các lý do sau:

*   **Metadata và Cấu trúc**: Journald lưu trữ log dưới dạng binary có cấu trúc, cho phép truy vấn và phân tích log hiệu quả hơn, đặc biệt quan trọng trong môi trường container/microservices.
*   **Nén và Hiệu suất**: Khả năng nén log tốt hơn và hiệu suất ghi log cao hơn so với log text thuần.
*   **Tích hợp**: Dễ dàng tích hợp với các công cụ giám sát hiện đại như Loki Agent (thuộc Enterprise Add-ons).

**Xử lý Log Persistence trên Rootfs Read-Only**:

Vì Rootfs là **chỉ đọc (Read-Only)**, log sẽ được ghi vào phân vùng **Data (RW)** (thường là `/var/log/journal`) để đảm bảo tính bền vững. Trong trường hợp phân vùng Data không khả dụng, log sẽ được ghi vào **tmpfs** (RAM) để đảm bảo không làm hỏng hệ thống, nhưng sẽ bị mất khi reboot.

- **Giám sát Hệ thống**: Kích hoạt **watchdog kernel module** để tự động khởi động lại hệ thống khi phát hiện treo (hang).

- **Sao lưu**: Tích hợp các công cụ sao lưu gia tăng như **restic** để tạo snapshot hệ thống.

### 6.3 Cơ chế Cập nhật Bất biến (Immutable Update Mechanism)

Shark OS sử dụng mô hình **A/B Partitioning** để đảm bảo cập nhật hệ thống an toàn và có thể rollback tức thì.

| Thành phần | Mô tả |
| :--- | :--- |
| **Disk Layout** | Chia ổ đĩa thành 4 phân vùng chính: **Bootloader**, **Data** (RW), **Root A** (RO), và **Root B** (RO). Phân vùng **Data** chứa các dữ liệu thay đổi (logs, container images, cấu hình) và được mount ở `/var/lib/shark`. |
| **Bootloader** | Sử dụng **GRUB** hoặc **systemd-boot** (tùy kiến trúc) để quản lý việc chọn boot giữa Root A và Root B. Bootloader được cấu hình để tự động chuyển về phân vùng Root cũ nếu phân vùng Root mới không boot thành công (rollback tự động). |
| **Quy trình Cập nhật** | 1. Hệ thống đang chạy trên Root A. 2. Lệnh `shark update apply` tải image mới và ghi vào Root B. 3. Bootloader được cấu hình lại để boot vào Root B. 4. Hệ thống khởi động lại. Nếu Root B boot thành công, Root A trở thành phân vùng dự phòng. Nếu thất bại, Bootloader tự động chuyển về Root A. |
| **Phạm vi Cập nhật** | Cơ chế A/B chỉ áp dụng cho **Base OS (Tier 1)**. Các thành phần **Container Platform (Tier 2)** và **Enterprise Add-ons (Tier 3)** được quản lý độc lập thông qua các công cụ container (K3s, Helm) và được lưu trữ trên phân vùng **Data** (RW), cho phép cập nhật độc lập mà không cần reboot OS. |

---

## 7. Chiến lược Triển khai và Phát triển (Deployment and Development Strategy)

- **Quy trình Build**: Sử dụng **Alpine's abuild** để tạo custom ISO/image. Toàn bộ quy trình được tự động hóa qua **GitHub Actions** cho CI/CD.

- **Cài đặt**: Cung cấp tùy chọn cài đặt một lệnh (one-command install) qua netboot hoặc ISO. Cấu hình hệ thống được quản lý thông qua các tệp **YAML** (tương tự Ansible Playbook) để hỗ trợ **Configuration as Code**.

- **Cộng đồng và Hỗ trợ**: Phát hành dưới giấy phép **GPL** (Open-source). Tài liệu chi tiết được duy trì trên GitHub. Cung cấp hỗ trợ doanh nghiệp thông qua các module trả phí (ví dụ: các công cụ quản lý tập trung, hỗ trợ SLA).

---

## Phụ lục: Giải quyết Vấn đề và Cải tiến

| Vấn đề trong Ý tưởng Ban đầu | Phân tích và Giải pháp Cải tiến |
| --- | --- |
| **Tích hợp Ceph** (full node) | **Vấn đề**: Việc chạy Ceph full node trên musl libc và Alpine là phức tạp và làm tăng đáng kể kích thước image. **Giải pháp**: Định vị Shark OS là **Ceph-ready client**. Chỉ tích hợp các công cụ client (`ceph-common`) được tối ưu hóa để kết nối với các cluster Ceph hiện có, giữ image nhẹ và tập trung vào vai trò HĐH nền tảng. |
| **Init System** (systemd-lite/OpenRC) | **Vấn đề**: Mặc dù OpenRC nhẹ, nhiều ứng dụng container/microservices hiện đại giả định sự tồn tại của systemd APIs. **Giải pháp**: Chọn **OpenRC** làm mặc định. Cung cấp các **shim layers** hoặc **wrapper scripts** để mô phỏng các API cần thiết của systemd cho các công cụ orchestration như K3s/Kubernetes, đảm bảo khả năng tương thích mà vẫn giữ được sự gọn nhẹ. |
| **Tương thích musl libc** | **Vấn đề**: musl libc không tương thích ABI với glibc, gây khó khăn cho việc chạy các binary thương mại hoặc các công cụ phức tạp. **Giải pháp**: Tích hợp sẵn **gcompat** hoặc một lớp tương thích tương tự. Khuyến khích sử dụng các binary được biên dịch tĩnh hoặc các package được đóng gói lại cho musl. |
| **Tối ưu hóa Kernel** | **Vấn đề**: Ý tưởng ban đầu còn thiếu các chi tiết cụ thể về tối ưu hóa cho Edge/Real-time. **Giải pháp**: Bổ sung tùy chọn **PREEMPT_RT** cho các workload Edge cần độ trễ cực thấp và tích hợp **zswap** để quản lý bộ nhớ hiệu quả hơn. |

---

## 8. Tài liệu Tham khảo (References)

Trong một tài liệu thiết kế thực tế, các nguồn sau sẽ được trích dẫn để hỗ trợ các tuyên bố kỹ thuật:

- [1] Alpine Linux Official Documentation (Quy trình build, abuild, apk).

- [2] Linux Kernel Documentation (cgroup v2, eBPF, PREEMPT_RT).

- [3] Cilium Project Documentation (Tích hợp eBPF, CNI).

- [4] Podman and Buildah Documentation (Triết lý rootless container).

- [5] Ceph Project Documentation (Yêu cầu client/server).

- [6] OpenRC Documentation (So sánh với systemd).

- [7] HashiCorp Vault Documentation (Quản lý bí mật).


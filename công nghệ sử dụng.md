Để xây dựng (build) Shark OS từ nền tảng Alpine Linux, chúng ta sẽ sử dụng bộ công cụ tiêu chuẩn của Alpine nhưng được cấu hình tùy chỉnh để phù hợp với kiến trúc Shark OS. Dưới đây là các công cụ chính:
1. Bộ công cụ Build chính (Core Build Tools)
abuild: Công cụ chính của Alpine để xây dựng các gói phần mềm (.apk). Chúng ta sẽ sử dụng nó để đóng gói các thành phần tùy chỉnh của Shark OS.
aports: Kho lưu trữ các công thức build (APKBUILDs). Shark OS sẽ có một nhánh aports riêng chứa các cấu hình kernel và package tùy chỉnh.
mkimage: Script của Alpine để tạo ISO image. Chúng ta sẽ tạo một profile riêng (ví dụ: mkimg.shark.sh) để định nghĩa các thành phần có trong image.
2. Xây dựng Kernel tùy chỉnh (Custom Kernel Build)
Chúng ta không dùng kernel mặc định mà build lại kernel để tối ưu:
Cấu hình: Bật CONFIG_DEBUG_INFO_BTF=y (cho eBPF), cgroup v2, và tích hợp PREEMPT_RT.
Toolchain: Sử dụng gcc và musl-dev trên môi trường Alpine để đảm bảo tính tương thích tuyệt đối.
3. Tự động hóa và CI/CD (Automation)
GitHub Actions / GitLab CI: Tự động hóa quy trình build mỗi khi có thay đổi trong mã nguồn.
Docker/Podman: Sử dụng container Alpine làm môi trường build sạch (clean build environment) để tránh xung đột với hệ thống host.
4. Công cụ tạo Image và Phân vùng (Imaging & Partitioning)
xorriso & squashfs-tools: Để nén hệ thống file và tạo file ISO bootable.
Shark Build Scripts: Các script tùy chỉnh để thực hiện việc chia phân vùng A/B tự động khi cài đặt và cấu hình Bootloader (GRUB/systemd-boot).
Tóm lại: Quy trình sẽ là: Sửa APKBUILD (trong aports) -> Build Package (bằng abuild) -> Tạo ISO (bằng mkimage với profile shark).
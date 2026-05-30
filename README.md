# 🐳 Xpenology (Virtual-DSM) Docker Project

Dự án triển khai hệ điều hành NAS **Synology DiskStation Manager (DSM 7.2)** ảo hóa thông qua Docker, sử dụng công nghệ tăng tốc phần cứng **KVM** trực tiếp từ CPU Intel Core i5-12600KF trên nền tảng hệ điều hành Ubuntu Server 24.04.

---

## 📌 1. Thông Tin Dịch Vụ & Đăng Nhập

* **Địa chỉ truy cập:** [https://nas.nhotin.space](https://nas.nhotin.space)
* **Cổng dịch vụ (Local Port):** `5000` (HTTP) / `5001` (HTTPS)
* **Cơ chế xác thực:** Proxy qua Nginx Server & Cloudflare CDN (Mã hóa SSL Wildcard `*.nhotin.space`).
* **Tài khoản quản trị:** Được lưu trữ bảo mật cục bộ trong tệp `.env` trên máy chủ (Không lưu trữ công khai, tệp `.env` được cấu hình loại trừ trong `.gitignore` để tránh bị commit lên GitHub).


---

## 🛠️ 2. Quản Lý Docker Container

Thư mục làm việc: `/home/nhotin/svman/xpenology`

* **Khởi chạy dịch vụ (Chạy ngầm):**
  ```bash
  docker compose up -d
  ```
* **Dừng dịch vụ:**
  ```bash
  docker compose down
  ```
* **Xem logs hoạt động thời gian thực:**
  ```bash
  docker logs -f xpenology-dsm
  ```
* **Kiểm tra trạng thái sức khỏe container:**
  ```bash
  docker ps -a --filter name=xpenology-dsm
  ```

---

## 🔀 3. Cấu Hình Nginx Reverse Proxy (Không giới hạn data)

Tệp cấu hình hệ thống: `/etc/nginx/sites-available/nas.nhotin.space.conf`
Tệp cấu hình liên kết: `/etc/nginx/sites-enabled/nas.nhotin.space.conf`

### Các tham số tối ưu hóa đặc biệt đã cấu hình:
* **`client_max_body_size 0;`**: Vô hiệu hóa giới hạn dung lượng tải lên của Nginx, cho phép bạn upload tệp tin dung lượng lớn không giới hạn.
* **Hỗ trợ WebSocket:** 
  ```nginx
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  ```
  Giúp giao diện DSM đồng bộ dữ liệu thời gian thực mượt mà (biểu đồ CPU/RAM, tiến trình copy file...).
* **`proxy_buffering off;`**: Tắt bộ đệm trung gian để dữ liệu truyền tải trực tiếp từ người dùng đến NAS với tốc độ tối đa của đường truyền.
* **Thời gian chờ kết nối (`proxy_read_timeout 36000s`):** Đảm bảo kết nối không bị ngắt quãng khi truyền các tệp dung lượng cực lớn kéo dài nhiều giờ.

---

## 🌐 4. Hệ Thống DDNS Tự Động Cập Nhật IP

Dịch vụ sử dụng script Cloudflare API DDNS để tự động đồng bộ IP động của nhà mạng lên Cloudflare cho subdomain `nas.nhotin.space`.

* **Thư mục quản lý DDNS:** `/home/nhotin/svman/cloudflare`
* **Biến cấu hình bản ghi (`.env`):**
  ```env
  CF_RECORD_ID_NAS=26d84f4f39d912c93e30f1f990c128d9
  ```
* **Script thực thi:** `/home/nhotin/svman/cloudflare/update_ip.sh`
* **Hoạt động:** Script được kích hoạt tự động qua **Cronjob** hệ thống. Khi phát hiện IP WAN thay đổi, script sẽ cập nhật bản ghi DNS của `nas.nhotin.space` cùng các subdomain khác lên Cloudflare hoàn toàn tự động.

---

*Tài liệu được khởi tạo và cập nhật thành công ngày 30/05/2026 bởi Antigravity.*

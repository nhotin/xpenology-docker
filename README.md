# 🐳 Xpenology (Virtual DSM) Docker Project

Triển khai hệ điều hành NAS Synology DiskStation Manager (DSM) dưới dạng máy ảo chạy trong môi trường Docker, sử dụng KVM Hardware Virtualization để đạt hiệu năng gần với phần cứng vật lý.

---

# 📌 1. Tổng Quan Dịch Vụ

Hệ thống cung cấp các tính năng:

* Quản lý tập tin tập trung.
* Chia sẻ dữ liệu nội bộ và từ xa.
* Đồng bộ hóa dữ liệu đa thiết bị.
* Sao lưu và phục hồi dữ liệu.
* Quản lý người dùng và phân quyền truy cập.
* Mở rộng thông qua hệ sinh thái ứng dụng DSM.

Dịch vụ được công bố thông qua:

* Reverse Proxy.
* HTTPS/TLS Encryption.
* Dynamic DNS (DDNS).
* CDN hoặc DNS Proxy (tùy kiến trúc triển khai).

---

# 🛠️ 2. Quản Lý Docker

Khởi động dịch vụ:

```bash
docker compose up -d
```

Dừng dịch vụ:

```bash
docker compose down
```

Khởi động lại:

```bash
docker compose restart
```

Xem logs:

```bash
docker logs -f <container-name>
```

Kiểm tra trạng thái container:

```bash
docker ps -a
```

---

# 🔀 3. Reverse Proxy

Hệ thống được triển khai phía sau Reverse Proxy nhằm:

* Hỗ trợ HTTPS.
* Hỗ trợ WebSocket.
* Cân bằng tải và tối ưu hiệu năng.
* Quản lý chứng chỉ SSL/TLS.
* Công bố dịch vụ qua tên miền thay vì địa chỉ IP.

Các tối ưu thường được áp dụng:

* Upload file dung lượng lớn.
* Tăng thời gian timeout cho các phiên truyền dữ liệu kéo dài.
* Tắt buffering trong các tác vụ yêu cầu truyền tải thời gian thực.
* Chuyển tiếp đầy đủ các header cần thiết cho DSM.

---

# 🌐 4. Dynamic DNS (DDNS)

Hệ thống hỗ trợ cơ chế DDNS nhằm:

* Tự động cập nhật địa chỉ IP WAN.
* Duy trì khả năng truy cập qua tên miền cố định.
* Giảm nhu cầu cấu hình thủ công khi IP thay đổi.

Việc cập nhật DNS có thể được thực hiện thông qua:

* API của nhà cung cấp DNS.
* Script tự động.
* Scheduled Tasks hoặc Cron Jobs.

---

# 🔒 5. Bảo Mật

Khuyến nghị:

* Sử dụng HTTPS bắt buộc.
* Bật xác thực hai lớp (2FA).
* Giới hạn quyền truy cập theo nguyên tắc tối thiểu.
* Cập nhật DSM và các package định kỳ.
* Theo dõi nhật ký truy cập và hoạt động hệ thống.
* Sao lưu dữ liệu và cấu hình thường xuyên.

Không lưu trữ thông tin xác thực, khóa API hoặc dữ liệu nhạy cảm trong mã nguồn hoặc tài liệu công khai.

---

# 📦 6. Thành Phần Hệ Thống

* Docker Engine
* Docker Compose
* Virtual DSM
* KVM Virtualization
* Reverse Proxy
* DNS/DDNS Service
* SSL/TLS Certificate
* Monitoring & Logging (tùy chọn)

---

# 📄 Ghi Chú

Tài liệu này mô tả kiến trúc và quy trình vận hành ở mức tổng quát. Các thông tin triển khai cụ thể như tên miền, địa chỉ máy chủ, thông tin xác thực, khóa API và cấu hình nội bộ cần được quản lý riêng trong môi trường vận hành.

---

# ⚡ 7. Lưu trữ Phân cấp (Storage Tiering - SSD / HDD)

Do nhân kernel của Virtual-DSM trong môi trường ảo hóa không hỗ trợ trực tiếp tính năng SSD Cache của Synology (dễ gây lỗi treo đĩa), hệ thống đã được thiết lập theo phương án **Manual Storage Tiering** (Lưu trữ phân cấp thủ công) tối ưu:

* **Volume 1 (SSD Kingmax - 219GB):** Dùng làm phân vùng chính chạy hệ điều hành DSM + lưu trữ nóng (**Hot Tier**). Hệ điều hành chạy trên SSD giúp giao diện mượt mà và tốc độ phản hồi cực nhanh.
* **Volume 2 (HDD - 440GB):** Dùng làm phân vùng lưu trữ lâu dài (**Cold Tier**).

### 🔄 Cơ chế hoạt động:
* Tệp mới tải lên hoặc các tệp đang làm việc thường xuyên sẽ được lưu trên SSD (Volume 1) thông qua thư mục chia sẻ tên là `hot-store`.
* Một script chạy tự động hàng đêm thông qua **Task Scheduler** của DSM sẽ quét thư mục `hot-store` này. Các tệp không được truy cập quá **90 ngày** sẽ được tự động chuyển sang thư mục `cold-store` trên HDD (Volume 2) để giải phóng dung lượng cho SSD.

### 🛠️ Thiết lập trên hệ thống:

1. **Thư mục chia sẻ (Shared Folder) - Đã được tạo sẵn:**
   * Thư mục `hot-store` lưu trên **Volume 1** (SSD).
   * Thư mục `cold-store` lưu trên **Volume 2** (HDD).
   *(Bạn không cần tạo lại các thư mục này nữa).*

2. **Thiết lập Script chạy tự động (Task Scheduler):**
   * Đăng nhập Web DSM (`https://nas.nhotin.space`).
   * Vào **Control Panel** > **Task Scheduler**.
   * Chọn **Create** > **Scheduled Task** > **User-defined script**.
   * Phần **General**:
     * **Task:** `Storage Tiering`
     * **User:** `root`
   * Phần **Schedule**:
     * Thiết lập chạy hàng ngày (Daily), ví dụ lúc `02:00 AM`.
   * Phần **Task Settings**:
     * Trong ô **Run command**, nhập:
       ```bash
       /bin/bash /volume1/scripts/storage_tiering.sh
       ```
     * Bạn có thể chọn gửi email báo cáo khi có lỗi hoặc khi chạy xong ở phần Send run details.
   * Nhấn **OK** để lưu lại.

3. **Cách chạy thử nghiệm:**
   * Bạn có thể chọn Task `Storage Tiering` vừa tạo và bấm nút **Run** để chạy thử ngay lập tức.
   * Kết quả chạy (log) sẽ được lưu tại file `/volume1/scripts/tiering_run.log`.


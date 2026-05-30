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

Do nhân kernel của Virtual-DSM trong môi trường ảo hóa không hỗ trợ trực tiếp tính năng SSD Cache của Synology (dễ gây lỗi treo đĩa), hệ thống được thiết kế theo phương án **Manual Storage Tiering** (Lưu trữ phân cấp thủ công) tối ưu:

* **Volume 1 (SSD - Hot Tier):** Dùng để cài đặt hệ điều hành DSM và làm tầng lưu trữ nóng. Hệ điều hành chạy trên SSD giúp giao diện mượt mà và tốc độ phản hồi cực nhanh.
* **Volume 2 (HDD - Cold Tier):** Dùng làm phân vùng lưu trữ lớn lâu dài, tiết kiệm chi phí.

---

### 🔄 Quy trình Hoạt động Tự động

#### 1. Quy trình làm việc hàng ngày (Máy tính ➡️ SSD)
* Bất cứ khi nào bạn tạo mới, chỉnh sửa, hoặc sao chép file vào thư mục đồng bộ **`hot-store`** trên máy tính của mình.
* Ứng dụng **Synology Drive Client** ngầm chạy trên máy tính sẽ tự động đồng bộ các file này lên NAS.
* Dữ liệu được ghi thẳng vào phân vùng **SSD (Volume 1)** của NAS thông qua thư mục chia sẻ `/volume1/hot-store/`. Do sử dụng SSD, quá trình đồng bộ và truy cập dữ liệu hiện tại luôn đạt tốc độ nhanh nhất.

#### 2. Quy trình phân tầng ngầm hàng đêm (SSD ➡️ HDD)
* Hàng đêm (vào lúc `02:00 AM`), một tác vụ được thiết lập trong **Task Scheduler** của DSM sẽ tự động kích hoạt script `/volume1/scripts/storage_tiering.sh` với quyền `root`.
* Script tiến hành quét thư mục `hot-store` trên SSD để tìm kiếm các tệp tin **không được truy cập (đọc/ghi) quá 90 ngày**.
* Các tệp tin cũ được phát hiện sẽ được tự động chuyển (Move) từ đĩa **SSD (Volume 1)** sang đĩa **HDD (Volume 2)** trong thư mục chia sẻ `/volume2/cold-store/`.
* Các thư mục rỗng trên SSD sẽ được tự động xóa để giải phóng hoàn toàn dung lượng cho SSD.
* *Lưu ý:* Các file cũ sau khi chuyển sang HDD sẽ nằm ở thư mục `cold-store`. Bạn vẫn có thể truy cập chúng bất cứ lúc nào qua File Station hoặc qua kết nối mạng nội bộ (SMB) trỏ đến `cold-store`.

---

### 🛠️ Thiết lập trên hệ thống

1. **Thư mục chia sẻ (Shared Folder) - Đã được tạo sẵn:**
   * Thư mục **`hot-store`** lưu trên **Volume 1** (SSD).
   * Thư mục **`cold-store`** lưu trên **Volume 2** (HDD).
   * Cần bật tính năng **Team Folder** cho thư mục `hot-store` trong **Synology Drive Admin Console** trên Web DSM để ứng dụng máy tính có thể kết nối đồng bộ.

2. **Thiết lập Script chạy tự động (Task Scheduler):**
   * Đăng nhập vào Web DSM của bạn (`https://<your-domain>`).
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


#!/bin/bash
# ==============================================================================
# Script Storage Tiering cho Synology DSM (Virtual-DSM)
# Tự động di chuyển dữ liệu cũ từ SSD (Hot Tier) sang HDD (Cold Tier)
# ==============================================================================

# Cấu hình đường dẫn thư mục
SOURCE="/volume1/hot-store"    # Volume 1 = SSD (Hot Tier)
DEST="/volume2/cold-store"     # Volume 2 = HDD (Cold Tier)

# Số ngày không truy cập để xác định file "cũ"
DAYS=90

# Log file
LOG_FILE="/volume1/scripts/tiering_run.log"

echo "=== Bắt đầu chạy Storage Tiering lúc $(date) ===" >> "$LOG_FILE"

# Kiểm tra thư mục nguồn và đích
if [ ! -d "$SOURCE" ]; then
    echo "LỖI: Thư mục nguồn SSD ($SOURCE) không tồn tại." >> "$LOG_FILE"
    exit 1
fi

if [ ! -d "$DEST" ]; then
    echo "Thông báo: Thư mục đích HDD ($DEST) chưa có. Tiến hành tạo mới." >> "$LOG_FILE"
    mkdir -p "$DEST"
fi

# Đếm file cần di chuyển
COUNT=$(find "$SOURCE" -type f -atime +$DAYS 2>/dev/null | wc -l)
echo "Tìm thấy $COUNT file không truy cập hơn $DAYS ngày." >> "$LOG_FILE"

# Di chuyển các file cũ
find "$SOURCE" -type f -atime +$DAYS 2>/dev/null | while read -r file; do
    rel_path="${file#$SOURCE/}"
    dest_dir=$(dirname "$DEST/$rel_path")
    mkdir -p "$dest_dir"
    echo "Di chuyển: $rel_path (SSD -> HDD)" >> "$LOG_FILE"
    mv "$file" "$DEST/$rel_path"
done

# Xóa thư mục rỗng trên SSD
find "$SOURCE" -mindepth 1 -type d -empty -delete 2>/dev/null

echo "=== Hoàn thành Storage Tiering lúc $(date) ===" >> "$LOG_FILE"

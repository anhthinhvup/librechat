# Sửa lỗi MongoDB corrupt data

## Vấn đề

MongoDB: `Unable to read the storage engine metadata file` - file storage.bson bị corrupt

## Giải pháp

### Cách 1: Xóa và tạo lại data (Mất dữ liệu cũ)

```bash
cd /opt/librechat

# 1. Stop MongoDB
docker-compose stop mongodb

# 2. Backup data cũ (nếu cần)
mv data-node data-node.backup.$(date +%Y%m%d_%H%M%S)

# 3. Tạo thư mục mới
mkdir -p data-node
chown -R 1000:1000 data-node
chmod -R 755 data-node

# 4. Start MongoDB
docker-compose up -d mongodb

# 5. Đợi khởi động
sleep 30

# 6. Kiểm tra
docker logs chat-mongodb --tail 20
```

### Cách 2: Sửa file storage.bson (Giữ dữ liệu)

```bash
cd /opt/librechat

# 1. Stop MongoDB
docker-compose stop mongodb

# 2. Xóa file storage.bson corrupt
rm -f data-node/storage.bson

# 3. Set quyền lại
chown -R 1000:1000 data-node
chmod -R 755 data-node

# 4. Start MongoDB
docker-compose up -d mongodb

# 5. Đợi khởi động
sleep 30

# 6. Kiểm tra
docker logs chat-mongodb --tail 20
```


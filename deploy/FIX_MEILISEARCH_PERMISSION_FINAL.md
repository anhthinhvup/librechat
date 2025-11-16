# Sửa lỗi Meilisearch Permission - Final

## Vấn đề

Meilisearch: `Permission denied (os error 13)` - vẫn còn lỗi permission

## Giải pháp

```bash
cd /opt/librechat

# 1. Stop Meilisearch
docker-compose stop meilisearch

# 2. Xóa thư mục cũ và tạo lại
rm -rf meili_data_v1.12
mkdir -p meili_data_v1.12

# 3. Set quyền đúng (1000:1000)
chown -R 1000:1000 meili_data_v1.12
chmod -R 777 meili_data_v1.12  # Dùng 777 để chắc chắn

# 4. Kiểm tra quyền
ls -la meili_data_v1.12/

# 5. Start Meilisearch
docker-compose up -d meilisearch

# 6. Đợi khởi động
sleep 10

# 7. Kiểm tra
docker logs chat-meilisearch --tail 20
docker ps | grep meilisearch
```

## Sửa cả 2 cùng lúc

```bash
cd /opt/librechat

# Stop cả 2
docker-compose stop mongodb meilisearch

# Sửa MongoDB
rm -f data-node/storage.bson
chown -R 1000:1000 data-node
chmod -R 755 data-node

# Sửa Meilisearch
rm -rf meili_data_v1.12
mkdir -p meili_data_v1.12
chown -R 1000:1000 meili_data_v1.12
chmod -R 777 meili_data_v1.12

# Start lại
docker-compose up -d mongodb meilisearch

# Đợi khởi động
echo "Đợi MongoDB và Meilisearch khởi động (30 giây)..."
sleep 30

# Kiểm tra
docker ps | grep -E "mongodb|meilisearch"
docker logs chat-mongodb --tail 10
docker logs chat-meilisearch --tail 10
```


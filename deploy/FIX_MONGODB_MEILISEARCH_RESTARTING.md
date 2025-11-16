# Sửa MongoDB và Meilisearch restart liên tục

## Vấn đề

- MongoDB: `Restarting (14)` - restart liên tục
- Meilisearch: `Restarting (1)` - restart liên tục

## Kiểm tra

```bash
cd /opt/librechat

# 1. Xem MongoDB logs
docker logs chat-mongodb --tail 50

# 2. Xem Meilisearch logs
docker logs chat-meilisearch --tail 50

# 3. Kiểm tra quyền thư mục data
ls -la data-node/
ls -la meili_data_v1.12/
```

## Sửa lỗi permission

### Sửa MongoDB:

```bash
cd /opt/librechat

# 1. Tạo thư mục data-node nếu chưa có
mkdir -p data-node

# 2. Set quyền theo UID/GID (1000:1000)
chown -R 1000:1000 data-node
chmod -R 755 data-node

# 3. Restart MongoDB
docker-compose restart mongodb

# 4. Đợi và kiểm tra
sleep 10
docker ps | grep mongodb
docker logs chat-mongodb --tail 20
```

### Sửa Meilisearch:

```bash
cd /opt/librechat

# 1. Tạo thư mục meili_data_v1.12 nếu chưa có
mkdir -p meili_data_v1.12

# 2. Set quyền theo UID/GID (1000:1000)
chown -R 1000:1000 meili_data_v1.12
chmod -R 755 meili_data_v1.12

# 3. Restart Meilisearch
docker-compose restart meilisearch

# 4. Đợi và kiểm tra
sleep 10
docker ps | grep meilisearch
docker logs chat-meilisearch --tail 20
```

## Sửa tất cả cùng lúc

```bash
cd /opt/librechat

# 1. Tạo và set quyền tất cả thư mục
mkdir -p data-node meili_data_v1.12
chown -R 1000:1000 data-node meili_data_v1.12
chmod -R 755 data-node meili_data_v1.12

# 2. Restart MongoDB và Meilisearch
docker-compose restart mongodb meilisearch

# 3. Đợi khởi động
echo "Đợi MongoDB và Meilisearch khởi động (30 giây)..."
sleep 30

# 4. Kiểm tra
docker ps | grep -E "mongodb|meilisearch"
docker logs chat-mongodb --tail 10
docker logs chat-meilisearch --tail 10
```


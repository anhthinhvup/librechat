# Sửa lỗi MongoDB Connection

## Vấn đề

- `connect ECONNREFUSED 172.20.0.5:27017` - MongoDB connection refused
- `getaddrinfo EAI_AGAIN mongodb` - Không resolve được hostname mongodb
- Container restart liên tục

## Kiểm tra

```bash
cd /opt/librechat

# 1. Kiểm tra MongoDB container có chạy không
docker ps | grep mongodb

# 2. Kiểm tra MongoDB logs
docker logs chat-mongodb --tail 30

# 3. Kiểm tra network
docker network inspect librechat_default | grep -A 5 mongodb

# 4. Test kết nối từ container
docker exec LibreChat ping -c 2 mongodb

# 5. Kiểm tra MONGO_URI
grep MONGO_URI .env
```

## Sửa lỗi

### Nếu MongoDB chưa start:

```bash
cd /opt/librechat

# Start MongoDB
docker-compose up -d mongodb

# Đợi MongoDB khởi động (30-60 giây)
sleep 30

# Kiểm tra MongoDB logs
docker logs chat-mongodb --tail 20

# Restart API
docker-compose restart api
```

### Nếu network không đúng:

```bash
# Kiểm tra containers có cùng network không
docker inspect LibreChat | grep -A 10 Networks
docker inspect chat-mongodb | grep -A 10 Networks

# Nếu khác network, restart tất cả
docker-compose down
docker-compose up -d
```

### Nếu MongoDB đang khởi động:

```bash
# Đợi MongoDB sẵn sàng
echo "Đợi MongoDB khởi động..."
sleep 60

# Kiểm tra MongoDB đã sẵn sàng chưa
docker exec chat-mongodb mongosh --eval "db.adminCommand('ping')" 2>/dev/null || echo "MongoDB chưa sẵn sàng"

# Restart API
docker-compose restart api
```

## Sửa nhanh

```bash
cd /opt/librechat

# 1. Restart tất cả containers
docker-compose down
docker-compose up -d

# 2. Đợi MongoDB khởi động (quan trọng!)
echo "Đợi MongoDB khởi động (60 giây)..."
sleep 60

# 3. Kiểm tra MongoDB
docker logs chat-mongodb --tail 10 | grep -i "listening\|waiting" || echo "MongoDB đang khởi động..."

# 4. Restart API
docker-compose restart api

# 5. Đợi API khởi động
sleep 30

# 6. Kiểm tra
docker ps | grep LibreChat
docker logs LibreChat --tail 20 | grep -i "connected\|listening" | tail -5
```


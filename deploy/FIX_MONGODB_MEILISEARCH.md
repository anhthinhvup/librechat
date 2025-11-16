# Sửa lỗi MongoDB và Meilisearch connection

## Vấn đề

- `getaddrinfo EAI_AGAIN mongodb` - Không kết nối được MongoDB
- `[mongoMeili] Error checking index` - Meilisearch không kết nối được

## Kiểm tra

```bash
cd /opt/librechat

# 1. Kiểm tra containers có chạy không
docker ps | grep -E "mongodb|meilisearch"

# 2. Kiểm tra network
docker network ls | grep librechat

# 3. Kiểm tra MONGO_URI trong .env
grep MONGO_URI .env

# 4. Kiểm tra MEILI_HOST trong .env
grep MEILI_HOST .env

# 5. Test kết nối từ container
docker exec LibreChat ping -c 2 mongodb
docker exec LibreChat ping -c 2 meilisearch
```

## Sửa lỗi

### Nếu containers không chạy:

```bash
cd /opt/librechat

# Restart tất cả
docker-compose down
docker-compose up -d

# Đợi vài giây
sleep 10

# Kiểm tra lại
docker ps
```

### Nếu network không đúng:

```bash
# Kiểm tra containers có cùng network không
docker inspect LibreChat | grep -A 10 Networks
docker inspect chat-mongodb | grep -A 10 Networks
docker inspect chat-meilisearch | grep -A 10 Networks
```

### Nếu MONGO_URI sai:

```bash
# Kiểm tra .env
grep -E "MONGO_URI|MEILI_HOST" .env

# Sửa nếu cần (thường là đúng rồi)
# MONGO_URI=mongodb://mongodb:27017/LibreChat
# MEILI_HOST=http://meilisearch:7700
```

## Kiểm tra sau khi sửa

```bash
cd /opt/librechat

# Đợi containers start
sleep 10

# Kiểm tra containers
docker ps

# Kiểm tra logs không còn lỗi connection
docker logs LibreChat --tail 20 | grep -i "connected\|error" | tail -10

# Test API
curl -s http://localhost:3080 | head -20
```


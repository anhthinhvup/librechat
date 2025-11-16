# Restart API sau khi MongoDB và Meilisearch đã sẵn sàng

## MongoDB và Meilisearch đã chạy ổn

- ✅ MongoDB: "mongod startup complete" và "Waiting for connections"
- ✅ Meilisearch: "starting 4 workers" và "Actix runtime found"

## Restart API

```bash
cd /opt/librechat

# 1. Restart API
docker-compose restart api

# 2. Đợi API khởi động (30 giây)
echo "Đợi API khởi động..."
sleep 30

# 3. Kiểm tra API đã kết nối MongoDB chưa
docker logs LibreChat --tail 30 | grep -i "connected\|listening\|error" | tail -10

# 4. Test API
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3080

# 5. Kiểm tra container
docker ps | grep LibreChat
```

## Kiểm tra website

Sau khi API chạy ổn:
- Truy cập: https://chat.daydemy.com
- Website sẽ hoạt động bình thường
- Không còn lỗi 502 Bad Gateway


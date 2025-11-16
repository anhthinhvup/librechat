# Đợi API sẵn sàng

## Vấn đề

API trả về HTTP 000 - container có thể đang khởi động hoặc gặp lỗi.

## Kiểm tra

```bash
cd /opt/librechat

# 1. Kiểm tra container có đang chạy không
docker ps | grep LibreChat

# 2. Kiểm tra container có đang restart không
docker ps -a | grep LibreChat

# 3. Xem logs chi tiết
docker logs LibreChat --tail 30

# 4. Kiểm tra có lỗi nghiêm trọng không
docker logs LibreChat --tail 50 | grep -i "error\|fatal\|crash" | tail -10
```

## Đợi API sẵn sàng

```bash
cd /opt/librechat

# Đợi 30-60 giây để API khởi động hoàn toàn
echo "Đợi API khởi động..."
sleep 30

# Kiểm tra lại
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3080

# Nếu vẫn 000, kiểm tra logs
docker logs LibreChat --tail 50
```

## Kiểm tra container có restart liên tục không

```bash
# Xem số lần restart
docker ps -a | grep LibreChat

# Nếu restart nhiều lần, xem logs
docker logs LibreChat --tail 100 | grep -i "error\|fatal" | tail -20
```

## Sửa nếu container restart liên tục

```bash
cd /opt/librechat

# Xem logs để tìm lỗi
docker logs LibreChat --tail 100

# Kiểm tra .env có đúng không
grep -E "PORT|MONGO_URI|MEILI_HOST" .env

# Restart lại
docker-compose restart api
```


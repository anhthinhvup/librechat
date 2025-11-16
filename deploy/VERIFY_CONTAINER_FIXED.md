# Kiểm tra Container đã sửa xong

## Kiểm tra container đã chạy ổn

```bash
cd /opt/librechat

# 1. Kiểm tra container đang chạy
docker ps | grep LibreChat

# 2. Kiểm tra logs không còn lỗi permission
docker logs LibreChat --tail 30 | grep -i "permission\|EACCES" || echo "✅ Không còn lỗi permission"

# 3. Kiểm tra API có phản hồi không
curl -s -o /dev/null -w "%{http_code}" http://localhost:3080 || echo "API chưa sẵn sàng"

# 4. Kiểm tra thư mục logs đã được tạo
ls -la api/logs/ 2>/dev/null || echo "Thư mục api/logs chưa có"

# 5. Xem logs chi tiết
docker logs LibreChat --tail 20
```

## Kiểm tra nhanh

```bash
cd /opt/librechat

# Kiểm tra container và logs
docker ps | grep LibreChat && echo "✅ Container đang chạy" || echo "❌ Container không chạy"
docker logs LibreChat --tail 10 | tail -5
```

## Nếu container chạy ổn

- ✅ Container đã chạy
- ✅ Không còn lỗi permission
- ✅ API có thể phản hồi
- ✅ Website có thể truy cập được

## Nếu vẫn còn lỗi

```bash
# Xem logs chi tiết
docker logs LibreChat --tail 50

# Kiểm tra quyền thư mục
ls -la api/logs/

# Kiểm tra docker-compose.override.yaml
cat docker-compose.override.yaml
```


# Kiểm tra API đã hoạt động

## Kiểm tra nhanh

```bash
cd /opt/librechat

# 1. Kiểm tra API phản hồi
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3080

# 2. Kiểm tra API trả về gì
curl -s http://localhost:3080 | head -20

# 3. Kiểm tra website có hoạt động không
# Truy cập: https://chat.daydemy.com
```

## Lỗi Meilisearch (không ảnh hưởng chức năng chính)

Lỗi `[mongoMeili] Error` không ảnh hưởng đến:
- ✅ Đăng ký/Đăng nhập
- ✅ Chat
- ✅ API hoạt động

Chỉ ảnh hưởng đến:
- ⚠️ Search trong conversations (tùy chọn)

## Sửa Meilisearch (nếu cần)

```bash
cd /opt/librechat

# 1. Kiểm tra MEILI_MASTER_KEY
grep MEILI_MASTER_KEY .env

# 2. Nếu chưa có, thêm vào
# MEILI_MASTER_KEY=your-master-key-here

# 3. Restart meilisearch
docker-compose restart meilisearch

# 4. Đợi vài giây
sleep 10

# 5. Kiểm tra logs
docker logs chat-meilisearch --tail 20
```

## Kiểm tra website

```bash
# Test từ server
curl -s http://localhost:3080 | grep -i "librechat\|title" | head -5

# Hoặc test từ browser
# Truy cập: https://chat.daydemy.com
```


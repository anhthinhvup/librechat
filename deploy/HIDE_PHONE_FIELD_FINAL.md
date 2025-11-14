# Ẩn Phone Field - Container đã chạy ổn

## Container đã chạy ổn, bây giờ ẩn phone field

```bash
cd /opt/librechat

# 1. Tìm file HTML
HTML_FILE=$(docker exec LibreChat find /app/client/dist -name "index.html" 2>/dev/null | head -1)

# 2. Kiểm tra file có tồn tại không
if [ -z "$HTML_FILE" ]; then
    echo "❌ Không tìm thấy index.html"
    exit 1
fi

echo "Found HTML file: $HTML_FILE"

# 3. Backup
docker exec LibreChat cp $HTML_FILE ${HTML_FILE}.backup

# 4. Thêm CSS để ẩn phone field
docker exec LibreChat sh -c "sed -i '/<\/head>/i <style>input[name=\"phone\"],label[for=\"phone\"],input[type=\"tel\"]{display:none!important}</style>' $HTML_FILE"

# 5. Kiểm tra đã thêm chưa
docker exec LibreChat grep -A 1 "phone.*display:none" $HTML_FILE

# 6. Restart
docker-compose restart api

echo "✅ Đã ẩn phone field"
```

## Kiểm tra sau khi sửa

```bash
# Xem container đã chạy ổn
docker ps | grep LibreChat

# Test đăng ký - phone field không còn hiển thị
```


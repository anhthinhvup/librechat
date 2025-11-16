# Ẩn Phone Field trong file JavaScript đã build

## Tìm file cần sửa

```bash
cd /opt/librechat

# Tìm file JS có chứa phone field
docker exec LibreChat-API grep -l "phone.*optional" /app/client/dist/assets/*.js 2>/dev/null
```

## Sửa file JavaScript

Sau khi tìm thấy file (ví dụ: index.DUj3QYK1.js):

```bash
# Backup
docker exec LibreChat-API cp /app/client/dist/assets/index.DUj3QYK1.js /app/client/dist/assets/index.DUj3QYK1.js.backup

# Sửa: Thay thế text để ẩn phone field
# Tìm và thay: "phone.*optional" thành "phone.*optional" nhưng comment out
docker exec LibreChat-API sh -c "sed -i 's/phone.*optional/\/\*phone.*optional\*\//g' /app/client/dist/assets/index.DUj3QYK1.js"

# Hoặc xóa hoàn toàn phần phone (phức tạp hơn)
```

## Hoặc sửa trực tiếp bằng vi/nano trong container

```bash
# Vào container
docker exec -it LibreChat-API sh

# Tìm và sửa file
cd /app/client/dist/assets
vi index.DUj3QYK1.js
# Tìm "phone" và comment/xóa phần đó
```

## Restart sau khi sửa

```bash
docker-compose restart api
```

## Lưu ý

- File JS đã minify nên khó đọc
- Sửa có thể gây lỗi
- Tốt nhất là rebuild image với code mới


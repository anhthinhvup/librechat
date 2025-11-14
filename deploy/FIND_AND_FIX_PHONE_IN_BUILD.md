# Tìm và sửa Phone Field trong file đã build

## Tìm file chứa phone field

```bash
cd /opt/librechat

# Tìm file JS có chứa "phone"
docker exec LibreChat-API grep -r "phone.*optional\|renderInput.*phone" /app/client/dist/assets/*.js 2>/dev/null

# Hoặc tìm trong tất cả file
docker exec LibreChat-API sh -c "grep -l 'phone.*optional' /app/client/dist/assets/*.js 2>/dev/null"
```

## Sửa file JavaScript đã build

Sau khi tìm thấy file, sửa trực tiếp:

```bash
# Ví dụ nếu tìm thấy file: /app/client/dist/assets/forms.Dbp-QdNU.js
# Backup
docker exec LibreChat-API cp /app/client/dist/assets/forms.Dbp-QdNU.js /app/client/dist/assets/forms.Dbp-QdNU.js.backup

# Sửa (comment out hoặc xóa phần phone)
docker exec LibreChat-API sed -i "s/phone.*optional/\/\*phone.*optional\*\//g" /app/client/dist/assets/forms.Dbp-QdNU.js

# Restart
docker-compose restart api
```

## Lưu ý

- File JS đã được minify nên khó đọc
- Sửa có thể gây lỗi nếu không cẩn thận
- Tốt nhất là rebuild image với code mới


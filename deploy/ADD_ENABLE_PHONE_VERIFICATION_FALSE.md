# Thêm ENABLE_PHONE_VERIFICATION=false - Lệnh nhanh

## Chạy các lệnh này trên server:

```bash
# 1. Vào thư mục dự án (đã vào rồi)
cd /opt/librechat

# 2. Kiểm tra file .env có tồn tại không
ls -la .env

# 3. Thêm cấu hình tắt phone verification
echo "" >> .env
echo "# Tắt phone verification SMS" >> .env
echo "ENABLE_PHONE_VERIFICATION=false" >> .env

# 4. Kiểm tra đã thêm chưa
grep ENABLE_PHONE_VERIFICATION .env

# 5. Restart API
docker-compose restart api

# 6. Kiểm tra logs
docker-compose logs -f api | grep registerUser
```

## Hoặc dùng lệnh một dòng:

```bash
cd /opt/librechat && echo "" >> .env && echo "ENABLE_PHONE_VERIFICATION=false" >> .env && docker-compose restart api
```


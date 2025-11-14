# Kiểm tra và sửa Phone Verification

## Bước 1: Kiểm tra .env

```bash
cd /opt/librechat

# Kiểm tra đã có ENABLE_PHONE_VERIFICATION=false chưa
grep ENABLE_PHONE_VERIFICATION .env
```

Nếu chưa có, thêm vào:
```bash
echo "" >> .env
echo "ENABLE_PHONE_VERIFICATION=false" >> .env
```

## Bước 2: Kiểm tra container đã load .env chưa

```bash
# Xem environment variables trong container
docker exec LibreChat env | grep ENABLE_PHONE_VERIFICATION
```

## Bước 3: Restart để đảm bảo load .env mới

```bash
docker-compose restart api
```

## Bước 4: Kiểm tra code mới đã có chưa

Vì đã sửa code, cần pull code mới từ git:

```bash
cd /opt/librechat

# Pull code mới
git pull origin main

# Hoặc nếu đang ở branch khác
git pull
```

## Bước 5: Rebuild với code mới (nếu có thay đổi code)

```bash
# Nếu có Dockerfile và muốn build local
docker-compose build api
docker-compose up -d

# Hoặc chỉ restart nếu code đã được mount
docker-compose restart api
```

## Kiểm tra logs

```bash
# Xem logs khi có user đăng ký
docker-compose logs -f api | grep -E "registerUser|Phone verification"
```

## Lưu ý

- Lỗi pull image không ảnh hưởng nếu image đã có sẵn
- Code mới cần được pull từ git trước
- Nếu dùng image từ registry, code mới chưa có trong image cũ


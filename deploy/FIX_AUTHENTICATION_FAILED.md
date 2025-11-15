# Sửa lỗi "Authentication failed"

## Vấn đề

Lỗi "Authentication failed. Please check your login method and try again." khi đăng nhập.

## Nguyên nhân có thể

1. Google OAuth credentials chưa được cấu hình đúng
2. Backend chưa load được .env mới
3. DOMAIN_SERVER không đúng
4. JWT secrets chưa được cấu hình
5. Database connection issue

## Kiểm tra và sửa

### Bước 1: Kiểm tra Google OAuth credentials

```bash
cd /opt/librechat

# Kiểm tra .env
grep GOOGLE .env

# Kiểm tra container đã load chưa
docker exec LibreChat env | grep GOOGLE_CLIENT

# Nếu chưa có, thêm vào .env:
# GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com
# GOOGLE_CLIENT_SECRET=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
```

### Bước 2: Kiểm tra DOMAIN_SERVER

```bash
cd /opt/librechat

# Kiểm tra DOMAIN_SERVER
grep DOMAIN_SERVER .env

# Phải là: DOMAIN_SERVER=https://chat.daydemy.com
# Nếu không đúng, sửa:
sed -i 's|DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.daydemy.com|' .env
```

### Bước 3: Kiểm tra JWT secrets

```bash
cd /opt/librechat

# Kiểm tra JWT secrets
grep JWT .env

# Nếu chưa có hoặc là placeholder, tạo mới:
# JWT_SECRET=$(openssl rand -base64 32)
# JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Thêm vào .env:
# JWT_SECRET=your_generated_secret_here
# JWT_REFRESH_SECRET=your_generated_refresh_secret_here
```

### Bước 4: Kiểm tra MongoDB connection

```bash
cd /opt/librechat

# Kiểm tra MongoDB đang chạy
docker ps | grep mongodb

# Kiểm tra connection từ API
docker logs LibreChat --tail 50 | grep -i "mongo\|connected\|error"
```

### Bước 5: Restart và kiểm tra logs

```bash
cd /opt/librechat

# Restart API
docker-compose restart api

# Đợi vài giây
sleep 10

# Kiểm tra logs
docker logs LibreChat --tail 50 | grep -i "error\|auth\|oauth\|jwt"

# Kiểm tra API có chạy ổn không
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3080
```

## Sửa nhanh (nếu chưa cấu hình Google OAuth)

```bash
cd /opt/librechat

# 1. Thêm Google OAuth credentials
sed -i 's|GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com|' .env
sed -i 's|GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=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|' .env

# 2. Đảm bảo DOMAIN_SERVER đúng
sed -i 's|DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.daydemy.com|' .env

# 3. Kiểm tra JWT secrets (tạo mới nếu chưa có)
if ! grep -q "^JWT_SECRET=" .env || grep -q "CHANGE_THIS" .env; then
    JWT_SECRET=$(openssl rand -base64 32)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)
    sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
fi

# 4. Restart
docker-compose restart api

# 5. Kiểm tra
sleep 10
docker logs LibreChat --tail 30
```

## Kiểm tra sau khi sửa

1. Truy cập: https://chat.daydemy.com/login
2. Thử đăng nhập bằng email/password
3. Hoặc thử "Continue with Google"
4. Không còn lỗi "Authentication failed"


# Thêm Google OAuth Credentials vào Server

## Credentials đã có

- **Client ID**: `485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com`
- **Client Secret**: `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`

## Cấu hình trên Server

```bash
cd /opt/librechat

# 1. Backup .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# 2. Sửa .env
vi .env

# Tìm và sửa các dòng:
# GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
# Thành:
GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com

# GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET
# Thành:
GOOGLE_CLIENT_SECRET=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

# 3. Kiểm tra DOMAIN_SERVER đúng chưa
grep DOMAIN_SERVER .env
# Phải là: DOMAIN_SERVER=https://chat.daydemy.com

# 4. Restart container để load .env mới
docker-compose restart api

# 5. Kiểm tra credentials đã được load
docker exec LibreChat env | grep GOOGLE_CLIENT

# 6. Kiểm tra logs
docker logs LibreChat --tail 20 | grep -i "google\|oauth"
```

## Hoặc dùng sed để sửa tự động

```bash
cd /opt/librechat

# Backup
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Sửa GOOGLE_CLIENT_ID
sed -i 's|GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com|' .env

# Sửa GOOGLE_CLIENT_SECRET
sed -i 's|GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=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|' .env

# Kiểm tra đã sửa đúng chưa
grep GOOGLE .env

# Restart
docker-compose restart api

# Kiểm tra
docker exec LibreChat env | grep GOOGLE_CLIENT
```

## Kiểm tra sau khi cấu hình

1. Truy cập: https://chat.daydemy.com/register
2. Click "Continue with Google"
3. Không còn lỗi "invalid_client"
4. Có thể đăng nhập bằng Google

## Lưu ý

- Đảm bảo trong Google Cloud Console, redirect URI đã được thêm:
  - `https://chat.daydemy.com/api/oauth/google/callback`
- Authorized JavaScript origins:
  - `https://chat.daydemy.com`


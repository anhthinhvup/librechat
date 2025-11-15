# Sửa lỗi Google OAuth cho Production (chat.daydemy.com)

## Vấn đề

- Error 401: invalid_client
- "The OAuth client was not found"
- URL có `client_id=YOUR_GOOGLE_CLIENT_ID` (placeholder)

## Giải pháp

### Bước 1: Tạo Google OAuth Credentials cho Production

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Điều hướng đến **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**

5. **Cấu hình OAuth consent screen** (nếu chưa có):
   - Chọn **External**
   - **App name**: LibreChat
   - **User support email**: Email của bạn
   - **Developer contact information**: Email của bạn
   - **Scopes**: Thêm `openid`, `profile`, `email`
   - **Test users**: Thêm email Google của bạn (nếu app chưa được verify)

6. **Tạo OAuth Client ID**:
   - **Application type**: Web application
   - **Name**: LibreChat Production
   - **Authorized JavaScript origins**:
     - `https://chat.daydemy.com`
   - **Authorized redirect URIs**:
     - `https://chat.daydemy.com/api/oauth/google/callback`
   - Click **Create**

7. **Sao chép Client ID và Client Secret**

### Bước 2: Cấu hình trên Server

```bash
cd /opt/librechat

# 1. Kiểm tra .env hiện tại
grep GOOGLE .env

# 2. Sửa .env - thay YOUR_GOOGLE_CLIENT_ID và YOUR_GOOGLE_CLIENT_SECRET
# Sử dụng vi hoặc nano
vi .env

# Tìm và sửa:
# GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
# Thành:
# GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com

# GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET
# Thành:
# GOOGLE_CLIENT_SECRET=GOCSPX-abcdefghijklmnopqrstuvwxyz

# 3. Kiểm tra DOMAIN_SERVER đúng chưa
grep DOMAIN_SERVER .env
# Phải là: DOMAIN_SERVER=https://chat.daydemy.com

# 4. Restart container để load .env mới
docker-compose restart api

# 5. Kiểm tra
docker logs LibreChat --tail 20 | grep -i "google\|oauth"
```

### Bước 3: Kiểm tra

```bash
# Kiểm tra credentials đã được load chưa
docker exec LibreChat env | grep GOOGLE_CLIENT

# Nếu thấy giá trị thật (không phải YOUR_GOOGLE_CLIENT_ID) thì OK
```

## Lưu ý quan trọng

1. **Redirect URI phải khớp chính xác**: `https://chat.daydemy.com/api/oauth/google/callback`
2. **JavaScript origins**: `https://chat.daydemy.com` (có https)
3. **Test users**: Nếu app chưa được verify, cần thêm email vào Test users
4. **HTTPS**: Google OAuth yêu cầu HTTPS trong production

## Kiểm tra sau khi sửa

1. Truy cập: https://chat.daydemy.com/register
2. Click "Continue with Google"
3. Không còn lỗi "invalid_client"
4. Có thể đăng nhập bằng Google


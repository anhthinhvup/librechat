# Hướng dẫn cấu hình Google OAuth SSO cho LibreChat

## Bước 1: Tạo Google OAuth Credentials

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo một project mới hoặc chọn project hiện có
3. Điều hướng đến **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Nếu chưa có, bạn sẽ cần cấu hình OAuth consent screen trước:
   - Chọn **External** (hoặc Internal nếu dùng Google Workspace)
   - Điền thông tin ứng dụng:
     - **App name**: LibreChat
     - **User support email**: Email của bạn
     - **Developer contact information**: Email của bạn
   - Click **Save and Continue**
   - Thêm scopes: `openid`, `profile`, `email`
   - Thêm test users (nếu cần)
   - Click **Save and Continue**

6. Tạo OAuth Client ID:
   - **Application type**: Web application
   - **Name**: LibreChat
   - **Authorized JavaScript origins**:
     - `http://localhost:3080` (cho development)
     - `https://yourdomain.com` (cho production)
   - **Authorized redirect URIs**:
     - `http://localhost:3080/api/oauth/google/callback` (cho development)
     - `https://yourdomain.com/api/oauth/google/callback` (cho production)
   - Click **Create**

7. Sao chép **Client ID** và **Client Secret**

## Bước 2: Cấu hình trong LibreChat

### Cách 1: Sử dụng script (Khuyên dùng)

```bash
docker-compose exec api node config/add-api-key.js google_oauth YOUR_CLIENT_ID YOUR_CLIENT_SECRET
```

### Cách 2: Thêm thủ công vào file .env

Thêm vào file `.env`:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# Registration Configuration
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=true
ALLOW_SOCIAL_REGISTRATION=true

# Domain Configuration (nếu khác localhost)
DOMAIN_SERVER=http://localhost:3080
```

### Cách 3: Cập nhật file librechat.yaml

File `librechat.yaml` đã được cấu hình với:
```yaml
registration:
  socialLogins: ['google']
```

## Bước 3: Khởi động lại container

```bash
docker-compose restart api
```

## Bước 4: Kiểm tra

1. Truy cập: http://localhost:3080
2. Bạn sẽ thấy:
   - Nút **"Sign up"** để đăng ký tài khoản mới
   - Nút **"Continue with Google"** để đăng nhập bằng Google
3. Test đăng ký và đăng nhập bằng Google

## Lưu ý quan trọng

### Redirect URI
Callback URL phải chính xác:
- Development: `http://localhost:3080/api/oauth/google/callback`
- Production: `https://yourdomain.com/api/oauth/google/callback`

### Domain Configuration
Nếu bạn chạy trên domain khác, cập nhật `DOMAIN_SERVER` trong file `.env`:
```env
DOMAIN_SERVER=https://yourdomain.com
```

### Email Domain Restrictions
Nếu bạn muốn giới hạn chỉ các email domain cụ thể được đăng ký, thêm vào `librechat.yaml`:
```yaml
registration:
  socialLogins: ['google']
  allowedDomains:
    - "gmail.com"
    - "yourcompany.com"
```

### Production Deployment
Khi deploy lên production:
1. Cập nhật **Authorized JavaScript origins** trong Google Cloud Console
2. Cập nhật **Authorized redirect URIs** trong Google Cloud Console
3. Cập nhật `DOMAIN_SERVER` trong file `.env`
4. Đảm bảo HTTPS được cấu hình đúng

## Troubleshooting

### Lỗi: "redirect_uri_mismatch"
- Kiểm tra lại **Authorized redirect URIs** trong Google Cloud Console
- Đảm bảo URL chính xác: `http://localhost:3080/api/oauth/google/callback`

### Lỗi: "invalid_client"
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` có đúng không
- Đảm bảo đã khởi động lại container sau khi thêm credentials

### Không thấy nút "Continue with Google"
- Kiểm tra `ALLOW_SOCIAL_LOGIN=true` trong file `.env`
- Kiểm tra `socialLogins: ['google']` trong file `librechat.yaml`
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` đã được cấu hình

### Không thấy mục đăng ký
- Kiểm tra `ALLOW_REGISTRATION=true` trong file `.env`
- Kiểm tra logs: `docker-compose logs api | grep -i registration`

## Xem logs

```bash
# Xem logs của API
docker-compose logs api

# Xem logs real-time
docker-compose logs -f api

# Filter logs cho OAuth
docker-compose logs api | grep -i "google\|oauth"
```













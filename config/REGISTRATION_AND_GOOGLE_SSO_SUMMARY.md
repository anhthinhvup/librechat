# Tóm tắt cấu hình Đăng ký và Google SSO

## ✅ Đã cấu hình

### 1. File `.env`
Đã thêm các biến môi trường sau:
```env
# Registration Configuration
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=true
ALLOW_SOCIAL_REGISTRATION=true

# Google OAuth Configuration (CẦN ĐIỀN THÔNG TIN)
# GOOGLE_CLIENT_ID=your_google_client_id_here
# GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# Google OAuth Callback URL
GOOGLE_CALLBACK_URL=/api/oauth/google/callback

# Domain Configuration (Local Development)
DOMAIN_CLIENT=http://localhost:3080
DOMAIN_SERVER=http://localhost:3080
```

### 2. File `librechat.yaml`
Đã cập nhật:
```yaml
registration:
  socialLogins: ['google']
```

## 📋 Các bước tiếp theo

### Bước 1: Tạo Google OAuth Credentials

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Điều hướng đến **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Cấu hình OAuth consent screen (nếu chưa có):
   - Chọn **External**
   - Điền thông tin ứng dụng
   - Thêm scopes: `openid`, `profile`, `email`
6. Tạo OAuth Client ID:
   - **Application type**: Web application
   - **Name**: LibreChat
   - **Authorized JavaScript origins**:
     - `http://localhost:3080`
     - `http://127.0.0.1:3080`
   - **Authorized redirect URIs**:
     - `http://localhost:3080/api/oauth/google/callback`
     - `http://127.0.0.1:3080/api/oauth/google/callback`
   - Click **Create**
7. Sao chép **Client ID** và **Client Secret**

### Bước 2: Thêm Google OAuth Credentials vào LibreChat

#### Cách 1: Sử dụng script (Khuyên dùng)
```bash
# Thêm Client ID
docker-compose exec api node config/add-api-key.js google_oauth_client_id YOUR_CLIENT_ID

# Thêm Client Secret
docker-compose exec api node config/add-api-key.js google_oauth_client_secret YOUR_CLIENT_SECRET
```

#### Cách 2: Thêm thủ công vào file `.env`
Mở file `.env` và uncomment, điền thông tin:
```env
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

### Bước 3: Khởi động lại container
```bash
docker-compose restart api
```

### Bước 4: Kiểm tra
1. Truy cập: http://localhost:3080
2. Bạn sẽ thấy:
   - Nút **"Sign up"** để đăng ký tài khoản mới
   - Nút **"Continue with Google"** để đăng nhập bằng Google
3. Test đăng ký và đăng nhập bằng Google

**Lưu ý**: Vì đang ở local development, bạn cần thêm email của mình vào **Test users** trong OAuth consent screen của Google Cloud Console.

## 🔍 Kiểm tra cấu hình

### Kiểm tra logs
```bash
docker-compose logs api | grep -i "google\|registration\|oauth"
```

### Kiểm tra biến môi trường
```bash
docker-compose exec api env | grep -i "GOOGLE\|ALLOW_REGISTRATION\|ALLOW_SOCIAL"
```

## ⚠️ Lưu ý quan trọng

1. **Redirect URI phải chính xác**: 
   - `http://localhost:3080/api/oauth/google/callback`
   - Phải khớp với cấu hình trong Google Cloud Console

2. **Domain Configuration** (Local Development):
   - `DOMAIN_SERVER` và `DOMAIN_CLIENT` đã được cấu hình là `http://localhost:3080`
   - Đây là cấu hình cho local development

3. **Test Users**:
   - Vì app chưa được verify, chỉ có thể test với các email đã thêm vào **Test users** trong OAuth consent screen
   - Thêm email Google của bạn vào danh sách test users

4. **HTTPS không bắt buộc ở Local**:
   - Ở local development, có thể dùng HTTP (http://localhost)
   - Google OAuth cho phép localhost với HTTP
   - Khi deploy lên production, sẽ cần HTTPS

4. **Email Domain Restrictions** (Tùy chọn):
   Nếu muốn giới hạn chỉ các email domain cụ thể, thêm vào `librechat.yaml`:
   ```yaml
   registration:
     socialLogins: ['google']
     allowedDomains:
       - "gmail.com"
       - "yourcompany.com"
   ```

## 🐛 Troubleshooting

### Không thấy nút "Continue with Google"
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` đã được cấu hình
- Kiểm tra `ALLOW_SOCIAL_LOGIN=true`
- Kiểm tra `socialLogins: ['google']` trong `librechat.yaml`
- Khởi động lại container: `docker-compose restart api`

### Lỗi "redirect_uri_mismatch"
- Kiểm tra **Authorized redirect URIs** trong Google Cloud Console
- Phải chính xác: `http://localhost:3080/api/oauth/google/callback`
- Đảm bảo `DOMAIN_SERVER` trong `.env` là `http://localhost:3080`

### Lỗi "access_denied"
- Kiểm tra email của bạn đã được thêm vào **Test users** trong OAuth consent screen chưa
- Vì app chưa được verify, chỉ có thể test với test users

### Không thấy mục đăng ký
- Kiểm tra `ALLOW_REGISTRATION=true` trong file `.env`
- Kiểm tra logs: `docker-compose logs api | grep -i registration`

### Lỗi "invalid_client"
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` có đúng không
- Đảm bảo đã khởi động lại container sau khi thêm credentials

## 📚 Tài liệu tham khảo

- [Hướng dẫn chi tiết Google OAuth Setup](./GOOGLE_OAUTH_SETUP.md)
- [LibreChat Documentation](https://www.librechat.ai/docs)


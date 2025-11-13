# Hướng dẫn cấu hình Google OAuth SSO cho Local Development

## 📋 Cấu hình hiện tại (Local Development)

### Domain Configuration
- **DOMAIN_CLIENT**: `http://localhost:3080`
- **DOMAIN_SERVER**: `http://localhost:3080`
- **Callback URL**: `http://localhost:3080/api/oauth/google/callback`

## 🔧 Bước 1: Tạo Google OAuth Credentials cho Local Development

### 1.1. Truy cập Google Cloud Console
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Điều hướng đến **APIs & Services** > **Credentials**

### 1.2. Cấu hình OAuth Consent Screen
1. Click **OAuth consent screen** (bên trái)
2. Chọn **External** (hoặc Internal nếu dùng Google Workspace)
3. Điền thông tin:
   - **App name**: LibreChat (Local)
   - **User support email**: Email của bạn
   - **Developer contact information**: Email của bạn
4. Click **Save and Continue**
5. **Scopes**: Thêm các scopes:
   - `openid`
   - `profile`
   - `email`
6. Click **Save and Continue**
7. **Test users**: Thêm email Google của bạn vào danh sách test users (nếu app chưa được verify)
8. Click **Save and Continue**

### 1.3. Tạo OAuth Client ID
1. Quay lại **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Chọn **Application type**: **Web application**
4. Điền thông tin:
   - **Name**: LibreChat Local
   - **Authorized JavaScript origins**:
     - `http://localhost:3080`
     - `http://127.0.0.1:3080`
   - **Authorized redirect URIs**:
     - `http://localhost:3080/api/oauth/google/callback`
     - `http://127.0.0.1:3080/api/oauth/google/callback`
5. Click **Create**
6. **Sao chép Client ID và Client Secret**

## 🔑 Bước 2: Thêm Google OAuth Credentials vào LibreChat

### Cách 1: Sử dụng script (Khuyên dùng)

```bash
# Thêm Client ID
docker-compose exec api node config/add-api-key.js google_oauth_client_id YOUR_CLIENT_ID

# Thêm Client Secret
docker-compose exec api node config/add-api-key.js google_oauth_client_secret YOUR_CLIENT_SECRET
```

### Cách 2: Thêm thủ công vào file `.env`

Mở file `.env` và uncomment, điền thông tin:
```env
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

## 🚀 Bước 3: Khởi động lại container

```bash
docker-compose restart api
```

## ✅ Bước 4: Kiểm tra

1. Truy cập: http://localhost:3080
2. Bạn sẽ thấy:
   - Nút **"Sign up"** để đăng ký tài khoản mới
   - Nút **"Continue with Google"** để đăng nhập bằng Google
3. Test đăng ký và đăng nhập bằng Google

## 🔍 Kiểm tra cấu hình

### Kiểm tra logs
```bash
docker-compose logs api | grep -i "google\|registration\|oauth"
```

### Kiểm tra biến môi trường
```bash
docker-compose exec api env | grep -i "GOOGLE\|ALLOW_REGISTRATION\|ALLOW_SOCIAL\|DOMAIN"
```

### Kiểm tra file cấu hình
```bash
# Kiểm tra .env
cat .env | grep -i "GOOGLE\|ALLOW_REGISTRATION\|DOMAIN"

# Kiểm tra librechat.yaml
cat librechat.yaml | grep -A 2 "registration"
```

## ⚠️ Lưu ý quan trọng cho Local Development

### 1. Test Users
- Khi app chưa được verify, chỉ có thể test với các email đã thêm vào **Test users** trong OAuth consent screen
- Thêm email Google của bạn vào danh sách test users

### 2. Redirect URI
- Phải chính xác: `http://localhost:3080/api/oauth/google/callback`
- Phải khớp với cấu hình trong Google Cloud Console

### 3. HTTPS không bắt buộc
- Ở local development, có thể dùng HTTP (http://localhost)
- Google OAuth cho phép localhost với HTTP

### 4. Port
- Đảm bảo port 3080 không bị sử dụng bởi ứng dụng khác
- Có thể thay đổi port trong file `.env` nếu cần:
  ```env
  PORT=3080
  ```

## 🐛 Troubleshooting

### Lỗi "redirect_uri_mismatch"
- Kiểm tra **Authorized redirect URIs** trong Google Cloud Console
- Phải chính xác: `http://localhost:3080/api/oauth/google/callback`
- Đảm bảo `DOMAIN_SERVER` trong `.env` là `http://localhost:3080`

### Lỗi "access_denied" hoặc "invalid_client"
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` có đúng không
- Đảm bảo đã khởi động lại container sau khi thêm credentials
- Kiểm tra email của bạn đã được thêm vào Test users chưa

### Không thấy nút "Continue with Google"
- Kiểm tra `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` đã được cấu hình
- Kiểm tra `ALLOW_SOCIAL_LOGIN=true`
- Kiểm tra `socialLogins: ['google']` trong `librechat.yaml`
- Khởi động lại container: `docker-compose restart api`

### Không thấy mục đăng ký
- Kiểm tra `ALLOW_REGISTRATION=true` trong file `.env`
- Kiểm tra logs: `docker-compose logs api | grep -i registration`

## 🚀 Khi deploy lên Production

Khi bạn sẵn sàng deploy lên production:

1. **Tạo OAuth Client ID mới cho production** (hoặc cập nhật existing one):
   - **Authorized JavaScript origins**: `https://yourdomain.com`
   - **Authorized redirect URIs**: `https://yourdomain.com/api/oauth/google/callback`

2. **Cập nhật file `.env`**:
   ```env
   DOMAIN_CLIENT=https://yourdomain.com
   DOMAIN_SERVER=https://yourdomain.com
   ```

3. **Cập nhật Google OAuth credentials** với production Client ID và Secret

4. **Khởi động lại container**

5. **Đảm bảo HTTPS được cấu hình đúng** (Google OAuth yêu cầu HTTPS trong production)

## 📚 Tài liệu tham khảo

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [LibreChat Documentation](https://www.librechat.ai/docs)










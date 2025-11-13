# Hướng dẫn sửa lỗi: redirect_uri_mismatch

## Lỗi hiện tại
```
Lỗi 400: redirect_uri_mismatch
redirect_uri=http://localhost:3080/oauth/google/callback
```

## Nguyên nhân
Google Cloud Console chưa có redirect URI `http://localhost:3080/oauth/google/callback` trong danh sách "Authorized redirect URIs".

## Cách sửa

### Bước 1: Truy cập Google Cloud Console
1. Mở trình duyệt và vào: https://console.cloud.google.com/apis/credentials
2. Đảm bảo bạn đã chọn đúng project (project chứa OAuth client ID của bạn)

### Bước 2: Mở OAuth Client ID
1. Tìm OAuth client ID bạn đã tạo (có Client ID: `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com`)
2. Click vào tên của OAuth client ID để mở cấu hình

### Bước 3: Thêm Authorized redirect URI
1. Scroll xuống phần **"Authorized redirect URIs"**
2. Click nút **"+ Thêm URI"** (hoặc **"+ Add URI"**)
3. Nhập chính xác URL sau:
   ```
   http://localhost:3080/oauth/google/callback
   ```
4. (Tùy chọn) Có thể thêm thêm:
   ```
   http://127.0.0.1:3080/oauth/google/callback
   ```

### Bước 4: Lưu thay đổi
1. Click nút **"Lưu"** (hoặc **"Save"**) ở cuối trang
2. Đợi vài giây để Google cập nhật cấu hình

### Bước 5: Kiểm tra lại
1. Quay lại trang LibreChat: http://localhost:3080/register
2. Refresh trang (F5)
3. Click nút **"Continue with Google"**
4. Thử đăng nhập lại

## Lưu ý quan trọng

### 1. URL phải chính xác
- **Đúng**: `http://localhost:3080/oauth/google/callback`
- **Sai**: `http://localhost:3080/api/oauth/google/callback` (có `/api` thừa)
- **Sai**: `https://localhost:3080/oauth/google/callback` (dùng `https` thay vì `http`)

### 2. Kiểm tra Test Users
- Đảm bảo email của bạn (`phamvanthinhcontact2004@gmail.com`) đã được thêm vào **Test users** trong OAuth consent screen
- Nếu chưa có, vào: https://console.cloud.google.com/apis/credentials/consent
- Scroll xuống phần **"Test users"**
- Click **"+ Thêm người dùng"** (hoặc **"+ Add users"**)
- Nhập email của bạn và click **"Thêm"** (hoặc **"Add"**)

### 3. Thời gian cập nhật
- Sau khi lưu, có thể mất **1-2 phút** để Google cập nhật cấu hình
- Nếu vẫn lỗi sau 2 phút, thử:
  - Xóa cache trình duyệt
  - Đăng xuất khỏi Google và đăng nhập lại
  - Thử trình duyệt khác

### 4. Kiểm tra OAuth Consent Screen
- Đảm bảo OAuth consent screen đã được cấu hình đúng:
  - User type: **External** (cho localhost)
  - App name: Tên ứng dụng của bạn
  - User support email: Email hỗ trợ
  - Developer contact information: Email của bạn

## Kiểm tra cấu hình LibreChat

### Kiểm tra biến môi trường
Các biến môi trường sau phải được cấu hình đúng trong `.env`:

```env
DOMAIN_SERVER=http://localhost:3080
GOOGLE_CALLBACK_URL=/oauth/google/callback
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=true
ALLOW_SOCIAL_REGISTRATION=true
```

### Kiểm tra route
Route OAuth được mount tại `/oauth` trong `api/server/index.js`:
```javascript
app.use('/oauth', routes.oauth);
```

Vì vậy callback URL sẽ là: `DOMAIN_SERVER + GOOGLE_CALLBACK_URL = http://localhost:3080/oauth/google/callback`

## Troubleshooting

### Vẫn lỗi sau khi đã thêm redirect URI?
1. **Kiểm tra lại URL trong Google Cloud Console**:
   - Đảm bảo không có khoảng trắng thừa
   - Đảm bảo đúng `http://` (không phải `https://`)
   - Đảm bảo đúng port `3080`

2. **Kiểm tra lại biến môi trường**:
   ```bash
   docker-compose exec api sh -c "grep -E 'DOMAIN_SERVER|GOOGLE_CALLBACK_URL' .env"
   ```

3. **Restart container**:
   ```bash
   docker-compose restart api
   ```

4. **Kiểm tra logs**:
   ```bash
   docker-compose logs --tail=50 api
   ```

### Lỗi "Access blocked: This app's request is invalid"?
- Đảm bảo email của bạn đã được thêm vào Test users
- Đảm bảo OAuth consent screen đã được publish (nếu cần)

### Lỗi "redirect_uri_mismatch" vẫn xuất hiện?
- Đợi thêm 2-3 phút để Google cập nhật
- Xóa cache trình duyệt và thử lại
- Kiểm tra lại URL trong Google Cloud Console (copy/paste từ LibreChat để đảm bảo chính xác)

## Liên kết hữu ích
- Google Cloud Console Credentials: https://console.cloud.google.com/apis/credentials
- Google OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent
- Google OAuth 2.0 Documentation: https://developers.google.com/identity/protocols/oauth2










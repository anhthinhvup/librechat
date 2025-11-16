# Hướng dẫn nhanh: Thêm Google OAuth để hiển thị nút "Continue with Google"

## ⚠️ Vấn đề hiện tại

Nút "Continue with Google" không hiển thị vì **Google OAuth credentials chưa được thêm vào file `.env`**.

## ✅ Giải pháp

### Bước 1: Lấy Google OAuth Credentials

1. Truy cập: https://console.cloud.google.com/
2. Tạo project hoặc chọn project hiện có
3. **APIs & Services** > **Credentials** > **Create Credentials** > **OAuth client ID**
4. Cấu hình:
   - **Application type**: Web application
   - **Name**: LibreChat Local
   - **Authorized JavaScript origins**: `http://localhost:3080`
   - **Authorized redirect URIs**: `http://localhost:3080/api/oauth/google/callback`
5. **Lưu Client ID và Client Secret**

### Bước 2: Thêm vào LibreChat

#### Cách 1: Sử dụng script (Khuyên dùng)

```bash
# Thêm Client ID
docker-compose exec api node config/add-api-key.js google_oauth_client_id YOUR_CLIENT_ID

# Thêm Client Secret
docker-compose exec api node config/add-api-key.js google_oauth_client_secret YOUR_CLIENT_SECRET
```

#### Cách 2: Sửa file `.env` thủ công

Mở file `.env` và tìm các dòng:
```env
# GOOGLE_CLIENT_ID=your_google_client_id_here
# GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

Sửa thành (bỏ dấu # và điền thông tin):
```env
GOOGLE_CLIENT_ID=your_actual_client_id_here
GOOGLE_CLIENT_SECRET=your_actual_client_secret_here
```

### Bước 3: Khởi động lại container

```bash
docker-compose restart api
```

### Bước 4: Kiểm tra

1. Refresh trang: http://localhost:3080/register
2. Bạn sẽ thấy nút **"Continue with Google"** xuất hiện

## 🔍 Kiểm tra nhanh

```bash
# Kiểm tra credentials đã được thêm chưa
docker-compose exec api env | grep GOOGLE_CLIENT

# Nếu thấy output có giá trị (không phải rỗng) thì đã OK
```

## ⚠️ Lưu ý quan trọng

1. **Test Users**: Vì app chưa được verify, bạn cần thêm email của mình vào **Test users** trong OAuth consent screen
2. **Redirect URI**: Phải chính xác `http://localhost:3080/api/oauth/google/callback`
3. **Cả hai credentials đều cần**: Cần cả `GOOGLE_CLIENT_ID` VÀ `GOOGLE_CLIENT_SECRET`













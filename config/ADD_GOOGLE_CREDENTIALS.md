# Hướng dẫn: Thêm Google OAuth Credentials sau khi tạo OAuth Client ID

## ✅ Bước 1: Lấy Client ID và Client Secret

Sau khi tạo OAuth Client ID thành công, bạn sẽ thấy một popup với thông tin:

1. **Client ID** - Copy giá trị này
2. **Client Secret** - Copy giá trị này (click vào "Show" để hiển thị)

**Lưu ý**: Nếu bạn đã đóng popup, bạn có thể:
- Vào **APIs & Services** > **Credentials**
- Click vào OAuth client ID vừa tạo
- Bạn sẽ thấy Client ID và có thể reset Client Secret nếu cần

## 🔑 Bước 2: Thêm vào LibreChat

### Cách 1: Sử dụng script (Khuyên dùng - Nhanh và dễ)

```bash
# Thêm Client ID (thay YOUR_CLIENT_ID bằng Client ID thật)
docker-compose exec api node config/add-api-key.js google_oauth_client_id YOUR_CLIENT_ID

# Thêm Client Secret (thay YOUR_CLIENT_SECRET bằng Client Secret thật)
docker-compose exec api node config/add-api-key.js google_oauth_client_secret YOUR_CLIENT_SECRET
```

**Ví dụ:**
```bash
docker-compose exec api node config/add-api-key.js google_oauth_client_id 123456789-abcdefghijklmnop.apps.googleusercontent.com
docker-compose exec api node config/add-api-key.js google_oauth_client_secret GOCSPX-abcdefghijklmnopqrstuvwxyz
```

### Cách 2: Sửa file `.env` thủ công

1. Mở file `.env` trong thư mục dự án
2. Tìm các dòng:
   ```env
   # GOOGLE_CLIENT_ID=your_google_client_id_here
   # GOOGLE_CLIENT_SECRET=your_google_client_secret_here
   ```

3. Sửa thành (bỏ dấu `#` và điền thông tin thật):
   ```env
   GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=GOCSPX-abcdefghijklmnopqrstuvwxyz
   ```

4. Lưu file

## 🚀 Bước 3: Khởi động lại container

```bash
docker-compose restart api
```

## ✅ Bước 4: Kiểm tra

1. **Kiểm tra credentials đã được thêm:**
   ```bash
   docker-compose exec api env | grep GOOGLE_CLIENT
   ```
   Bạn sẽ thấy:
   ```
   GOOGLE_CLIENT_ID=123456789-...
   GOOGLE_CLIENT_SECRET=GOCSPX-...
   ```

2. **Kiểm tra logs:**
   ```bash
   docker-compose logs api | grep -i "google\|oauth"
   ```

3. **Truy cập trang đăng ký:**
   - Mở trình duyệt: http://localhost:3080/register
   - **Refresh trang** (F5 hoặc Ctrl+R)
   - Bạn sẽ thấy nút **"Continue with Google"** xuất hiện!

## ⚠️ Lưu ý quan trọng

### 1. Authorized Redirect URIs
Đảm bảo bạn đã thêm đúng redirect URI trong Google Cloud Console:
- `http://localhost:3080/api/oauth/google/callback`

### 2. Test Users
Vì app chưa được verify, bạn cần:
- Vào **OAuth consent screen** > **Test users**
- Thêm email Google của bạn vào danh sách test users
- Chỉ các email trong danh sách này mới có thể đăng nhập

### 3. Cả hai credentials đều cần
- Cần cả `GOOGLE_CLIENT_ID` **VÀ** `GOOGLE_CLIENT_SECRET`
- Thiếu một trong hai sẽ không hiển thị nút

### 4. Khởi động lại container
- Sau khi thêm credentials, **phải khởi động lại container**
- Nếu không, thay đổi sẽ không có hiệu lực

## 🐛 Troubleshooting

### Không thấy nút sau khi thêm credentials
1. Kiểm tra credentials đã được thêm đúng chưa:
   ```bash
   docker-compose exec api env | grep GOOGLE_CLIENT
   ```

2. Kiểm tra đã khởi động lại container chưa:
   ```bash
   docker-compose restart api
   ```

3. Kiểm tra logs có lỗi không:
   ```bash
   docker-compose logs api | tail -20
   ```

4. **Refresh trình duyệt** (F5 hoặc Ctrl+R)

### Lỗi "redirect_uri_mismatch"
- Kiểm tra **Authorized redirect URIs** trong Google Cloud Console
- Phải có: `http://localhost:3080/api/oauth/google/callback`
- Đảm bảo `DOMAIN_SERVER` trong `.env` là `http://localhost:3080`

### Lỗi "access_denied"
- Thêm email của bạn vào **Test users** trong OAuth consent screen
- Vì app chưa được verify, chỉ test users mới có thể đăng nhập

## 📋 Checklist

- [ ] Đã tạo OAuth Client ID trong Google Cloud Console
- [ ] Đã copy Client ID và Client Secret
- [ ] Đã thêm Client ID vào LibreChat
- [ ] Đã thêm Client Secret vào LibreChat
- [ ] Đã khởi động lại container
- [ ] Đã thêm email vào Test users
- [ ] Đã kiểm tra redirect URI đúng
- [ ] Đã refresh trang đăng ký
- [ ] Nút "Continue with Google" đã hiển thị


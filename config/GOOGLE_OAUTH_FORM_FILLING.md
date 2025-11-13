# Hướng dẫn điền form tạo Google OAuth Client ID

## 📋 Các trường cần điền

### 1. **Loại ứng dụng** (Application type) ⭐
- **Chọn**: `Ứng dụng web` (Web application)
- Đây là lựa chọn đúng cho LibreChat

### 2. **Tên** (Name) ⭐
- **Nhập**: `LibreChat` hoặc `LibreChat Local`
- Hoặc để mặc định: `Web client 1`
- Tên này chỉ để quản lý trong console, không hiển thị cho người dùng

### 3. **Nguồn gốc JavaScript được ủy quyền** (Authorized JavaScript origins)
- **Click nút "+ Thêm URI"**
- **Nhập**: `http://localhost:3080`
- **Click "+ Thêm URI" lần nữa** (nếu muốn)
- **Nhập**: `http://127.0.0.1:3080` (tùy chọn, nhưng nên thêm)

**Kết quả sẽ có:**
```
http://localhost:3080
http://127.0.0.1:3080
```

### 4. **URI chuyển hướng được ủy quyền** (Authorized redirect URIs) ⭐ QUAN TRỌNG
- **Click nút "+ Thêm URI"**
- **Nhập**: `http://localhost:3080/api/oauth/google/callback`
- **Click "+ Thêm URI" lần nữa** (nếu muốn)
- **Nhập**: `http://127.0.0.1:3080/api/oauth/google/callback` (tùy chọn)

**Kết quả sẽ có:**
```
http://localhost:3080/api/oauth/google/callback
http://127.0.0.1:3080/api/oauth/google/callback
```

## ✅ Tóm tắt nhanh

**Các trường BẮT BUỘC phải điền:**
1. ✅ **Loại ứng dụng**: `Ứng dụng web` (đã chọn sẵn)
2. ✅ **Tên**: `LibreChat` (hoặc để mặc định)
3. ✅ **URI chuyển hướng**: `http://localhost:3080/api/oauth/google/callback` (QUAN TRỌNG NHẤT)

**Các trường TÙY CHỌN nhưng nên thêm:**
4. ⚪ **Nguồn gốc JavaScript**: `http://localhost:3080`
5. ⚪ **URI chuyển hướng thêm**: `http://127.0.0.1:3080/api/oauth/google/callback`

## 🎯 Sau khi điền xong

1. **Click nút "Tạo"** (Create)
2. Bạn sẽ thấy popup với:
   - **Client ID** - Copy giá trị này
   - **Client Secret** - Copy giá trị này (click "Show" để hiển thị)
3. **Lưu lại** Client ID và Client Secret để thêm vào LibreChat

## ⚠️ Lưu ý quan trọng

1. **Redirect URI phải chính xác**: 
   - Phải là: `http://localhost:3080/api/oauth/google/callback`
   - Không được có dấu cách, không được thiếu `/api/oauth/google/callback`

2. **Không cần HTTPS ở local**: 
   - Dùng `http://` không phải `https://`
   - Google cho phép localhost với HTTP

3. **Nếu đã tạo rồi nhưng thiếu redirect URI**:
   - Vào **APIs & Services** > **Credentials**
   - Click vào OAuth client ID vừa tạo
   - Thêm redirect URI vào phần "Authorized redirect URIs"
   - Click "Lưu" (Save)

## 📸 Hình ảnh minh họa

Sau khi điền đầy đủ, form sẽ trông như sau:

```
Loại ứng dụng: Ứng dụng web ✓
Tên: LibreChat

Nguồn gốc JavaScript được ủy quyền:
  ✓ http://localhost:3080
  ✓ http://127.0.0.1:3080

URI chuyển hướng được ủy quyền:
  ✓ http://localhost:3080/api/oauth/google/callback
  ✓ http://127.0.0.1:3080/api/oauth/google/callback
```

## 🚀 Bước tiếp theo

Sau khi tạo thành công và có Client ID + Client Secret:

1. Thêm vào LibreChat (xem: `config/ADD_GOOGLE_CREDENTIALS.md`)
2. Khởi động lại container
3. Test đăng nhập bằng Google










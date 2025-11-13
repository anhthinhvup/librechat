# Hướng dẫn thêm Token trực tiếp từ giao diện web

LibreChat hỗ trợ thêm API key và Base URL **trực tiếp từ giao diện web** mà không cần chỉnh sửa file config!

## 🎯 Cách thực hiện

### Bước 1: Tạo Generic Custom Endpoint (Chỉ cần làm 1 lần)

Chạy script để tạo một endpoint template cho phép user nhập từ UI:

```bash
docker-compose exec api node config/add-generic-endpoint.js myapi
```

Hoặc chế độ tương tác:
```bash
docker-compose exec api node config/add-generic-endpoint.js
```

Script sẽ tạo một endpoint với:
- `apiKey: 'user_provided'` - Cho phép user nhập API key từ UI
- `baseURL: 'user_provided'` - Cho phép user nhập Base URL từ UI

### Bước 2: Khởi động lại container

```bash
docker-compose restart api
```

### Bước 3: Thêm token từ giao diện web

1. **Đăng nhập vào LibreChat**: http://localhost:3080

2. **Tạo chat mới hoặc chọn model**

3. **Chọn endpoint** bạn vừa tạo (ví dụ: "myapi") từ dropdown "Provider"

4. **Nhập API Key và Base URL**:
   - Bạn sẽ thấy biểu tượng **🔑 (key icon)** hoặc nút **"Set API Key"**
   - Click vào đó để mở dialog
   - Nhập:
     - **API Key**: Token của bạn (ví dụ: `sk-SL4F...ZWPLO`)
     - **API URL**: Base URL của API (ví dụ: `https://api.langhit.com/v1`)
   - Chọn thời gian hết hạn (12 giờ, 24 giờ, 7 ngày, hoặc không bao giờ)
   - Click **"Save"**

5. **Sử dụng ngay!**
   - Sau khi lưu, bạn có thể sử dụng endpoint ngay lập tức
   - API key và Base URL được lưu an toàn và mã hóa trong database
   - Chỉ bạn mới có thể thấy và sử dụng API key của mình

## 📋 Ví dụ với Langhit

### Bước 1: Tạo endpoint
```bash
docker-compose exec api node config/add-generic-endpoint.js langhit
```

### Bước 2: Khởi động lại
```bash
docker-compose restart api
```

### Bước 3: Thêm token từ UI
1. Đăng nhập vào LibreChat
2. Chọn provider "langhit"
3. Click vào biểu tượng 🔑
4. Nhập:
   - **API Key**: `sk-SL4F...ZWPLO` (token từ Langhit)
   - **API URL**: `https://api.langhit.com/v1`
5. Click "Save"

## 🔍 Kiểm tra endpoint đã được tạo

### Xem file librechat.yaml:
```bash
docker-compose exec api cat /app/librechat.yaml
```

Bạn sẽ thấy:
```yaml
endpoints:
  custom:
    - name: 'langhit'
      apiKey: 'user_provided'
      baseURL: 'user_provided'
      models:
        default: ['gpt-3.5-turbo', 'gpt-4']
        fetch: true
      titleConvo: true
      titleModel: 'gpt-3.5-turbo'
      modelDisplayLabel: 'Langhit'
```

## ✅ Ưu điểm của cách này

1. **Dễ sử dụng**: Không cần chỉnh sửa file config
2. **Bảo mật**: API key được mã hóa và lưu riêng cho từng user
3. **Linh hoạt**: Mỗi user có thể có API key riêng
4. **Không cần restart**: Sau khi thêm endpoint một lần, user có thể thêm token mà không cần restart
5. **Quản lý chi phí**: Dễ dàng track chi phí theo từng user

## 🛠️ Quản lý API Keys từ UI

### Xem API key đã lưu:
- API key được hiển thị dưới dạng `<HIDDEN>` để bảo mật
- Bạn có thể xem lại bằng cách click vào biểu tượng 🔑

### Cập nhật API key:
1. Click vào biểu tượng 🔑
2. Nhập API key mới
3. Click "Save"

### Thu hồi (Revoke) API key:
1. Click vào biểu tượng 🔑
2. Click nút **"Revoke Keys"**
3. Xác nhận việc thu hồi

## ⚠️ Lưu ý

1. **Endpoint phải được tạo trước**: Bạn cần chạy script `add-generic-endpoint.js` trước để tạo endpoint template

2. **File librechat.yaml phải được mount**: Đảm bảo file `librechat.yaml` được mount vào container trong `docker-compose.yml`:
   ```yaml
   volumes:
     - type: bind
       source: ./librechat.yaml
       target: /app/librechat.yaml
   ```

3. **API key hết hạn**: API key sẽ hết hạn sau thời gian đã chọn (nếu có). Bạn cần nhập lại sau khi hết hạn.

4. **Mỗi user riêng biệt**: Mỗi user có API key riêng. User A không thể thấy API key của User B.

## 🔧 Troubleshooting

### Vấn đề: Không thấy endpoint trong dropdown
**Nguyên nhân:** 
- Endpoint chưa được tạo
- File librechat.yaml chưa được mount
- Chưa khởi động lại container

**Giải pháp:**
1. Kiểm tra endpoint đã được tạo: `docker-compose exec api cat /app/librechat.yaml`
2. Kiểm tra docker-compose.yml có mount librechat.yaml không
3. Khởi động lại: `docker-compose restart api`

### Vấn đề: Không thấy nút "Set API Key"
**Nguyên nhân:** 
- Endpoint không được cấu hình với `user_provided`
- Endpoint chưa được load đúng cách

**Giải pháp:**
1. Kiểm tra file librechat.yaml có `apiKey: 'user_provided'` và `baseURL: 'user_provided'` không
2. Khởi động lại container
3. Clear cache của browser và reload trang

### Vấn đề: Lỗi "Config not found"
**Nguyên nhân:** 
- Tên endpoint không khớp
- File librechat.yaml có lỗi cú pháp

**Giải pháp:**
1. Kiểm tra tên endpoint trong file YAML
2. Validate cú pháp YAML
3. Xem logs: `docker-compose logs api`

## 📚 Thêm thông tin

- Script tạo endpoint: `docker-compose exec api node config/add-generic-endpoint.js`
- Xem file config: `docker-compose exec api cat /app/librechat.yaml`
- Xem logs: `docker-compose logs api`
- Khởi động lại: `docker-compose restart api`

---

## 🎉 Quick Start

Nếu bạn có token từ Langhit hoặc service khác:

```bash
# 1. Tạo endpoint
docker-compose exec api node config/add-generic-endpoint.js myapi

# 2. Khởi động lại
docker-compose restart api

# 3. Đăng nhập vào LibreChat và thêm token từ UI!
```

Sau đó vào giao diện web, chọn endpoint "myapi", click 🔑, và nhập token của bạn!


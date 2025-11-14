# Tắt Phone Verification - Hướng dẫn nhanh

## Cách 1: Dùng script tự động (Khuyến nghị)

```bash
bash deploy/disable-phone-verification.sh
```

Script sẽ tự động:
- Tìm thư mục dự án
- Thêm hoặc cập nhật `ENABLE_PHONE_VERIFICATION=false` vào `.env`

## Cách 2: Thêm thủ công

### Bước 1: Vào thư mục dự án

```bash
cd /opt/librechat  # hoặc thư mục của bạn
```

### Bước 2: Mở file `.env`

```bash
nano .env
# hoặc
vi .env
```

### Bước 3: Thêm dòng này

```bash
# Tắt phone verification SMS
ENABLE_PHONE_VERIFICATION=false
```

### Bước 4: Lưu và thoát

- Nano: `Ctrl+X`, sau đó `Y`, sau đó `Enter`
- Vi: `:wq` và `Enter`

### Bước 5: Restart server

```bash
docker-compose restart api
```

## Kiểm tra

```bash
# Xem logs
docker-compose logs -f api | grep registerUser

# Bạn sẽ thấy:
# [registerUser] Phone verification is disabled. Phone number saved but OTP not sent.
```

## Bật lại

Sửa trong `.env`:
```bash
ENABLE_PHONE_VERIFICATION=true
```

Hoặc xóa dòng đó (mặc định là true).

Sau đó restart:
```bash
docker-compose restart api
```


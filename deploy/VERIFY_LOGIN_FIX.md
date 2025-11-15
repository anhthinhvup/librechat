# Kiểm tra sau khi sửa lỗi đăng nhập

## Đã có

- ✅ JWT_REFRESH_SECRET đã được tạo
- ✅ User tồn tại trong database (provider: local)
- ✅ Container đã restart

## Kiểm tra tiếp

### Bước 1: Kiểm tra JWT_REFRESH_SECRET đã được load vào container

```bash
cd /opt/librechat

# Kiểm tra trong container
docker exec LibreChat env | grep JWT_REFRESH_SECRET

# Phải thấy: JWT_REFRESH_SECRET=VQ/yQfB+yeyNrFOtz2TceLgwB8penUIEGhHaZUW7EwI=
```

### Bước 2: Xem logs khi đăng nhập

```bash
cd /opt/librechat

# Xem logs real-time
docker logs LibreChat --tail 100 -f

# Sau đó thử đăng nhập trên website
# Xem logs để biết lỗi cụ thể (nếu có)
```

### Bước 3: Kiểm tra user có password hash không

```bash
cd /opt/librechat

# Kiểm tra user có password không
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.findOne({email:'phamvanthinhcontact2004@gmail.com'}, {email:1, password:1, provider:1})"
```

Nếu không có password hash, có thể đăng ký chưa hoàn tất.

### Bước 4: Test đăng nhập

1. Truy cập: https://chat.daydemy.com/login
2. Nhập email: `phamvanthinhcontact2004@gmail.com`
3. Nhập password (mật khẩu bạn đã đặt khi đăng ký)
4. Click "Continue"

Nếu vẫn lỗi, xem logs để biết lỗi cụ thể.

## Nếu quên mật khẩu

Có thể reset password hoặc xóa user và đăng ký lại:

```bash
cd /opt/librechat

# Xóa user (CẨN THẬN - sẽ mất data!)
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.deleteOne({email:'phamvanthinhcontact2004@gmail.com'})"

# Sau đó đăng ký lại tại: https://chat.daydemy.com/register
```


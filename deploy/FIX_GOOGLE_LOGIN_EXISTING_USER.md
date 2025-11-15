# Sửa lỗi Google Login với user đã tồn tại

## Vấn đề

```
[googleLogin] User found by email: phamvanthinhcontact2004@gmail.com but not by googleId
[googleLogin] User phamvanthinhcontact2004@gmail.com already exists with provider local
```

User đã đăng ký bằng email/password (provider "local"), nên không thể đăng nhập bằng Google OAuth.

## Giải pháp

### Cách 1: Đăng nhập bằng email/password (Đơn giản nhất)

1. Truy cập: https://chat.daydemy.com/login
2. Đăng nhập bằng email/password thay vì "Continue with Google"
3. Sử dụng mật khẩu bạn đã đặt khi đăng ký

### Cách 2: Link Google account với user hiện có (Sửa database)

```bash
cd /opt/librechat

# 1. Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# 2. Tìm user
db.users.find({ email: "phamvanthinhcontact2004@gmail.com" }).pretty()

# 3. Lấy Google ID từ lần đăng nhập Google (cần thử đăng nhập Google một lần để lấy ID)
# Hoặc xem logs để tìm Google ID

# 4. Update user để thêm Google provider
# Thay USER_ID và GOOGLE_ID bằng giá trị thật
db.users.updateOne(
  { email: "phamvanthinhcontact2004@gmail.com" },
  { 
    $set: { 
      provider: "google",
      googleId: "GOOGLE_ID_HERE"  // Cần lấy từ Google profile
    }
  }
)

# 5. Thoát
exit
```

### Cách 3: Xóa user cũ và tạo lại bằng Google OAuth

```bash
cd /opt/librechat

# 1. Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# 2. Xóa user (CẨN THẬN - sẽ mất data!)
db.users.deleteOne({ email: "phamvanthinhcontact2004@gmail.com" })

# 3. Xóa conversations và messages của user (tùy chọn)
# Lấy user ID trước khi xóa
USER_ID=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.findOne({email:'phamvanthinhcontact2004@gmail.com'})._id" | tr -d '\r\n')
# Xóa conversations
db.conversations.deleteMany({ user: USER_ID })
# Xóa messages
db.messages.deleteMany({ user: USER_ID })

# 4. Thoát
exit

# 5. Sau đó đăng ký lại bằng Google OAuth
```

### Cách 4: Cho phép link account (Sửa code - Phức tạp)

Cần sửa code để cho phép link Google account với user local. Không khuyến nghị trừ khi cần thiết.

## Khuyến nghị

**Dùng Cách 1**: Đăng nhập bằng email/password. Đây là cách đơn giản và an toàn nhất.

Nếu quên mật khẩu, có thể reset hoặc xóa user và tạo lại.


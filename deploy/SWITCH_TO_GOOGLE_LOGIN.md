# Chuyển sang đăng nhập bằng Google OAuth

## Vấn đề

User đã đăng ký bằng email/password (provider "local"), nên không thể đăng nhập bằng Google OAuth.

## Giải pháp: Xóa user và đăng ký lại bằng Google

### Bước 1: Xóa user hiện tại

```bash
cd /opt/librechat

# 1. Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# 2. Lấy user ID trước khi xóa (để xóa conversations và messages)
var user = db.users.findOne({email: "phamvanthinhcontact2004@gmail.com"});
print("User ID: " + user._id);

# 3. Xóa conversations của user (tùy chọn - nếu muốn giữ lại thì bỏ qua)
db.conversations.deleteMany({ user: user._id.toString() });

# 4. Xóa messages của user (tùy chọn - nếu muốn giữ lại thì bỏ qua)
db.messages.deleteMany({ user: user._id.toString() });

# 5. Xóa user
db.users.deleteOne({ email: "phamvanthinhcontact2004@gmail.com" });

# 6. Kiểm tra đã xóa chưa
db.users.findOne({email: "phamvanthinhcontact2004@gmail.com"});
# Phải trả về: null

# 7. Thoát
exit
```

### Bước 2: Đăng ký lại bằng Google OAuth

1. Truy cập: https://chat.daydemy.com/register
2. Click "Continue with Google"
3. Chọn tài khoản Google của bạn
4. Cho phép quyền truy cập
5. Đăng ký hoàn tất

### Bước 3: Kiểm tra

Sau khi đăng ký, bạn sẽ có thể:
- ✅ Đăng nhập bằng Google OAuth
- ✅ Không cần nhớ mật khẩu
- ✅ Bảo mật hơn (dùng Google authentication)

## Lưu ý

⚠️ **Xóa user sẽ mất:**
- Tất cả conversations (cuộc hội thoại)
- Tất cả messages (tin nhắn)
- Các cài đặt cá nhân

✅ **Sau khi đăng ký lại bằng Google:**
- Bạn sẽ có account mới
- Có thể đăng nhập bằng Google OAuth
- Không cần nhớ mật khẩu

## Hoặc giữ lại data (Phức tạp hơn)

Nếu muốn giữ lại conversations và messages, cần:
1. Backup conversations và messages
2. Xóa user
3. Đăng ký lại bằng Google
4. Restore conversations và messages với user ID mới

Không khuyến nghị trừ khi thực sự cần.


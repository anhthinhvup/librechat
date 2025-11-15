# Kiểm tra tại sao không đăng nhập được

## Vấn đề

Đã đăng ký nhưng không đăng nhập được (bằng email/password).

## Kiểm tra

### Bước 1: Kiểm tra JWT_REFRESH_SECRET

```bash
cd /opt/librechat

# Kiểm tra .env
grep JWT_REFRESH_SECRET .env

# Kiểm tra trong container
docker exec LibreChat env | grep JWT_REFRESH_SECRET
```

**Nếu không có JWT_REFRESH_SECRET, tạo mới:**

```bash
cd /opt/librechat

# Tạo JWT_REFRESH_SECRET
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Thêm vào .env
if grep -q "^JWT_REFRESH_SECRET=" .env; then
    sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
else
    echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" >> .env
fi

# Restart
docker-compose restart api
```

### Bước 2: Xem logs khi đăng nhập

```bash
cd /opt/librechat

# Xem logs real-time
docker logs LibreChat --tail 100 -f

# Sau đó thử đăng nhập trên website
# Xem logs để biết lỗi cụ thể
```

### Bước 3: Kiểm tra user trong database

```bash
cd /opt/librechat

# Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# Tìm user
db.users.find({ email: "phamvanthinhcontact2004@gmail.com" }).pretty()

# Kiểm tra user có password hash không
# Nếu không có, có thể đăng ký chưa hoàn tất

# Thoát
exit
```

### Bước 4: Test đăng nhập bằng API

```bash
cd /opt/librechat

# Test login endpoint
curl -v -X POST http://localhost:3080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"phamvanthinhcontact2004@gmail.com","password":"YOUR_PASSWORD"}' \
  2>&1 | head -50
```

## Sửa nhanh

```bash
cd /opt/librechat

# 1. Đảm bảo có JWT_REFRESH_SECRET
if ! grep -q "^JWT_REFRESH_SECRET=" .env || grep -q "CHANGE_THIS" .env | grep JWT_REFRESH; then
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)
    if grep -q "^JWT_REFRESH_SECRET=" .env; then
        sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
    else
        echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" >> .env
    fi
    echo "✅ Đã tạo JWT_REFRESH_SECRET"
fi

# 2. Đảm bảo có JWT_SECRET
if ! grep -q "^JWT_SECRET=" .env || grep -q "CHANGE_THIS" .env | grep JWT_SECRET; then
    JWT_SECRET=$(openssl rand -base64 32)
    if grep -q "^JWT_SECRET=" .env; then
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    else
        echo "JWT_SECRET=$JWT_SECRET" >> .env
    fi
    echo "✅ Đã tạo JWT_SECRET"
fi

# 3. Restart
docker-compose restart api

# 4. Đợi vài giây
sleep 10

# 5. Kiểm tra
docker exec LibreChat env | grep JWT
docker logs LibreChat --tail 20
```

## Lưu ý

- **Mật khẩu**: Đảm bảo nhập đúng mật khẩu đã đặt khi đăng ký
- **JWT secrets**: Cả JWT_SECRET và JWT_REFRESH_SECRET đều cần có giá trị
- **Case sensitive**: Email và password có phân biệt hoa thường


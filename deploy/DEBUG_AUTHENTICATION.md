# Debug lỗi Authentication failed

## Kiểm tra chi tiết

### Bước 1: Xem logs backend khi đăng nhập

```bash
cd /opt/librechat

# Xem logs real-time khi thử đăng nhập
docker logs LibreChat --tail 100 -f

# Hoặc xem logs gần đây
docker logs LibreChat --tail 50 | grep -i "auth\|error\|login\|jwt"
```

### Bước 2: Kiểm tra credentials trong container

```bash
cd /opt/librechat

# Kiểm tra tất cả biến môi trường liên quan
docker exec LibreChat env | grep -E "GOOGLE|JWT|DOMAIN|MONGO" | sort

# Kiểm tra cụ thể
docker exec LibreChat env | grep GOOGLE_CLIENT_ID
docker exec LibreChat env | grep GOOGLE_CLIENT_SECRET
docker exec LibreChat env | grep JWT_SECRET
docker exec LibreChat env | grep DOMAIN_SERVER
```

### Bước 3: Kiểm tra .env file

```bash
cd /opt/librechat

# Xem .env
cat .env | grep -E "GOOGLE|JWT|DOMAIN" | grep -v "^#"

# Kiểm tra format
grep GOOGLE_CLIENT_ID .env
grep GOOGLE_CLIENT_SECRET .env
grep JWT_SECRET .env
grep DOMAIN_SERVER .env
```

### Bước 4: Kiểm tra MongoDB connection

```bash
cd /opt/librechat

# Kiểm tra MongoDB đang chạy
docker ps | grep mongodb

# Test connection từ API container
docker exec LibreChat sh -c "ping -c 2 mongodb"

# Kiểm tra MONGO_URI
docker exec LibreChat env | grep MONGO_URI
```

### Bước 5: Kiểm tra API endpoint

```bash
cd /opt/librechat

# Test API health
curl -v http://localhost:3080/api/health 2>&1 | head -20

# Test login endpoint
curl -v -X POST http://localhost:3080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}' 2>&1 | head -30
```

## Sửa các vấn đề thường gặp

### Nếu JWT_SECRET chưa có hoặc là placeholder:

```bash
cd /opt/librechat

# Tạo JWT secrets mới
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Thêm vào .env
if grep -q "^JWT_SECRET=" .env; then
    sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
else
    echo "JWT_SECRET=$JWT_SECRET" >> .env
fi

if grep -q "^JWT_REFRESH_SECRET=" .env; then
    sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
else
    echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" >> .env
fi

# Restart
docker-compose restart api
```

### Nếu Google OAuth chưa được load:

```bash
cd /opt/librechat

# Đảm bảo .env có credentials
grep GOOGLE_CLIENT .env

# Nếu không có, thêm vào
echo "GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com" >> .env
echo "GOOGLE_CLIENT_SECRET=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" >> .env

# Restart
docker-compose restart api
```

### Nếu DOMAIN_SERVER không đúng:

```bash
cd /opt/librechat

# Sửa DOMAIN_SERVER
sed -i 's|DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.daydemy.com|' .env

# Restart
docker-compose restart api
```

## Kiểm tra sau khi sửa

```bash
cd /opt/librechat

# 1. Kiểm tra container đã load .env chưa
docker exec LibreChat env | grep -E "GOOGLE_CLIENT|JWT_SECRET|DOMAIN_SERVER"

# 2. Restart lại
docker-compose restart api

# 3. Đợi vài giây
sleep 10

# 4. Xem logs
docker logs LibreChat --tail 30

# 5. Test API
curl -s http://localhost:3080 | head -20
```


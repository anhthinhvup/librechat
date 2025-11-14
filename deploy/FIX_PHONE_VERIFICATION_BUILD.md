# Sửa Phone Verification - Container đã build

## Vấn đề

Container dùng image đã build sẵn, không có source code TypeScript/React. Frontend đã được build thành JavaScript trong `/app/client/dist`.

## Giải pháp

### Cách 1: Rebuild image với code mới (Đúng cách)

```bash
cd /opt/librechat

# Pull code mới (đã làm)
git pull origin master

# Build lại image với code mới
docker-compose build --no-cache api

# Hoặc nếu có Dockerfile.multi
docker build -f Dockerfile.multi --target node -t librechat-api:local .

# Start lại
docker-compose up -d
```

### Cách 2: Sửa file JavaScript đã build (Tạm thời)

```bash
# Tìm file JavaScript đã build
docker exec LibreChat-API find /app/client/dist -name "*.js" -type f | grep -i registration

# Hoặc tìm trong assets
docker exec LibreChat-API ls -la /app/client/dist/assets/

# Sửa file JavaScript (tìm và thay thế)
docker exec LibreChat-API sh -c "find /app/client/dist -name '*.js' -exec sed -i \"s/phone.*optional/\/\*phone.*optional\*\//g\" {} \;"
```

### Cách 3: Mount source code vào container (Development)

Sửa `docker-compose.yml` để mount source code:

```yaml
volumes:
  - ./client/src:/app/client/src
```

Sau đó rebuild.

### Cách 4: Tắt hoàn toàn ở backend (Khuyến nghị)

Vì đã có `ENABLE_PHONE_VERIFICATION=false`, backend sẽ không gửi OTP. Chỉ cần ẩn field ở frontend bằng cách sửa file đã build hoặc rebuild.

## Kiểm tra cấu trúc container

```bash
# Xem cấu trúc
docker exec LibreChat-API ls -la /app/client/

# Xem file đã build
docker exec LibreChat-API ls -la /app/client/dist/assets/ | head -20

# Tìm file có chứa "phone"
docker exec LibreChat-API grep -r "phone" /app/client/dist/assets/ | head -5
```


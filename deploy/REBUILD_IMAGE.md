# Build lại Image với code mới

## Bước 1: Pull code mới (nếu chưa)

```bash
cd /opt/librechat

# Pull code mới từ GitHub
git pull origin master
```

## Bước 2: Build image

```bash
cd /opt/librechat

# Build image với Dockerfile.multi, target api-build
docker build -f Dockerfile.multi --target api-build -t librechat-api:local .

# Hoặc build với cache (nhanh hơn)
docker build -f Dockerfile.multi --target api-build -t librechat-api:local --cache-from librechat-api:local .
```

## Bước 3: Tạo docker-compose.override.yaml

```bash
cd /opt/librechat

# Tạo override file để dùng image local
cat > docker-compose.override.yaml << 'EOF'
services:
  api:
    image: librechat-api:local
    build:
      context: .
      dockerfile: Dockerfile.multi
      target: api-build
EOF
```

## Bước 4: Restart containers

```bash
cd /opt/librechat

# Stop containers
docker-compose down

# Start lại với image mới
docker-compose up -d

# Kiểm tra
docker ps | grep LibreChat
docker logs LibreChat --tail 20
```

## Kiểm tra code mới đã có

```bash
# Kiểm tra phone field đã bị comment trong code
docker exec LibreChat grep -A 5 "phone.*optional" /app/client/src/components/Auth/Registration.tsx 2>/dev/null || echo "File source không có trong container (đã build)"

# Kiểm tra file đã build - phone field không còn
docker exec LibreChat grep -i "phone" /app/client/dist/assets/*.js 2>/dev/null | head -5
```

## Lưu ý

- Build có thể mất 10-30 phút tùy máy
- Cần đủ RAM (tối thiểu 4GB) để build
- Nếu build lỗi, kiểm tra logs: `docker build ... 2>&1 | tee build.log`


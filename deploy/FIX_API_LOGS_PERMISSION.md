# Sửa lỗi Permission cho /app/api/logs/

## Vấn đề

Container không thể tạo `/app/api/logs/` vì permission denied, khiến container restart liên tục.

## Giải pháp

### Cách 1: Tạo thư mục và mount volume (Khuyến nghị)

```bash
cd /opt/librechat

# 1. Tạo thư mục api/logs trên host
mkdir -p api/logs

# 2. Set quyền theo UID/GID (1000:1000)
chown -R 1000:1000 api/logs
chmod -R 755 api/logs

# 3. Tạo hoặc cập nhật docker-compose.override.yaml
cat > docker-compose.override.yaml << 'EOF'
services:
  api:
    volumes:
      - ./api/logs:/app/api/logs
EOF

# 4. Restart container
docker-compose down
docker-compose up -d

# 5. Kiểm tra
docker ps | grep LibreChat
docker logs LibreChat --tail 20
```

### Cách 2: Sửa quyền trong container (Tạm thời)

```bash
# Stop container
docker stop LibreChat

# Start với quyền root tạm thời để tạo thư mục
docker run --rm --user root -v $(pwd)/api/logs:/app/api/logs ghcr.io/danny-avila/librechat-dev:latest sh -c "mkdir -p /app/api/logs && chown -R 1000:1000 /app/api/logs"

# Hoặc mount và sửa quyền
mkdir -p api/logs
chmod -R 777 api/logs
```

## Kiểm tra sau khi sửa

```bash
# Container đã chạy ổn
docker ps | grep LibreChat

# Không còn lỗi permission
docker logs LibreChat --tail 20 | grep -i "permission\|EACCES"

# Thư mục logs đã được tạo
ls -la api/logs/
```


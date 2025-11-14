# Sửa lỗi Permission Denied cho /app/logs/

## Vấn đề

Container không có quyền ghi vào `/app/logs/error-2025-11-14.log`

## Giải pháp

### Cách 1: Sửa quyền trong container

```bash
cd /opt/librechat

# Vào container và sửa quyền
docker exec -it LibreChat sh -c "mkdir -p /app/logs && chmod 777 /app/logs"

# Hoặc chown cho user node (nếu có)
docker exec -it LibreChat sh -c "chown -R node:node /app/logs 2>/dev/null || chmod -R 777 /app/logs"
```

### Cách 2: Tạo volume mount cho logs

Sửa `docker-compose.yml`:

```yaml
volumes:
  - ./logs:/app/logs
```

Sau đó:
```bash
mkdir -p logs
chmod 777 logs
docker-compose restart api
```

### Cách 3: Tắt logging (tạm thời)

Sửa trong code hoặc env để không ghi log file.

### Cách 4: Sửa quyền trước khi start

```bash
cd /opt/librechat

# Stop container
docker stop LibreChat

# Sửa quyền trong image hoặc mount
# Sau đó start lại
docker start LibreChat
```


# Sửa lỗi Permission - Stop và Start lại

## Vấn đề

Container đang restarting nên không thể exec vào.

## Giải pháp

### Cách 1: Stop, sửa quyền, start lại

```bash
cd /opt/librechat

# Stop container
docker stop LibreChat

# Start lại với quyền mới (sẽ tự tạo logs với quyền đúng)
docker start LibreChat

# Nếu vẫn lỗi, sửa quyền khi container đang chạy
docker exec LibreChat sh -c "mkdir -p /app/logs && chmod 777 /app/logs"
```

### Cách 2: Mount volume cho logs (Tốt nhất)

```bash
cd /opt/librechat

# Tạo thư mục logs trên host
mkdir -p logs
chmod 777 logs

# Sửa docker-compose.yml
# Tìm phần volumes của service api và thêm:
#   - ./logs:/app/logs

# Stop và start lại
docker-compose down
docker-compose up -d
```

### Cách 3: Sửa trong Dockerfile (Nếu build lại)

Thêm vào Dockerfile:
```dockerfile
RUN mkdir -p /app/logs && chmod 777 /app/logs
```


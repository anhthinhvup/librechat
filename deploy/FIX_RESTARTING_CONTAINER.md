# Sửa Container đang Restarting

## Kiểm tra lỗi

```bash
cd /opt/librechat

# Xem logs để biết lỗi
docker logs LibreChat --tail 50

# Hoặc
docker-compose logs api --tail 50
```

## Sửa lỗi thường gặp

### Lỗi 1: Port đã được sử dụng

```bash
# Kiểm tra port 3080
netstat -tlnp | grep 3080
# Hoặc
ss -tlnp | grep 3080

# Kill process đang dùng port
# Hoặc đổi PORT trong .env
```

### Lỗi 2: File .env không đúng format

```bash
# Kiểm tra .env
cat .env | grep -v "^#" | grep "="

# Kiểm tra có dòng trống hoặc format sai không
```

### Lỗi 3: Volume mount lỗi

```bash
# Kiểm tra volumes
docker inspect LibreChat | grep -A 20 Mounts

# Kiểm tra file .env có tồn tại không
ls -la .env
```

## Sau khi sửa lỗi

```bash
# Stop container
docker stop LibreChat

# Start lại
docker-compose up -d api

# Hoặc
docker start LibreChat
```


# Sửa lỗi Permission cho logs - Volume đã mount

## Vấn đề

Docker-compose.yml đã có mount `./logs:/app/logs` nhưng thư mục logs trên host chưa có hoặc không đủ quyền.

## Giải pháp

```bash
cd /opt/librechat

# Tạo thư mục logs trên host
mkdir -p logs

# Set quyền cho thư mục logs
chmod 777 logs

# Restart container để mount lại
docker-compose restart api

# Kiểm tra container đã chạy ổn
docker ps | grep LibreChat

# Kiểm tra logs không còn lỗi permission
docker logs LibreChat --tail 20
```

## Kiểm tra logs đã được ghi

```bash
# Xem file log trên host
ls -la logs/

# Xem nội dung log
tail -f logs/error-*.log
```


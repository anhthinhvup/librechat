# Hướng dẫn kiểm tra SMS Logs

## Vấn đề: Không tìm thấy docker-compose.yml

Lỗi này xảy ra khi bạn không ở đúng thư mục dự án.

## Giải pháp

### Bước 1: Tìm thư mục dự án LibreChat

```bash
# Tìm thư mục có file docker-compose.yml
find / -name "docker-compose.yml" -path "*/LibreChat*" 2>/dev/null

# Hoặc tìm thư mục có file .env
find / -name ".env" -path "*librechat*" 2>/dev/null | head -1

# Hoặc tìm container LibreChat
docker ps | grep -i librechat
```

### Bước 2: Vào thư mục dự án

Thường thì thư mục dự án sẽ ở một trong các vị trí sau:

```bash
# Nếu cài ở /opt
cd /opt/librechat

# Nếu cài ở home
cd ~/librechat

# Nếu cài ở /var/www
cd /var/www/librechat

# Nếu dùng git clone
cd ~/LibreChat-main
```

### Bước 3: Kiểm tra đã vào đúng thư mục

```bash
# Kiểm tra có file docker-compose.yml không
ls -la docker-compose.yml

# Hoặc
test -f docker-compose.yml && echo "OK" || echo "Không tìm thấy"
```

### Bước 4: Xem logs SMS

```bash
# Xem logs của service api
docker-compose logs -f api | grep SMSService

# Hoặc xem tất cả logs của api
docker-compose logs -f api

# Hoặc dùng docker trực tiếp (nếu biết tên container)
docker logs -f LibreChat | grep SMSService
```

## Các lệnh hữu ích khác

### Tìm container đang chạy

```bash
# Xem tất cả container
docker ps

# Xem container LibreChat
docker ps | grep -i librechat

# Xem logs trực tiếp từ container
docker logs -f LibreChat
```

### Kiểm tra cấu hình SMS

```bash
# Vào thư mục dự án
cd /opt/librechat  # hoặc thư mục của bạn

# Kiểm tra file .env có cấu hình SMS không
grep -i "SMS\|TWILIO" .env

# Xem cấu hình Twilio
grep "TWILIO" .env
```

### Restart service

```bash
# Vào thư mục dự án
cd /opt/librechat  # hoặc thư mục của bạn

# Restart API service
docker-compose restart api

# Hoặc restart tất cả
docker-compose restart
```

## Script tự động tìm và kiểm tra

Tạo file `check-sms.sh`:

```bash
#!/bin/bash

# Tìm thư mục dự án
PROJECT_DIR=$(find /opt /home /var/www -name "docker-compose.yml" -path "*librechat*" 2>/dev/null | head -1 | xargs dirname)

if [ -z "$PROJECT_DIR" ]; then
    # Thử tìm container
    CONTAINER=$(docker ps --format "{{.Names}}" | grep -i librechat | head -1)
    if [ -n "$CONTAINER" ]; then
        echo "Tìm thấy container: $CONTAINER"
        echo "Xem logs:"
        docker logs -f "$CONTAINER" | grep SMSService
        exit 0
    fi
    echo "❌ Không tìm thấy thư mục dự án LibreChat"
    echo "Hãy cd vào thư mục có file docker-compose.yml"
    exit 1
fi

echo "✅ Tìm thấy thư mục: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

echo "📋 Kiểm tra cấu hình SMS:"
grep -i "SMS\|TWILIO" .env || echo "⚠️  Chưa có cấu hình SMS"

echo ""
echo "📊 Xem logs SMS:"
docker-compose logs -f api | grep SMSService
```

Chạy:
```bash
chmod +x check-sms.sh
./check-sms.sh
```

## Troubleshooting

### Nếu không tìm thấy docker-compose.yml

1. **Kiểm tra đã cài đặt chưa:**
   ```bash
   docker ps | grep librechat
   ```

2. **Tìm container đang chạy:**
   ```bash
   docker ps --format "{{.Names}}"
   ```

3. **Xem logs trực tiếp từ container:**
   ```bash
   docker logs -f <container_name> | grep SMSService
   ```

### Nếu không có quyền

```bash
# Thử với sudo
sudo docker-compose logs -f api | grep SMSService

# Hoặc
sudo docker logs -f LibreChat | grep SMSService
```

## Ví dụ đầy đủ

```bash
# 1. Tìm thư mục
cd /opt/librechat

# 2. Kiểm tra đã vào đúng
ls docker-compose.yml

# 3. Xem logs
docker-compose logs -f api | grep SMSService
```


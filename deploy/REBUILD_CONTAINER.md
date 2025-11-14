# Hướng dẫn Rebuild Docker Container

## Cách 1: Restart đơn giản (Khuyến nghị)

Vì file `.env` được mount vào container, chỉ cần restart:

```bash
cd /opt/librechat

# Restart API container
docker-compose restart api

# Hoặc restart tất cả
docker-compose restart
```

## Cách 2: Rebuild với pull image mới

```bash
cd /opt/librechat

# Pull image mới nhất
docker-compose pull api

# Restart với image mới
docker-compose up -d api
```

## Cách 3: Rebuild hoàn toàn (nếu có thay đổi code)

```bash
cd /opt/librechat

# Stop containers
docker-compose down

# Pull image mới
docker-compose pull api

# Start lại
docker-compose up -d

# Hoặc rebuild từ đầu (nếu có Dockerfile)
docker-compose build --no-cache api
docker-compose up -d
```

## Cách 4: Rebuild nhanh (một lệnh)

```bash
cd /opt/librechat && docker-compose down && docker-compose pull api && docker-compose up -d
```

## Kiểm tra sau khi rebuild

```bash
# Xem containers đang chạy
docker-compose ps

# Xem logs
docker-compose logs -f api

# Kiểm tra phone verification đã tắt
docker-compose logs api | grep "Phone verification is disabled"
```

## Lưu ý

- **Restart** thường đủ vì `.env` được mount vào container
- **Rebuild** chỉ cần khi có thay đổi code hoặc muốn pull image mới
- **Build từ đầu** chỉ cần khi có Dockerfile và muốn build local


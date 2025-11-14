# Sửa lỗi Rebuild - Pull Image Failed

## Vấn đề

Lỗi `pull access denied` xảy ra khi Docker không tìm thấy image hoặc cần authentication.

## Giải pháp

### Cách 1: Start lại container (Đơn giản nhất)

Vì `.env` đã được mount, chỉ cần start lại:

```bash
cd /opt/librechat

# Start lại container api
docker-compose up -d api

# Hoặc start tất cả
docker-compose up -d
```

### Cách 2: Kiểm tra image name trong docker-compose.yml

```bash
cd /opt/librechat

# Xem image name
grep "image:" docker-compose.yml

# Nếu dùng image từ GitHub Container Registry
# Image name sẽ là: ghcr.io/danny-avila/librechat-dev:latest
```

### Cách 3: Pull image thủ công (nếu cần)

```bash
# Pull image trực tiếp
docker pull ghcr.io/danny-avila/librechat-dev:latest

# Sau đó start
docker-compose up -d
```

### Cách 4: Kiểm tra container đang chạy

```bash
# Xem containers
docker-compose ps

# Nếu api chưa chạy, start lại
docker-compose up -d api

# Xem logs
docker-compose logs -f api
```

## Lưu ý

- Lỗi pull không ảnh hưởng nếu image đã có sẵn trên server
- Chỉ cần `docker-compose up -d` để start lại containers
- File `.env` đã được mount, không cần rebuild


# Hướng dẫn Deploy LibreChat - Tóm tắt nhanh

## Thông tin
- **Domain**: `chat.daydemy.com`
- **Server**: `88.99.26.236`
- **Domain hiện có**: `langhit.com` (đã deploy)
- **Port LibreChat**: `3080` (localhost only)

## Cách deploy nhanh nhất

### Trên máy local (Windows)

1. **Upload code lên server:**
```powershell
# Sử dụng SCP (cần cài OpenSSH hoặc WinSCP)
scp -r E:\LibreChat-main\LibreChat-main\* root@88.99.26.236:/opt/librechat/
```

Hoặc sử dụng WinSCP, FileZilla để upload thư mục `LibreChat-main` lên `/opt/librechat/`

### Trên server (SSH vào server)

```bash
# 1. SSH vào server
ssh root@88.99.26.236

# 2. Chạy script tự động (khuyến nghị)
cd /opt/librechat
chmod +x deploy/DEPLOY_MULTI_SITE.sh
./deploy/DEPLOY_MULTI_SITE.sh
```

Script sẽ tự động:
- Kiểm tra port của langhit.com
- Tạo thư mục cần thiết
- Cấu hình Nginx cho cả 2 domain
- Tạo SSL certificate
- Deploy Docker containers

### Hoặc deploy thủ công

Xem file: `DEPLOY_CHAT_DAYDEMY.md` để có hướng dẫn chi tiết từng bước.

## Kiểm tra sau khi deploy

```bash
# Kiểm tra containers
docker-compose ps

# Kiểm tra logs
docker-compose logs -f api

# Test API
curl http://localhost:3080/api/health

# Test từ browser
# Mở: https://chat.daydemy.com
```

## Cấu hình quan trọng

### 1. File .env
Phải có các giá trị:
- `JWT_SECRET` (generate: `openssl rand -base64 32`)
- `JWT_REFRESH_SECRET` (generate: `openssl rand -base64 32`)
- `MEILI_MASTER_KEY` (generate: `openssl rand -base64 32`)
- `DOMAIN_CLIENT=https://chat.daydemy.com`
- `DOMAIN_SERVER=https://chat.daydemy.com`

### 2. Google OAuth
Cập nhật redirect URI trong Google Cloud Console:
```
https://chat.daydemy.com/oauth/google/callback
```

### 3. DNS
Đảm bảo `chat.daydemy.com` đã trỏ về `88.99.26.236`

## Files quan trọng

- `deploy/DEPLOY_MULTI_SITE.sh` - Script tự động deploy
- `deploy/DEPLOY_CHAT_DAYDEMY.md` - Hướng dẫn chi tiết
- `deploy/nginx-reverse-proxy.conf` - Cấu hình Nginx cho cả 2 domain
- `deploy/docker-compose.production.yml` - Docker Compose config
- `deploy/env.production` - Template file .env

## Troubleshooting

### Port 3080 đã được sử dụng
```bash
lsof -i :3080
# Kill process hoặc thay đổi port trong docker-compose.yml
```

### Nginx không proxy được
```bash
tail -f /var/log/nginx/error.log
docker-compose logs api
```

### Container không start
```bash
docker-compose logs
docker-compose down
docker-compose up -d
```

## Liên kết

- LibreChat: https://chat.daydemy.com
- Langhit: https://langhit.com
- Server: 88.99.26.236






# Quick Start - Deploy LibreChat lên Hetzner

## Domain
- **Domain**: `chat.daydemy.com`
- **Server IP**: `88.99.26.236`
- **Port**: `3080` (internal, chỉ accessible từ localhost)

## Các bước deploy nhanh

### 1. Trên Server Hetzner

```bash
# Kết nối vào server
ssh root@88.99.26.236

# Tạo thư mục
mkdir -p /opt/librechat
cd /opt/librechat
```

### 2. Clone code từ GitHub

```bash
# Clone repository LibreChat
git clone https://github.com/danny-avila/LibreChat.git /opt/librechat
cd /opt/librechat
```

**Lưu ý**: Nếu bạn đã có code đã chỉnh sửa trên máy local, có thể:
- Option 1: Upload bằng SCP/SFTP
- Option 2: Tạo fork trên GitHub và clone fork của bạn
- Option 3: Clone và sau đó copy các file đã chỉnh sửa vào

### 3. Tạo file .env

```bash
cd /opt/librechat
cp deploy/env.production .env
nano .env
```

**QUAN TRỌNG**: Cần generate các random strings:
```bash
# Tạo JWT_SECRET
openssl rand -base64 32

# Tạo JWT_REFRESH_SECRET
openssl rand -base64 32

# Tạo MEILI_MASTER_KEY
openssl rand -base64 32
```

Cập nhật vào file `.env`:
- `JWT_SECRET=...`
- `JWT_REFRESH_SECRET=...`
- `MEILI_MASTER_KEY=...`

### 4. Tạo SSL Certificate

```bash
# Cài đặt certbot (nếu chưa có)
apt update
apt install certbot python3-certbot-nginx -y

# Tạo SSL certificate
certbot certonly --nginx -d chat.daydemy.com
```

### 5. Cấu hình Nginx

```bash
# Copy cấu hình Nginx
cp deploy/nginx-librechat.conf /etc/nginx/sites-available/librechat

# Enable site
ln -s /etc/nginx/sites-available/librechat /etc/nginx/sites-enabled/

# Test và reload
nginx -t
systemctl reload nginx
```

### 6. Tạo thư mục và set permissions

```bash
mkdir -p images uploads logs data-node meili_data_v1.12
chown -R 1000:1000 images uploads logs data-node meili_data_v1.12
```

### 7. Deploy với Docker Compose

```bash
# Copy docker-compose file
cp deploy/docker-compose.production.yml docker-compose.yml

# Start services
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f api
```

### 8. Cấu hình Google OAuth

**QUAN TRỌNG**: Cần cập nhật Google OAuth redirect URI:

1. Vào: https://console.cloud.google.com/apis/credentials
2. Mở OAuth Client ID: `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com`
3. Trong "Authorized redirect URIs", thêm:
   ```
   https://chat.daydemy.com/oauth/google/callback
   ```
4. Click "Lưu" (Save)

### 9. Kiểm tra

```bash
# Kiểm tra container
docker-compose ps

# Kiểm tra port
netstat -tlnp | grep 3080

# Test từ server
curl http://localhost:3080/api/health

# Test từ browser
# Mở: https://chat.daydemy.com
```

## Lưu ý quan trọng

1. **Domain DNS**: Đảm bảo `chat.daydemy.com` đã trỏ về IP `88.99.26.236`
2. **Port 3080**: Chỉ expose trên localhost, không expose ra ngoài
3. **SSL Certificate**: Cần có SSL certificate trước khi start Nginx
4. **Google OAuth**: Phải cập nhật redirect URI trong Google Cloud Console
5. **JWT Secrets**: Phải generate random strings, không dùng giá trị mặc định
6. **Permissions**: Đảm bảo thư mục có đúng permissions (1000:1000)

## Troubleshooting

### Port 3080 đã được sử dụng
```bash
lsof -i :3080
# Kill process hoặc thay đổi port
```

### Nginx không proxy được
```bash
# Kiểm tra logs
tail -f /var/log/nginx/error.log

# Kiểm tra LibreChat
docker-compose logs api
```

### SSL Certificate không hoạt động
```bash
# Kiểm tra certificate
certbot certificates

# Renew
certbot renew
```

## Files quan trọng

- `/opt/librechat/.env` - Environment variables
- `/opt/librechat/docker-compose.yml` - Docker Compose config
- `/opt/librechat/librechat.yaml` - LibreChat config
- `/etc/nginx/sites-available/librechat` - Nginx config
- `/etc/letsencrypt/live/chat.daydemy.com/` - SSL certificates

## Liên kết

- Domain: https://chat.daydemy.com
- Server: 88.99.26.236
- Google OAuth: https://console.cloud.google.com/apis/credentials


## Domain
- **Domain**: `chat.daydemy.com`
- **Server IP**: `88.99.26.236`
- **Port**: `3080` (internal, chỉ accessible từ localhost)

## Các bước deploy nhanh

### 1. Trên Server Hetzner

```bash
# Kết nối vào server
ssh root@88.99.26.236

# Tạo thư mục
mkdir -p /opt/librechat
cd /opt/librechat
```

### 2. Clone code từ GitHub

```bash
# Clone repository LibreChat
git clone https://github.com/danny-avila/LibreChat.git /opt/librechat
cd /opt/librechat
```

**Lưu ý**: Nếu bạn đã có code đã chỉnh sửa trên máy local, có thể:
- Option 1: Upload bằng SCP/SFTP
- Option 2: Tạo fork trên GitHub và clone fork của bạn
- Option 3: Clone và sau đó copy các file đã chỉnh sửa vào

### 3. Tạo file .env

```bash
cd /opt/librechat
cp deploy/env.production .env
nano .env
```

**QUAN TRỌNG**: Cần generate các random strings:
```bash
# Tạo JWT_SECRET
openssl rand -base64 32

# Tạo JWT_REFRESH_SECRET
openssl rand -base64 32

# Tạo MEILI_MASTER_KEY
openssl rand -base64 32
```

Cập nhật vào file `.env`:
- `JWT_SECRET=...`
- `JWT_REFRESH_SECRET=...`
- `MEILI_MASTER_KEY=...`

### 4. Tạo SSL Certificate

```bash
# Cài đặt certbot (nếu chưa có)
apt update
apt install certbot python3-certbot-nginx -y

# Tạo SSL certificate
certbot certonly --nginx -d chat.daydemy.com
```

### 5. Cấu hình Nginx

```bash
# Copy cấu hình Nginx
cp deploy/nginx-librechat.conf /etc/nginx/sites-available/librechat

# Enable site
ln -s /etc/nginx/sites-available/librechat /etc/nginx/sites-enabled/

# Test và reload
nginx -t
systemctl reload nginx
```

### 6. Tạo thư mục và set permissions

```bash
mkdir -p images uploads logs data-node meili_data_v1.12
chown -R 1000:1000 images uploads logs data-node meili_data_v1.12
```

### 7. Deploy với Docker Compose

```bash
# Copy docker-compose file
cp deploy/docker-compose.production.yml docker-compose.yml

# Start services
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f api
```

### 8. Cấu hình Google OAuth

**QUAN TRỌNG**: Cần cập nhật Google OAuth redirect URI:

1. Vào: https://console.cloud.google.com/apis/credentials
2. Mở OAuth Client ID: `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com`
3. Trong "Authorized redirect URIs", thêm:
   ```
   https://chat.daydemy.com/oauth/google/callback
   ```
4. Click "Lưu" (Save)

### 9. Kiểm tra

```bash
# Kiểm tra container
docker-compose ps

# Kiểm tra port
netstat -tlnp | grep 3080

# Test từ server
curl http://localhost:3080/api/health

# Test từ browser
# Mở: https://chat.daydemy.com
```

## Lưu ý quan trọng

1. **Domain DNS**: Đảm bảo `chat.daydemy.com` đã trỏ về IP `88.99.26.236`
2. **Port 3080**: Chỉ expose trên localhost, không expose ra ngoài
3. **SSL Certificate**: Cần có SSL certificate trước khi start Nginx
4. **Google OAuth**: Phải cập nhật redirect URI trong Google Cloud Console
5. **JWT Secrets**: Phải generate random strings, không dùng giá trị mặc định
6. **Permissions**: Đảm bảo thư mục có đúng permissions (1000:1000)

## Troubleshooting

### Port 3080 đã được sử dụng
```bash
lsof -i :3080
# Kill process hoặc thay đổi port
```

### Nginx không proxy được
```bash
# Kiểm tra logs
tail -f /var/log/nginx/error.log

# Kiểm tra LibreChat
docker-compose logs api
```

### SSL Certificate không hoạt động
```bash
# Kiểm tra certificate
certbot certificates

# Renew
certbot renew
```

## Files quan trọng

- `/opt/librechat/.env` - Environment variables
- `/opt/librechat/docker-compose.yml` - Docker Compose config
- `/opt/librechat/librechat.yaml` - LibreChat config
- `/etc/nginx/sites-available/librechat` - Nginx config
- `/etc/letsencrypt/live/chat.daydemy.com/` - SSL certificates

## Liên kết

- Domain: https://chat.daydemy.com
- Server: 88.99.26.236
- Google OAuth: https://console.cloud.google.com/apis/credentials



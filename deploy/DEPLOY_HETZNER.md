# Hướng dẫn Deploy LibreChat lên Hetzner Server

## Yêu cầu
- Server Hetzner: IP `88.99.26.236`
- Domain: `chat.daydemy.com` đã trỏ về IP `88.99.26.236`
- Nginx đã cài đặt trên server
- Docker và Docker Compose đã cài đặt
- Certbot (Let's Encrypt) đã cài đặt (để tạo SSL certificate)

## Bước 1: Chuẩn bị trên Server Hetzner

### 1.1. Kết nối vào server
```bash
ssh root@88.99.26.236
```

### 1.2. Tạo thư mục cho LibreChat
```bash
mkdir -p /opt/librechat
cd /opt/librechat
```

### 1.3. Clone code LibreChat từ GitHub
```bash
# Clone repository LibreChat từ GitHub
git clone https://github.com/danny-avila/LibreChat.git .

# Hoặc nếu muốn clone vào thư mục khác, sau đó copy
# git clone https://github.com/danny-avila/LibreChat.git /tmp/LibreChat
# cp -r /tmp/LibreChat/* /opt/librechat/
# cp -r /tmp/LibreChat/.* /opt/librechat/ 2>/dev/null || true

# Kiểm tra đã clone thành công
ls -la
```

## Bước 2: Cấu hình Environment Variables

### 2.1. Tạo file .env
```bash
cd /opt/librechat
cp env.example .env
nano .env
```

### 2.2. Cấu hình .env với các giá trị sau:
```env
# Basic Configuration
PORT=3080
HOST=0.0.0.0
NODE_ENV=production

# Domain Configuration
DOMAIN_CLIENT=https://chat.daydemy.com
DOMAIN_SERVER=https://chat.daydemy.com

# Database
MONGO_URI=mongodb://mongodb:27017/LibreChat

# Meilisearch
MEILI_HOST=http://meilisearch:7700
MEILI_MASTER_KEY=your_secure_random_master_key_here

# RAG API
RAG_PORT=8000
RAG_API_URL=http://rag_api:8000

# JWT Secrets (TẠO RANDOM STRINGS)
JWT_SECRET=your_jwt_secret_secure_random_string
JWT_REFRESH_SECRET=your_jwt_refresh_secret_secure_random_string

# Registration
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=true
ALLOW_SOCIAL_REGISTRATION=true

# Google OAuth (THAY ĐỔI VỚI CREDENTIALS CỦA BẠN)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=/oauth/google/callback

# API Keys
OPENAI_API_KEY=sk-SL4FdpsAirJCaVYeapOOFvi6Xy99Iwz7IjmvK2mGVT1oZWPU
OPENAI_REVERSE_PROXY=https://langhit.com/v1
OPENAI_API_BASE_URL=https://langhit.com/v1
OPENAI_MODELS=gpt-4o-mini-2024-07-18,gpt-4.1-mini,gpt-5-nano-2025-08-07

# Docker User (Linux)
UID=1000
GID=1000
```

### 2.3. Tạo random strings cho JWT secrets
```bash
# Tạo JWT_SECRET
openssl rand -base64 32

# Tạo JWT_REFRESH_SECRET
openssl rand -base64 32

# Tạo MEILI_MASTER_KEY
openssl rand -base64 32
```

## Bước 3: Cấu hình Nginx Reverse Proxy

### 3.1. Copy file cấu hình Nginx
```bash
# Copy file nginx-librechat.conf vào server
# Sửa domain name trong file
nano /opt/librechat/deploy/nginx-librechat.conf
```

### 3.2. Kiểm tra domain name trong file
- Domain đã được cấu hình: `chat.daydemy.com`
- Đường dẫn SSL certificate: `/etc/letsencrypt/live/chat.daydemy.com/`

### 3.3. Tạo SSL Certificate với Let's Encrypt
```bash
# Cài đặt Certbot (nếu chưa có)
apt update
apt install certbot python3-certbot-nginx -y

# Tạo SSL certificate cho domain LibreChat
certbot certonly --nginx -d chat.daydemy.com

# Hoặc nếu dùng standalone (khi Nginx chưa chạy)
certbot certonly --standalone -d chat.daydemy.com
```

### 3.4. Copy cấu hình Nginx vào sites-available
```bash
cp /opt/librechat/deploy/nginx-librechat.conf /etc/nginx/sites-available/librechat
```

### 3.5. Kiểm tra đường dẫn SSL certificate trong file
```bash
nano /etc/nginx/sites-available/librechat
# Đường dẫn SSL certificate đã được cấu hình: /etc/letsencrypt/live/chat.daydemy.com/
```

### 3.6. Kích hoạt site
```bash
ln -s /etc/nginx/sites-available/librechat /etc/nginx/sites-enabled/
```

### 3.7. Test cấu hình Nginx
```bash
nginx -t
```

### 3.8. Reload Nginx
```bash
systemctl reload nginx
```

## Bước 4: Deploy LibreChat với Docker Compose

### 4.1. Copy docker-compose.production.yml
```bash
cp /opt/librechat/deploy/docker-compose.production.yml /opt/librechat/docker-compose.yml
```

### 4.2. Kiểm tra file librechat.yaml
```bash
# Đảm bảo file librechat.yaml tồn tại
ls -la /opt/librechat/librechat.yaml
```

### 4.3. Tạo các thư mục cần thiết
```bash
mkdir -p /opt/librechat/images
mkdir -p /opt/librechat/uploads
mkdir -p /opt/librechat/logs
mkdir -p /opt/librechat/data-node
mkdir -p /opt/librechat/meili_data_v1.12
```

### 4.4. Set permissions
```bash
chown -R 1000:1000 /opt/librechat/images
chown -R 1000:1000 /opt/librechat/uploads
chown -R 1000:1000 /opt/librechat/logs
chown -R 1000:1000 /opt/librechat/data-node
chown -R 1000:1000 /opt/librechat/meili_data_v1.12
```

### 4.5. Start Docker Compose
```bash
cd /opt/librechat
docker-compose up -d
```

### 4.6. Kiểm tra logs
```bash
docker-compose logs -f api
```

## Bước 5: Cấu hình Google OAuth cho Production

### 5.1. Cập nhật Google Cloud Console
1. Vào: https://console.cloud.google.com/apis/credentials
2. Mở OAuth Client ID của bạn
3. Trong "Authorized redirect URIs", thêm:
   ```
   https://chat.daydemy.com/oauth/google/callback
   ```
4. Click "Lưu" (Save)

### 5.2. Cập nhật OAuth Consent Screen
1. Vào: https://console.cloud.google.com/apis/credentials/consent
2. Thêm domain production vào "Authorized domains"
3. Thêm email test users (nếu đang ở chế độ testing)

## Bước 6: Kiểm tra và Test

### 6.1. Kiểm tra container đang chạy
```bash
docker-compose ps
```

### 6.2. Kiểm tra port 3080 đang listen
```bash
netstat -tlnp | grep 3080
```

### 6.3. Test từ server
```bash
curl http://localhost:3080/api/health
```

### 6.4. Test từ browser
- Mở browser và truy cập: `https://chat.daydemy.com`
- Kiểm tra đăng ký và đăng nhập bằng Google

## Bước 7: Cấu hình Auto-renewal SSL Certificate

### 7.1. Test auto-renewal
```bash
certbot renew --dry-run
```

### 7.2. Cấu hình cron job (tự động renew)
```bash
# Certbot thường tự động cấu hình, kiểm tra:
systemctl status certbot.timer
```

## Troubleshooting

### Lỗi: Port 3080 đã được sử dụng
```bash
# Kiểm tra process đang dùng port 3080
lsof -i :3080

# Hoặc
netstat -tlnp | grep 3080

# Dừng process hoặc thay đổi port trong docker-compose.yml
```

### Lỗi: Nginx không proxy được
```bash
# Kiểm tra Nginx logs
tail -f /var/log/nginx/error.log

# Kiểm tra LibreChat có chạy không
docker-compose ps
docker-compose logs api
```

### Lỗi: SSL Certificate không hoạt động
```bash
# Kiểm tra certificate
certbot certificates

# Renew certificate
certbot renew
```

### Lỗi: Permission denied
```bash
# Set quyền cho thư mục
chown -R 1000:1000 /opt/librechat/images
chown -R 1000:1000 /opt/librechat/uploads
chown -R 1000:1000 /opt/librechat/logs
```

### Lỗi: MongoDB connection
```bash
# Kiểm tra MongoDB container
docker-compose logs mongodb

# Restart MongoDB
docker-compose restart mongodb
```

## Maintenance

### Update LibreChat
```bash
cd /opt/librechat
docker-compose pull
docker-compose up -d
```

### Backup Database
```bash
# Backup MongoDB
docker-compose exec mongodb mongodump --out /data/db/backup

# Copy backup ra ngoài
docker cp chat-mongodb:/data/db/backup /opt/librechat/backup-$(date +%Y%m%d)
```

### View Logs
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api
docker-compose logs -f mongodb
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart api
```

## Security Notes

1. **Firewall**: Đảm bảo chỉ mở port 80, 443, và SSH (22)
2. **SSL**: Luôn sử dụng HTTPS trong production
3. **Secrets**: Không commit file `.env` vào Git
4. **Updates**: Thường xuyên update Docker images và hệ thống
5. **Backup**: Backup database và files thường xuyên

## Liên kết hữu ích

- LibreChat Documentation: https://www.librechat.ai/docs
- Docker Compose Documentation: https://docs.docker.com/compose/
- Nginx Documentation: https://nginx.org/en/docs/
- Let's Encrypt Documentation: https://letsencrypt.org/docs/


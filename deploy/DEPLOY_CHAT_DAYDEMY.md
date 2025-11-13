# Hướng dẫn Deploy LibreChat lên Server 88.99.26.236

## Tổng quan
- **Domain LibreChat**: `chat.daydemy.com`
- **Domain hiện tại**: `langhit.com` (đã deploy)
- **Server IP**: `88.99.26.236`
- **Port LibreChat**: `3080` (chỉ expose trên localhost)
- **Port Langhit**: `3000` (giả định, cần kiểm tra port thực tế)

## Kiến trúc
```
Internet
   ↓
Nginx Reverse Proxy (Port 80/443)
   ├── langhit.com → localhost:3000
   └── chat.daydemy.com → localhost:3080
```

## Các bước triển khai

### Bước 1: Kết nối vào Server

```bash
ssh root@88.99.26.236
```

### Bước 2: Kiểm tra cấu hình Nginx hiện tại

```bash
# Xem cấu hình Nginx hiện tại cho langhit.com
cat /etc/nginx/sites-available/langhit
# hoặc
cat /etc/nginx/sites-enabled/langhit

# Kiểm tra port mà langhit.com đang chạy
netstat -tlnp | grep LISTEN
# Tìm port của langhit (thường là 3000, 8000, hoặc 8080)
```

**QUAN TRỌNG**: Ghi lại port mà langhit.com đang sử dụng để cập nhật vào file nginx-reverse-proxy.conf

### Bước 3: Tạo thư mục cho LibreChat

```bash
mkdir -p /opt/librechat
cd /opt/librechat
```

### Bước 4: Upload code lên server

Có 3 cách:

**Cách 1: Clone từ GitHub (nếu code đã push lên GitHub)**
```bash
git clone https://github.com/your-username/LibreChat.git /opt/librechat
cd /opt/librechat
```

**Cách 2: Upload bằng SCP từ máy local**
```bash
# Từ máy local (Windows PowerShell hoặc Git Bash)
scp -r E:\LibreChat-main\LibreChat-main\* root@88.99.26.236:/opt/librechat/
```

**Cách 3: Sử dụng rsync (nếu có)**
```bash
rsync -avz --progress E:\LibreChat-main\LibreChat-main\ root@88.99.26.236:/opt/librechat/
```

### Bước 5: Tạo file .env

```bash
cd /opt/librechat
cp deploy/env.production .env
nano .env
```

**QUAN TRỌNG**: Generate các secret keys:

```bash
# Tạo JWT_SECRET
openssl rand -base64 32

# Tạo JWT_REFRESH_SECRET  
openssl rand -base64 32

# Tạo MEILI_MASTER_KEY
openssl rand -base64 32
```

Cập nhật các giá trị này vào file `.env`:
- `JWT_SECRET=<giá trị vừa generate>`
- `JWT_REFRESH_SECRET=<giá trị vừa generate>`
- `MEILI_MASTER_KEY=<giá trị vừa generate>`

Kiểm tra các cấu hình khác trong `.env`:
- `DOMAIN_CLIENT=https://chat.daydemy.com`
- `DOMAIN_SERVER=https://chat.daydemy.com`
- `PORT=3080`

### Bước 6: Tạo SSL Certificate cho chat.daydemy.com

```bash
# Cài đặt certbot nếu chưa có
apt update
apt install certbot python3-certbot-nginx -y

# Tạo SSL certificate cho chat.daydemy.com
certbot certonly --nginx -d chat.daydemy.com

# Kiểm tra certificate
certbot certificates
```

### Bước 7: Cấu hình Nginx Reverse Proxy

Có 2 cách cấu hình:

#### Cách 1: Sử dụng file nginx-reverse-proxy.conf (Khuyến nghị)

File này sẽ cấu hình cả langhit.com và chat.daydemy.com:

```bash
# Backup cấu hình Nginx hiện tại
cp /etc/nginx/sites-available/langhit /etc/nginx/sites-available/langhit.backup

# Cập nhật port của langhit trong file nginx-reverse-proxy.conf
cd /opt/librechat
nano deploy/nginx-reverse-proxy.conf
# Tìm dòng: server 127.0.0.1:3000;
# Thay đổi 3000 thành port thực tế của langhit.com

# Copy file cấu hình
cp deploy/nginx-reverse-proxy.conf /etc/nginx/sites-available/multi-site

# Enable site
ln -sf /etc/nginx/sites-available/multi-site /etc/nginx/sites-enabled/multi-site

# Disable site cũ của langhit (nếu có)
# rm /etc/nginx/sites-enabled/langhit

# Test cấu hình
nginx -t

# Reload Nginx
systemctl reload nginx
```

#### Cách 2: Thêm cấu hình riêng cho chat.daydemy.com

Nếu muốn giữ nguyên cấu hình langhit.com và chỉ thêm chat.daydemy.com:

```bash
# Copy cấu hình LibreChat
cp /opt/librechat/deploy/nginx-librechat.conf /etc/nginx/sites-available/librechat

# Enable site
ln -s /etc/nginx/sites-available/librechat /etc/nginx/sites-enabled/

# Test và reload
nginx -t
systemctl reload nginx
```

### Bước 8: Tạo thư mục và set permissions

```bash
cd /opt/librechat
mkdir -p images uploads logs data-node meili_data_v1.12
chown -R 1000:1000 images uploads logs data-node meili_data_v1.12
```

### Bước 9: Kiểm tra Docker và Docker Compose

```bash
# Kiểm tra Docker
docker --version
docker-compose --version

# Nếu chưa cài, cài đặt:
# apt update
# apt install docker.io docker-compose -y
# systemctl start docker
# systemctl enable docker
```

### Bước 10: Deploy với Docker Compose

```bash
cd /opt/librechat

# Copy docker-compose file
cp deploy/docker-compose.production.yml docker-compose.yml

# Start services
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f api
```

### Bước 11: Kiểm tra các container

```bash
# Xem trạng thái containers
docker-compose ps

# Kiểm tra port 3080
netstat -tlnp | grep 3080

# Test API từ server
curl http://localhost:3080/api/health

# Xem logs nếu có lỗi
docker-compose logs api
docker-compose logs mongodb
docker-compose logs meilisearch
```

### Bước 12: Cấu hình Google OAuth (nếu cần)

1. Vào Google Cloud Console: https://console.cloud.google.com/apis/credentials
2. Mở OAuth Client ID: `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com`
3. Trong "Authorized redirect URIs", thêm:
   ```
   https://chat.daydemy.com/oauth/google/callback
   ```
4. Click "Save"

### Bước 13: Kiểm tra từ browser

1. Mở: `https://chat.daydemy.com`
2. Kiểm tra xem có load được không
3. Test đăng ký/đăng nhập

## Kiểm tra và Troubleshooting

### Kiểm tra Nginx

```bash
# Xem logs Nginx
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log

# Test cấu hình
nginx -t

# Reload Nginx
systemctl reload nginx
```

### Kiểm tra Docker containers

```bash
# Xem tất cả containers
docker ps -a

# Xem logs của từng service
docker-compose logs api
docker-compose logs mongodb
docker-compose logs meilisearch
docker-compose logs rag_api
docker-compose logs vectordb

# Restart service nếu cần
docker-compose restart api
```

### Kiểm tra port

```bash
# Xem các port đang được sử dụng
netstat -tlnp | grep LISTEN

# Kiểm tra port 3080
lsof -i :3080

# Nếu port 3080 đã được sử dụng, thay đổi trong docker-compose.yml
```

### Kiểm tra SSL Certificate

```bash
# Xem danh sách certificates
certbot certificates

# Renew certificate
certbot renew

# Test auto-renewal
certbot renew --dry-run
```

### Kiểm tra DNS

```bash
# Kiểm tra DNS từ server
nslookup chat.daydemy.com
dig chat.daydemy.com

# Kiểm tra từ máy local
ping chat.daydemy.com
```

### Lỗi thường gặp

#### 1. Port 3080 đã được sử dụng
```bash
# Tìm process đang dùng port 3080
lsof -i :3080
# Kill process hoặc thay đổi port trong docker-compose.yml
```

#### 2. Nginx không proxy được
```bash
# Kiểm tra logs
tail -f /var/log/nginx/error.log

# Kiểm tra LibreChat có chạy không
curl http://localhost:3080/api/health

# Kiểm tra firewall
ufw status
# Nếu cần, mở port 80 và 443
ufw allow 80/tcp
ufw allow 443/tcp
```

#### 3. SSL Certificate không hoạt động
```bash
# Kiểm tra certificate
certbot certificates

# Tạo lại certificate
certbot certonly --nginx -d chat.daydemy.com

# Kiểm tra file certificate
ls -la /etc/letsencrypt/live/chat.daydemy.com/
```

#### 4. Container không start
```bash
# Xem logs chi tiết
docker-compose logs

# Kiểm tra .env file
cat .env

# Kiểm tra docker-compose.yml
cat docker-compose.yml

# Rebuild và restart
docker-compose down
docker-compose up -d --build
```

## Cấu trúc thư mục trên server

```
/opt/librechat/
├── .env                          # Environment variables
├── docker-compose.yml            # Docker Compose config
├── librechat.yaml                # LibreChat config
├── images/                       # Custom images
├── uploads/                      # User uploads
├── logs/                         # Application logs
├── data-node/                    # MongoDB data
└── meili_data_v1.12/            # Meilisearch data

/etc/nginx/
├── sites-available/
│   ├── multi-site               # Nginx config cho cả 2 domain
│   └── librechat                # Nginx config riêng cho LibreChat
└── sites-enabled/
    └── multi-site -> ../sites-available/multi-site

/etc/letsencrypt/live/
├── langhit.com/                 # SSL cho langhit.com
└── chat.daydemy.com/            # SSL cho chat.daydemy.com
```

## Lệnh hữu ích

### Quản lý Docker Compose

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Xem logs
docker-compose logs -f

# Rebuild và restart
docker-compose up -d --build
```

### Backup

```bash
# Backup MongoDB
docker exec chat-mongodb mongodump --out /data/db/backup

# Backup toàn bộ thư mục
tar -czf librechat-backup-$(date +%Y%m%d).tar.gz /opt/librechat
```

### Update

```bash
cd /opt/librechat

# Pull code mới (nếu dùng git)
git pull

# Rebuild containers
docker-compose down
docker-compose up -d --build
```

## Liên kết

- **LibreChat**: https://chat.daydemy.com
- **Langhit**: https://langhit.com
- **Server**: 88.99.26.236
- **Google OAuth**: https://console.cloud.google.com/apis/credentials

## Lưu ý quan trọng

1. **Port 3080**: Chỉ expose trên localhost (127.0.0.1), không expose ra ngoài
2. **SSL Certificate**: Phải có SSL certificate trước khi start Nginx
3. **DNS**: Đảm bảo `chat.daydemy.com` đã trỏ về IP `88.99.26.236`
4. **JWT Secrets**: Phải generate random strings, không dùng giá trị mặc định
5. **Permissions**: Đảm bảo thư mục có đúng permissions (1000:1000)
6. **Firewall**: Đảm bảo port 80 và 443 đã được mở
7. **Port conflict**: Kiểm tra port của langhit.com không trùng với port 3080


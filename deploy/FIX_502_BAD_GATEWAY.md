# Sửa lỗi 502 Bad Gateway

## Vấn đề

Cloudflare trả về 502 Bad Gateway - server không phản hồi.

## Nguyên nhân thường gặp

1. Container LibreChat đang down hoặc restarting
2. Nginx/reverse proxy không kết nối được với container
3. Container crash hoặc không start được
4. Port không được expose đúng

## Kiểm tra và sửa

### Bước 1: Kiểm tra container

```bash
cd /opt/librechat

# Xem trạng thái container
docker ps -a | grep LibreChat

# Xem logs
docker logs LibreChat --tail 50

# Kiểm tra container có đang chạy không
docker ps | grep LibreChat
```

### Bước 2: Kiểm tra port

```bash
# Kiểm tra port 3080 có đang listen không
netstat -tlnp | grep 3080
# Hoặc
ss -tlnp | grep 3080

# Kiểm tra container có expose port không
docker port LibreChat
```

### Bước 3: Restart container

```bash
cd /opt/librechat

# Restart container
docker-compose restart api

# Hoặc stop và start lại
docker-compose down
docker-compose up -d

# Kiểm tra
docker ps | grep LibreChat
docker logs LibreChat --tail 20
```

### Bước 4: Kiểm tra Nginx/reverse proxy (nếu có)

```bash
# Kiểm tra Nginx config
nginx -t

# Kiểm tra Nginx status
systemctl status nginx

# Restart Nginx
systemctl restart nginx

# Xem Nginx logs
tail -f /var/log/nginx/error.log
```

### Bước 5: Kiểm tra firewall

```bash
# Kiểm tra firewall có block port không
iptables -L -n | grep 3080

# Hoặc nếu dùng ufw
ufw status | grep 3080
```

## Sửa nhanh

```bash
cd /opt/librechat

# 1. Kiểm tra và restart container
docker ps -a | grep LibreChat
docker-compose restart api

# 2. Đợi vài giây
sleep 5

# 3. Kiểm tra container đã chạy chưa
docker ps | grep LibreChat

# 4. Kiểm tra logs
docker logs LibreChat --tail 20

# 5. Test kết nối local
curl http://localhost:3080 || echo "Container chưa sẵn sàng"
```

## Nếu container không start được

```bash
# Xem logs chi tiết
docker logs LibreChat --tail 100

# Kiểm tra .env có đúng không
grep -E "PORT|MONGO_URI|MEILI_HOST" .env

# Kiểm tra dependencies (mongodb, meilisearch)
docker ps | grep -E "mongodb|meilisearch"

# Restart tất cả
docker-compose down
docker-compose up -d
```


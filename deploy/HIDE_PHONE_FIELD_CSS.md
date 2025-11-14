# Ẩn Phone Field bằng CSS

## Bước 1: Kiểm tra tên container

```bash
cd /opt/librechat

# Xem tên container đúng
docker ps --format "{{.Names}}"

# Hoặc
docker-compose ps
```

## Bước 2: Tìm file HTML

```bash
# Với tên container đúng (ví dụ: LibreChat)
docker exec LibreChat find /app/client/dist -name "index.html"

# Hoặc
docker exec $(docker ps --format "{{.Names}}" | grep -i librechat | head -1) find /app/client/dist -name "index.html"
```

## Bước 3: Thêm CSS để ẩn phone field

```bash
# Tên container (thay bằng tên đúng)
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -i librechat | head -1)

# Tìm file HTML
HTML_FILE=$(docker exec $CONTAINER_NAME find /app/client/dist -name "index.html")

# Backup
docker exec $CONTAINER_NAME cp $HTML_FILE ${HTML_FILE}.backup

# Thêm CSS vào đầu file (trước </head>)
docker exec $CONTAINER_NAME sh -c "sed -i '/<\/head>/i <style>input[name=\"phone\"],label[for=\"phone\"],input[type=\"tel\"]{display:none!important}</style>' $HTML_FILE"

# Restart
docker-compose restart api
```

## Hoặc sửa trực tiếp

```bash
# Vào container
docker exec -it LibreChat sh

# Trong container
cd /app/client/dist
vi index.html

# Thêm vào trước </head>:
# <style>input[name="phone"],label[for="phone"]{display:none!important}</style>
```


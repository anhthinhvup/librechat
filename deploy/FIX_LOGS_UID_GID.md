# Sửa lỗi Permission logs - UID/GID

## Vấn đề

Container dùng `user: "${UID}:${GID}"` nên cần set quyền logs theo UID/GID đó.

## Giải pháp

```bash
cd /opt/librechat

# 1. Kiểm tra UID/GID trong .env
grep -E "^UID=|^GID=" .env

# 2. Tạo thư mục logs
mkdir -p logs

# 3. Set quyền theo UID/GID (ví dụ UID=1000, GID=1000)
# Nếu UID/GID không có trong .env, dùng quyền 777
if grep -q "^UID=" .env && grep -q "^GID=" .env; then
    UID_VAL=$(grep "^UID=" .env | cut -d'=' -f2)
    GID_VAL=$(grep "^GID=" .env | cut -d'=' -f2)
    chown -R $UID_VAL:$GID_VAL logs
    chmod -R 755 logs
else
    chmod -R 777 logs
fi

# 4. Restart container
docker-compose restart api

# 5. Kiểm tra
docker logs LibreChat --tail 20
```

## Hoặc set quyền 777 (đơn giản nhất)

```bash
cd /opt/librechat
mkdir -p logs
chmod -R 777 logs
docker-compose restart api
```


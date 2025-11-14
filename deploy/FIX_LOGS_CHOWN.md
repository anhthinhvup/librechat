# Sửa lỗi Permission logs - Chown theo UID/GID

## Vấn đề

Container dùng `user: "${UID}:${GID}"` nên cần chown logs theo UID/GID đó.

## Giải pháp

```bash
cd /opt/librechat

# 1. Kiểm tra UID/GID trong .env
grep -E "^UID=|^GID=" .env

# 2. Nếu có UID/GID, set chown
if grep -q "^UID=" .env && grep -q "^GID=" .env; then
    UID_VAL=$(grep "^UID=" .env | cut -d'=' -f2 | tr -d ' ')
    GID_VAL=$(grep "^GID=" .env | cut -d'=' -f2 | tr -d ' ')
    echo "Setting ownership to $UID_VAL:$GID_VAL"
    chown -R $UID_VAL:$GID_VAL logs
    chmod -R 755 logs
else
    echo "UID/GID not found, using 777"
    chmod -R 777 logs
fi

# 3. Kiểm tra quyền
ls -la logs/

# 4. Restart
docker-compose restart api

# 5. Kiểm tra logs
sleep 5
docker logs LibreChat --tail 20 | grep -i error
```

## Hoặc tắt logging (tạm thời)

Nếu không cần logs, có thể tắt logging trong code hoặc env.


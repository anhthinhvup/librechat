# Sửa nhanh Phone Verification trên Server

## Vấn đề

Code mới chưa có trong Docker image, nên form verify vẫn hiển thị.

## Giải pháp nhanh: Sửa trực tiếp trong container

### Bước 1: Vào container và sửa file

```bash
cd /opt/librechat

# Vào container
docker exec -it LibreChat-API sh

# Trong container, sửa file
cd /app/client/src/components/Auth
cp Registration.tsx Registration.tsx.backup

# Sửa file (comment out phone field)
# Tìm dòng: {renderInput('phone', 'com_auth_phone', 'tel', {
# Thay thành: {/* {renderInput('phone', 'com_auth_phone', 'tel', {
# Tìm dòng: })}
# Thay thành: })} */}
```

### Bước 2: Hoặc dùng sed (tự động)

```bash
cd /opt/librechat

# Backup
docker exec LibreChat-API cp /app/client/src/components/Auth/Registration.tsx /app/client/src/components/Auth/Registration.tsx.backup

# Comment out phone field
docker exec LibreChat-API sed -i "s/{renderInput('phone'/{{\/* renderInput('phone'/g" /app/client/src/components/Auth/Registration.tsx
docker exec LibreChat-API sed -i "s/})}/}) *\/}/g" /app/client/src/components/Auth/Registration.tsx

# Restart
docker-compose restart api
```

### Bước 3: Hoặc copy file đã sửa vào container

```bash
# Từ máy local, copy file đã sửa lên server
scp client/src/components/Auth/Registration.tsx root@stage6:/tmp/

# Trên server, copy vào container
docker cp /tmp/Registration.tsx LibreChat-API:/app/client/src/components/Auth/Registration.tsx

# Restart
docker-compose restart api
```

## Lưu ý

- Thay đổi này sẽ mất khi container được rebuild
- Để giữ lâu dài, cần build lại image với code mới


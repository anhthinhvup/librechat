# Hướng dẫn cập nhật code lên server

## Bước 1: Commit code lên GitHub (từ máy Windows)

```bash
# Thêm các file đã sửa
git add .

# Commit với message
git commit -m "Add phone verification feature"

# Push lên GitHub
git push origin main
```

## Bước 2: Cập nhật code trên server

SSH vào server:
```bash
ssh root@88.99.26.236
```

Vào thư mục LibreChat:
```bash
cd /opt/librechat
```

Pull code mới từ GitHub:
```bash
git pull origin main
```

## Bước 3: Restart Docker containers

```bash
cd /opt/librechat
docker-compose down
docker-compose up -d
```

## Bước 4: Kiểm tra logs (nếu có lỗi)

```bash
docker-compose logs -f api
```

## Lưu ý:

1. **Nếu có conflict**: Git sẽ báo lỗi. Cần resolve conflict trước khi pull tiếp.
2. **Nếu cần build lại**: Nếu có thay đổi trong `packages/`, có thể cần rebuild:
   ```bash
   docker-compose build api
   docker-compose up -d
   ```
3. **Backup trước khi update**: Nên backup database trước khi update:
   ```bash
   docker-compose exec mongodb mongodump --out /backup
   ```


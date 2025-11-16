# Kiểm tra và khôi phục lịch sử chat

## Vấn đề

Lịch sử chat có thể đã mất khi reset MongoDB (xóa storage.bson) hoặc muốn kiểm tra/xem lại.

## Lịch sử chat được lưu ở đâu

- **Database**: MongoDB (tên database từ MONGO_URI, thường là `LibreChat`)
- **Collections**:
  - `conversations` - Lưu các cuộc hội thoại
  - `messages` - Lưu các tin nhắn
  - `users` - Lưu thông tin người dùng

## Kiểm tra lịch sử chat còn không

### Cách 1: Kiểm tra qua MongoDB shell

```bash
cd /opt/librechat

# 1. Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# 2. Kiểm tra số lượng conversations
db.conversations.countDocuments()

# 3. Kiểm tra số lượng messages
db.messages.countDocuments()

# 4. Xem danh sách conversations (10 cái đầu)
db.conversations.find().limit(10).pretty()

# 5. Xem danh sách messages (10 cái đầu)
db.messages.find().limit(10).pretty()

# 6. Tìm conversations của user cụ thể (thay USER_ID)
db.conversations.find({ user: "USER_ID" }).pretty()

# 7. Thoát
exit
```

### Cách 2: Kiểm tra qua MongoDB Compass hoặc tool khác

```bash
# Kết nối MongoDB:
# Host: localhost (hoặc IP server)
# Port: 27017
# Database: LibreChat
# Authentication: None (nếu chưa bật auth)
```

### Cách 3: Export data để kiểm tra

```bash
cd /opt/librechat

# Export conversations
docker exec chat-mongodb mongodump --db=LibreChat --collection=conversations --out=/tmp/backup

# Export messages
docker exec chat-mongodb mongodump --db=LibreChat --collection=messages --out=/tmp/backup

# Copy ra host
docker cp chat-mongodb:/tmp/backup ./mongodb-backup
```

## Khôi phục lịch sử chat (nếu có backup)

### Nếu có backup MongoDB

```bash
cd /opt/librechat

# 1. Copy backup vào container
docker cp ./mongodb-backup/LibreChat chat-mongodb:/tmp/restore

# 2. Restore conversations
docker exec chat-mongodb mongorestore --db=LibreChat --collection=conversations /tmp/restore/LibreChat/conversations.bson

# 3. Restore messages
docker exec chat-mongodb mongorestore --db=LibreChat --collection=messages /tmp/restore/LibreChat/messages.bson

# 4. Restart API để load lại data
docker-compose restart api
```

### Nếu có backup data-node

```bash
cd /opt/librechat

# 1. Stop MongoDB
docker-compose stop mongodb

# 2. Restore từ backup
# Nếu có data-node.backup.*
cp -r data-node.backup.*/ data-node/

# Hoặc nếu có backup ở nơi khác
# cp -r /path/to/backup/data-node ./data-node

# 3. Set quyền
chown -R 1000:1000 data-node
chmod -R 755 data-node

# 4. Start MongoDB
docker-compose up -d mongodb

# 5. Đợi MongoDB khởi động
sleep 30

# 6. Kiểm tra
docker exec chat-mongodb mongosh LibreChat --eval "db.conversations.countDocuments()"
```

## Kiểm tra trong website

1. Đăng nhập vào: https://chat.daydemy.com
2. Xem sidebar bên trái - các conversations sẽ hiển thị ở đó
3. Nếu không thấy, có thể data đã mất khi reset MongoDB

## Lưu ý

⚠️ **Nếu đã xóa `storage.bson` và không có backup**, dữ liệu chat đã mất vĩnh viễn.

✅ **Để tránh mất data trong tương lai**:
- Backup MongoDB định kỳ
- Backup thư mục `data-node/` trước khi sửa
- Sử dụng `mongodump` để backup


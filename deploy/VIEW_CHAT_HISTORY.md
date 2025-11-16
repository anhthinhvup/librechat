# Xem lịch sử chat trong LibreChat

## Lưu ý

- **Lịch sử chat trong LibreChat** là các cuộc hội thoại với AI models (GPT-4, Claude, etc.)
- **Không phải** lịch sử chat với AI assistant trong Cursor
- Lịch sử được lưu trong MongoDB database `LibreChat`

## Xem lịch sử chat trong LibreChat

### Cách 1: Xem trong website (Dễ nhất)

1. Đăng nhập vào: https://chat.daydemy.com
2. Xem sidebar bên trái - các conversations sẽ hiển thị ở đó
3. Click vào conversation để xem lại

### Cách 2: Xem trong MongoDB

```bash
cd /opt/librechat

# 1. Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# 2. Xem tất cả conversations
db.conversations.find().sort({updatedAt: -1}).pretty()

# 3. Xem conversations của user cụ thể (thay USER_ID)
# Lấy USER_ID từ website hoặc:
db.users.find().pretty()

# Sau đó:
db.conversations.find({ user: "USER_ID" }).sort({updatedAt: -1}).pretty()

# 4. Xem messages của một conversation
db.messages.find({ conversationId: "CONVERSATION_ID" }).sort({createdAt: 1}).pretty()

# 5. Thoát
exit
```

### Cách 3: Export ra file để xem

```bash
cd /opt/librechat

# Export conversations ra JSON
docker exec chat-mongodb mongosh LibreChat --quiet --eval "JSON.stringify(db.conversations.find().toArray())" > conversations.json

# Export messages ra JSON
docker exec chat-mongodb mongosh LibreChat --quiet --eval "JSON.stringify(db.messages.find().toArray())" > messages.json

# Xem file
cat conversations.json | head -100
```

## Tìm conversation theo từ khóa

```bash
cd /opt/librechat

# Tìm conversations có title chứa từ khóa
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.conversations.find({ title: /KEYWORD/i }).pretty()"

# Tìm messages có text chứa từ khóa
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.messages.find({ text: /KEYWORD/i }).pretty()"
```

## Kiểm tra nhanh có data không

```bash
cd /opt/librechat

# Kiểm tra số lượng
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  print('Conversations: ' + db.conversations.countDocuments());
  print('Messages: ' + db.messages.countDocuments());
  print('Users: ' + db.users.countDocuments());
"
```


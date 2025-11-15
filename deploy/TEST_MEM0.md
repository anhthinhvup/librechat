# Hướng dẫn Test Mem0 trên LibreChat

Hướng dẫn chi tiết để kiểm tra và test tính năng mem0 (memory management) trên LibreChat.

## Mục lục
1. [Kiểm tra cài đặt](#kiểm-tra-cài-đặt)
2. [Test cơ bản](#test-cơ-bản)
3. [Test tự động tạo memories](#test-tự-động-tạo-memories)
4. [Test sync với MongoDB](#test-sync-với-mongodb)
5. [Kiểm tra logs](#kiểm-tra-logs)
6. [Troubleshooting](#troubleshooting)

---

## Kiểm tra cài đặt

### 1. Kiểm tra mem0 server đang chạy

```bash
cd /opt/librechat

# Kiểm tra container mem0
docker ps | grep mem0-server

# Kiểm tra health endpoint
curl http://localhost:8001/health

# Kết quả mong đợi:
# {"status":"healthy","service":"mem0-api"}
```

### 2. Kiểm tra cấu hình trong .env

```bash
cd /opt/librechat

# Kiểm tra các biến môi trường
grep -E "MEM0|ENABLE_MEM0" .env

# Kết quả mong đợi:
# MEM0_API_URL=http://mem0-server:8001
# MEM0_API_KEY=your-api-key
# ENABLE_MEM0=true
# OPENAI_API_KEY=your-openai-key
```

### 3. Kiểm tra API container có code mới

```bash
# Kiểm tra logs API có load Mem0Service không
docker-compose logs api | grep -i "mem0\|Mem0Service"

# Hoặc kiểm tra trong container
docker exec LibreChat ls -la /app/api/server/services/ | grep Mem0
```

---

## Test cơ bản

### Test 1: Kiểm tra mem0 API trực tiếp

```bash
# Test health endpoint
curl http://localhost:8001/health

# Test thêm memories (thay USER_ID bằng user ID thật)
curl -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "messages": [
      {"role": "user", "content": "Tôi tên là Nguyễn Văn A, 25 tuổi"},
      {"role": "assistant", "content": "Xin chào! Tôi đã ghi nhớ thông tin của bạn."}
    ]
  }'

# Test lấy memories
curl http://localhost:8001/memories/test_user_123

# Test tìm kiếm memories
curl -X POST http://localhost:8001/memories/search \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "query": "tên là gì",
    "limit": 5
  }'
```

### Test 2: Kiểm tra từ trong container API

```bash
# Vào container API
docker exec -it LibreChat bash

# Test Mem0Service có load được không
node -e "const Mem0Service = require('./api/server/services/Mem0Service'); console.log('Mem0Service loaded:', !!Mem0Service);"

# Thoát
exit
```

---

## Test tự động tạo memories

### Bước 1: Tạo conversation mới trên LibreChat

1. Đăng nhập vào LibreChat
2. Tạo conversation mới
3. Chat với AI và cung cấp thông tin về bản thân:

```
Bạn: Tôi tên là Phạm Văn Thịnh, sinh năm 1995, làm việc tại công ty ABC
AI: Cảm ơn bạn đã chia sẻ thông tin!
Bạn: Tôi thích đọc sách và chơi thể thao
AI: Tôi đã ghi nhớ sở thích của bạn.
```

### Bước 2: Kiểm tra mem0 đã nhận messages

```bash
# Xem logs mem0 server
docker-compose logs -f mem0

# Hoặc xem logs API
docker-compose logs -f api | grep -i mem0

# Bạn sẽ thấy logs như:
# [Mem0Service] Added memories for user <user_id>
# [AgentController] Sent X messages to mem0 for user <user_id>
```

### Bước 3: Kiểm tra memories đã được tạo

```bash
# Lấy user ID từ database hoặc từ logs
# Sau đó test API mem0
curl http://localhost:8001/memories/<USER_ID>

# Hoặc vào MongoDB
docker exec -it chat-mongodb mongosh LibreChat

# Trong mongosh:
use LibreChat
db.memoryentries.find({ userId: ObjectId("<USER_ID>") }).pretty()

# Thoát
exit
```

---

## Test sync với MongoDB

### Kiểm tra memories đã sync từ mem0 về MongoDB

```bash
# Vào MongoDB
docker exec -it chat-mongodb mongosh LibreChat

# Xem tất cả memories (thay USER_ID)
use LibreChat
db.memoryentries.find({ userId: ObjectId("<USER_ID>") }).sort({ updated_at: -1 }).pretty()

# Tìm memories có key bắt đầu bằng "mem0_"
db.memoryentries.find({ 
  userId: ObjectId("<USER_ID>"),
  key: /^mem0_/
}).pretty()

# Đếm số lượng memories từ mem0
db.memoryentries.countDocuments({ 
  userId: ObjectId("<USER_ID>"),
  key: /^mem0_/
})

# Thoát
exit
```

### Test sync thủ công (nếu cần)

```bash
# Vào container API
docker exec -it LibreChat bash

# Chạy script test sync (tạo file test-sync.js)
cat > /tmp/test-sync.js << 'EOF'
const Mem0Service = require('/app/api/server/services/Mem0Service');
const { setMemory, getAllUserMemories } = require('/app/models');

async function testSync() {
  const userId = 'YOUR_USER_ID_HERE'; // Thay bằng user ID thật
  try {
    await Mem0Service.syncToMongoDB(userId, {
      setMemory,
      getAllUserMemories,
    });
    console.log('Sync completed!');
  } catch (error) {
    console.error('Sync error:', error);
  }
}

testSync();
EOF

# Chạy test (cần chỉnh user ID trước)
node /tmp/test-sync.js

exit
```

---

## Kiểm tra logs

### Xem logs mem0 server

```bash
# Xem logs real-time
docker-compose logs -f mem0

# Xem logs gần đây
docker-compose logs --tail=100 mem0

# Tìm lỗi
docker-compose logs mem0 | grep -i error
```

### Xem logs API liên quan đến mem0

```bash
# Xem logs real-time
docker-compose logs -f api | grep -i mem0

# Xem tất cả logs API
docker-compose logs --tail=200 api | grep -i "mem0\|Mem0Service"

# Tìm lỗi
docker-compose logs api | grep -i "mem0.*error\|error.*mem0"
```

### Kiểm tra mem0 có nhận requests không

```bash
# Xem logs mem0 với filter
docker-compose logs mem0 | grep -E "POST|GET|memories"

# Hoặc xem access logs nếu có
docker-compose logs mem0 | grep -E "user_id|Added memories"
```

---

## Test AI có sử dụng memories không

### Bước 1: Tạo memories thủ công (nếu chưa có)

1. Vào LibreChat Settings > Personalization
2. Thêm memory: 
   - Key: `my_name`
   - Value: `Tôi tên là Phạm Văn Thịnh`

### Bước 2: Test AI nhớ thông tin

Chat với AI:

```
Bạn: Tên tôi là gì?
AI: (Nên trả lời: Tên bạn là Phạm Văn Thịnh)
```

### Bước 3: Kiểm tra memories được sử dụng

```bash
# Xem logs khi chat
docker-compose logs -f api | grep -i "memory\|memories"

# Hoặc xem trong conversation, AI sẽ có memories context
```

---

## Troubleshooting

### Lỗi 1: Mem0 server không khởi động

```bash
# Kiểm tra logs
docker-compose logs mem0

# Kiểm tra port 8001 có bị chiếm không
netstat -tulpn | grep 8001

# Restart mem0
docker-compose restart mem0

# Rebuild nếu cần
docker-compose build mem0
docker-compose up -d mem0
```

### Lỗi 2: API không kết nối được mem0

```bash
# Kiểm tra network
docker network ls
docker network inspect librechat_default | grep mem0

# Test từ trong container API
docker exec -it LibreChat bash
curl http://mem0-server:8001/health
exit

# Kiểm tra MEM0_API_URL trong .env
grep MEM0_API_URL .env
```

### Lỗi 3: Memories không được tạo

```bash
# Kiểm tra ENABLE_MEM0
grep ENABLE_MEM0 .env

# Kiểm tra logs API
docker-compose logs api | grep -i "mem0.*error\|error.*mem0"

# Kiểm tra mem0 có nhận requests không
docker-compose logs mem0 | tail -50

# Test thủ công
curl -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test",
    "messages": [{"role": "user", "content": "test"}]
  }'
```

### Lỗi 4: Memories không sync về MongoDB

```bash
# Kiểm tra logs sync
docker-compose logs api | grep -i "sync.*mem0\|mem0.*sync"

# Kiểm tra MongoDB connection
docker exec -it chat-mongodb mongosh LibreChat --eval "db.stats()"

# Test sync thủ công (xem phần trên)
```

### Lỗi 5: OPENAI_API_KEY không đúng

```bash
# Kiểm tra key
grep OPENAI_API_KEY .env

# Test key có hoạt động không
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_OPENAI_API_KEY"

# Cập nhật key trong .env và restart
docker-compose restart mem0 api
```

---

## Checklist test hoàn chỉnh

- [ ] Mem0 server đang chạy (`docker ps | grep mem0`)
- [ ] Health endpoint trả về OK (`curl http://localhost:8001/health`)
- [ ] `.env` có đầy đủ cấu hình mem0
- [ ] API container có file `Mem0Service.js`
- [ ] Test API mem0 trực tiếp thành công
- [ ] Chat trên LibreChat và kiểm tra logs
- [ ] Memories được tạo trong mem0
- [ ] Memories được sync về MongoDB
- [ ] AI có thể sử dụng memories khi chat

---

## Kết quả mong đợi

Sau khi test thành công:

1. **Mem0 server**: Nhận messages từ conversations và tạo memories tự động
2. **MongoDB**: Có memories được sync từ mem0 (key bắt đầu bằng `mem0_`)
3. **AI**: Sử dụng memories khi chat với user
4. **Logs**: Có logs về việc gửi messages đến mem0 và sync memories

---

## Lưu ý

- Mem0 cần OPENAI_API_KEY để hoạt động
- Memories được tạo tự động sau mỗi conversation
- Sync về MongoDB diễn ra trong background (không block request)
- Nếu mem0 không available, hệ thống vẫn hoạt động bình thường (graceful degradation)

---

## Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. Logs: `docker-compose logs -f mem0 api`
2. Health: `curl http://localhost:8001/health`
3. Config: `grep -E "MEM0|ENABLE_MEM0" .env`
4. Network: `docker network inspect librechat_default`


#!/bin/bash

# Script test mem0 server với reverse proxy
set -e

echo "========================================="
echo "Test Mem0 Server với Reverse Proxy"
echo "========================================="

cd /opt/librechat

# 1. Pull code mới
echo "📥 Pulling latest code..."
git pull

# 2. Rebuild image
echo "🔨 Rebuilding Docker image..."
cd mem0_server
docker build -t mem0-server:latest .
cd ..

# 3. Xóa container cũ
echo "🗑️  Removing old container..."
docker rm -f mem0-server || true

# 4. Tạo container mới
echo "🚀 Starting new container..."
docker run -d \
  --name mem0-server \
  --restart always \
  -p 8001:8001 \
  -e OPENAI_API_KEY=sk-SL4FdpsAirJCaVYeapOOFvi6Xy99Iwz7IjmvK2mGVT1oZWPU \
  -e OPENAI_REVERSE_PROXY=https://langhit.com/v1 \
  -v $(pwd)/mem0_data:/app/data \
  mem0-server:latest

# 5. Đợi server khởi động
echo "⏳ Waiting for server to start (20 seconds)..."
sleep 20

# 6. Test health endpoint
echo "🏥 Testing health endpoint..."
curl -s http://localhost:8001/health | jq . || echo "Health check failed"

# 7. Test add memory
echo ""
echo "📝 Testing add memory..."
RESPONSE=$(curl -s -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_traceback",
    "messages": [
      {"role": "user", "content": "My name is TestUser"},
      {"role": "assistant", "content": "Hello TestUser"}
    ]
  }')

echo "Response:"
echo "$RESPONSE" | jq . || echo "$RESPONSE"

# 8. Xem logs đầy đủ
echo ""
echo "📋 Full logs (last 100 lines):"
docker logs mem0-server --tail=100

# 9. Tìm lỗi OpenAIConfig
echo ""
echo "🔍 Searching for OpenAIConfig errors..."
docker logs mem0-server 2>&1 | grep -i "OpenAIConfig\|base_url\|Error" | tail -20

echo ""
echo "✅ Test completed!"


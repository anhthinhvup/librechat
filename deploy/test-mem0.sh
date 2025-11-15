#!/bin/bash

# Script test mem0 trên LibreChat
# Chạy: bash deploy/test-mem0.sh

set -e

echo "========================================="
echo "Test Mem0 trên LibreChat"
echo "========================================="

cd /opt/librechat

# Màu sắc
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Kiểm tra mem0 server
echo ""
echo "1. Kiểm tra mem0 server..."
if docker ps | grep -q mem0-server; then
    echo -e "${GREEN}✅ Mem0 server đang chạy${NC}"
else
    echo -e "${RED}❌ Mem0 server không chạy${NC}"
    echo "   Chạy: docker-compose up -d mem0"
    exit 1
fi

# Test 2: Health check
echo ""
echo "2. Kiểm tra health endpoint..."
HEALTH=$(curl -s http://localhost:8001/health 2>/dev/null || echo "ERROR")
if echo "$HEALTH" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Health check OK${NC}"
    echo "   Response: $HEALTH"
else
    echo -e "${RED}❌ Health check failed${NC}"
    echo "   Response: $HEALTH"
    exit 1
fi

# Test 3: Kiểm tra cấu hình
echo ""
echo "3. Kiểm tra cấu hình .env..."
if grep -q "ENABLE_MEM0=true" .env; then
    echo -e "${GREEN}✅ ENABLE_MEM0=true${NC}"
else
    echo -e "${YELLOW}⚠️  ENABLE_MEM0 chưa được set hoặc = false${NC}"
fi

if grep -q "MEM0_API_URL" .env; then
    MEM0_URL=$(grep "MEM0_API_URL" .env | cut -d '=' -f2)
    echo -e "${GREEN}✅ MEM0_API_URL=$MEM0_URL${NC}"
else
    echo -e "${RED}❌ MEM0_API_URL chưa được cấu hình${NC}"
fi

if grep -q "OPENAI_API_KEY" .env && ! grep -q "OPENAI_API_KEY=$" .env; then
    echo -e "${GREEN}✅ OPENAI_API_KEY đã được cấu hình${NC}"
else
    echo -e "${YELLOW}⚠️  OPENAI_API_KEY chưa được cấu hình${NC}"
fi

# Test 4: Kiểm tra Mem0Service trong API
echo ""
echo "4. Kiểm tra Mem0Service trong API container..."
if docker exec LibreChat test -f /app/api/server/services/Mem0Service.js 2>/dev/null; then
    echo -e "${GREEN}✅ Mem0Service.js tồn tại${NC}"
else
    echo -e "${RED}❌ Mem0Service.js không tồn tại${NC}"
    echo "   Cần rebuild API: docker-compose build api"
fi

# Test 5: Test API mem0 trực tiếp
echo ""
echo "5. Test thêm memories vào mem0..."
TEST_USER_ID="test_user_$(date +%s)"
TEST_RESPONSE=$(curl -s -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"$TEST_USER_ID\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Tôi tên là Test User, 30 tuổi\"},
      {\"role\": \"assistant\", \"content\": \"Xin chào! Tôi đã ghi nhớ.\"}
    ]
  }" 2>/dev/null || echo "ERROR")

if echo "$TEST_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Test thêm memories thành công${NC}"
    echo "   User ID: $TEST_USER_ID"
else
    echo -e "${RED}❌ Test thêm memories thất bại${NC}"
    echo "   Response: $TEST_RESPONSE"
fi

# Test 6: Test lấy memories
echo ""
echo "6. Test lấy memories..."
GET_RESPONSE=$(curl -s "http://localhost:8001/memories/$TEST_USER_ID" 2>/dev/null || echo "ERROR")
if echo "$GET_RESPONSE" | grep -q "success\|memories"; then
    echo -e "${GREEN}✅ Test lấy memories thành công${NC}"
    echo "   Response preview: $(echo "$GET_RESPONSE" | head -c 100)..."
else
    echo -e "${YELLOW}⚠️  Chưa có memories hoặc lỗi${NC}"
    echo "   Response: $GET_RESPONSE"
fi

# Test 7: Kiểm tra logs
echo ""
echo "7. Kiểm tra logs gần đây..."
echo "   Mem0 logs (5 dòng cuối):"
docker-compose logs --tail=5 mem0 2>/dev/null | tail -5 || echo "   Không có logs"

echo ""
echo "   API logs liên quan đến mem0 (5 dòng cuối):"
docker-compose logs --tail=50 api 2>/dev/null | grep -i mem0 | tail -5 || echo "   Không có logs mem0"

# Test 8: Kiểm tra network
echo ""
echo "8. Kiểm tra network connectivity..."
if docker exec LibreChat curl -s --max-time 2 http://mem0-server:8001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API container có thể kết nối mem0${NC}"
else
    echo -e "${RED}❌ API container không thể kết nối mem0${NC}"
    echo "   Kiểm tra network: docker network inspect librechat_default"
fi

# Tổng kết
echo ""
echo "========================================="
echo "Tổng kết"
echo "========================================="
echo ""
echo "Để test đầy đủ:"
echo "1. Đăng nhập LibreChat và chat với AI"
echo "2. Xem logs: docker-compose logs -f api | grep -i mem0"
echo "3. Kiểm tra memories trong MongoDB:"
echo "   docker exec -it chat-mongodb mongosh LibreChat"
echo "   db.memoryentries.find({ key: /^mem0_/ }).pretty()"
echo ""
echo "Xem hướng dẫn chi tiết: deploy/TEST_MEM0.md"


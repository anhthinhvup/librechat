#!/bin/bash

# Script kiểm tra và sửa lỗi 502 Bad Gateway

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔍 Kiểm tra lỗi 502 Bad Gateway..."

# 1. Kiểm tra container
echo ""
echo "📦 Kiểm tra container LibreChat:"
docker ps -a | grep LibreChat || echo "❌ Container không tồn tại"

# 2. Kiểm tra container có đang chạy không
echo ""
echo "🔄 Trạng thái container:"
if docker ps | grep -q LibreChat; then
    echo "✅ Container đang chạy"
else
    echo "❌ Container không chạy, đang start..."
    docker-compose up -d api
    sleep 5
fi

# 3. Kiểm tra port
echo ""
echo "🔌 Kiểm tra port 3080:"
if netstat -tlnp 2>/dev/null | grep -q ":3080 " || ss -tlnp 2>/dev/null | grep -q ":3080 "; then
    echo "✅ Port 3080 đang listen"
else
    echo "❌ Port 3080 không listen"
fi

# 4. Kiểm tra logs
echo ""
echo "📋 Logs (20 dòng cuối):"
docker logs LibreChat --tail 20 2>&1 | tail -20

# 5. Test kết nối local
echo ""
echo "🌐 Test kết nối local:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3080 | grep -q "200\|302\|401"; then
    echo "✅ Server phản hồi"
else
    echo "❌ Server không phản hồi"
    echo "💡 Đang restart container..."
    docker-compose restart api
    sleep 5
    echo "📋 Logs sau restart:"
    docker logs LibreChat --tail 10
fi

# 6. Kiểm tra dependencies
echo ""
echo "🔗 Kiểm tra dependencies:"
docker ps | grep -E "mongodb|meilisearch" || echo "⚠️  Một số dependencies không chạy"

echo ""
echo "✅ Hoàn tất kiểm tra!"
echo "💡 Nếu vẫn lỗi, xem logs chi tiết: docker logs LibreChat --tail 100"

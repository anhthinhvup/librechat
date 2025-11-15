#!/bin/bash
# Script cập nhật mem0 server
set -e

cd /opt/librechat

echo "📦 Copy app.py vào container..."
docker cp mem0_server/app.py mem0-server:/app/app.py

echo "🔄 Restart mem0..."
docker-compose restart mem0

echo "⏳ Đợi 10 giây..."
sleep 10

echo "✅ Hoàn thành!"
echo ""
echo "Kiểm tra:"
echo "  curl http://localhost:8001/health"
echo "  docker-compose logs --tail=10 mem0"


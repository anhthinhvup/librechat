#!/bin/bash
# Script rebuild đơn giản - chạy từ /opt/librechat

echo "=== Rebuild LibreChat Container ==="
echo ""

cd /opt/librechat || exit 1

echo "1. Stopping containers..."
docker-compose down

echo ""
echo "2. Starting containers..."
docker-compose up -d

echo ""
echo "3. Waiting for containers to start..."
sleep 5

echo ""
echo "4. Checking container status..."
docker-compose ps

echo ""
echo "✅ Rebuild hoàn thành!"
echo ""
echo "Kiểm tra logs:"
echo "  docker-compose logs -f api"
echo ""
echo "Kiểm tra phone verification:"
echo "  docker-compose logs api | grep 'Phone verification'"


#!/bin/bash

# Script force rebuild mem0 server không dùng cache
set -e

echo "========================================="
echo "Force Rebuild Mem0 Server (No Cache)"
echo "========================================="

cd /opt/librechat

# 1. Pull code mới
echo "📥 Pulling latest code..."
git pull

# 2. Force rebuild KHÔNG dùng cache
echo "🔨 Force rebuilding Docker image (no cache)..."
cd mem0_server
docker build --no-cache -t mem0-server:latest .
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

# 6. Xem logs từ đầu
echo "📋 Full logs from container start:"
docker logs mem0-server 2>&1

echo ""
echo "✅ Rebuild completed!"


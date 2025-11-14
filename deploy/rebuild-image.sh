#!/bin/bash

# Script để build lại image với code mới

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔨 Bắt đầu build image..."

# 1. Pull code mới (nếu cần)
echo "📥 Pull code mới từ GitHub..."
git pull origin master || echo "⚠️  Không pull được, dùng code hiện tại"

# 2. Build image
echo "🏗️  Building image (có thể mất 10-30 phút)..."
docker build -f Dockerfile.multi --target api-build -t librechat-api:local . || {
    echo "❌ Build thất bại!"
    exit 1
}

# 3. Tạo override file
echo "📝 Tạo docker-compose.override.yaml..."
cat > docker-compose.override.yaml << 'EOF'
services:
  api:
    image: librechat-api:local
EOF

# 4. Restart containers
echo "🔄 Restart containers..."
docker-compose down
docker-compose up -d

# 5. Kiểm tra
echo "✅ Kiểm tra container..."
sleep 5
docker ps | grep LibreChat
echo ""
echo "📋 Logs (20 dòng cuối):"
docker logs LibreChat --tail 20

echo ""
echo "✅ Hoàn tất! Image đã được build và container đã restart."
echo "💡 Kiểm tra phone field đã bị ẩn chưa bằng cách test đăng ký."


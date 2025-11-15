#!/bin/bash

# Script sửa lỗi và cài đặt lại Mem0 server
set -e

echo "========================================="
echo "Sửa lỗi và cài đặt lại Mem0 Server"
echo "========================================="

cd /opt/librechat

# Dừng container cũ nếu có
echo "🛑 Dừng container mem0 cũ..."
docker-compose stop mem0 2>/dev/null || true
docker-compose rm -f mem0 2>/dev/null || true

# Tạo thư mục cần thiết
echo "📁 Tạo thư mục..."
mkdir -p mem0_data/qdrant
chmod -R 755 mem0_data

# Kiểm tra .env
if [ ! -f ".env" ]; then
    echo "❌ Lỗi: Không tìm thấy file .env"
    exit 1
fi

# Thêm biến môi trường nếu chưa có
if ! grep -q "MEM0_API_URL" .env; then
    echo "" >> .env
    echo "# Mem0 Configuration" >> .env
    echo "MEM0_API_URL=http://mem0-server:8001" >> .env
    echo "MEM0_API_KEY=$(openssl rand -hex 32)" >> .env
    echo "ENABLE_MEM0=true" >> .env
fi

# Kiểm tra OPENAI_API_KEY
if ! grep -q "OPENAI_API_KEY=" .env || grep -q "OPENAI_API_KEY=$" .env; then
    echo "⚠️  Cảnh báo: OPENAI_API_KEY chưa được cấu hình trong .env"
    echo "   Mem0 cần OPENAI_API_KEY để hoạt động"
fi

# Build và khởi động mem0
echo "🔨 Build mem0 image..."
docker-compose build mem0

echo "🚀 Khởi động mem0 service..."
docker-compose up -d mem0

# Đợi khởi động
echo "⏳ Đợi mem0 khởi động (20 giây)..."
sleep 20

# Kiểm tra
if docker ps | grep -q mem0-server; then
    echo "✅ Mem0 đã khởi động!"
    echo ""
    echo "📊 Kiểm tra logs:"
    echo "   docker-compose logs -f mem0"
    echo ""
    echo "🔍 Kiểm tra health:"
    echo "   curl http://localhost:8001/health"
    echo ""
    echo "📝 API Endpoints:"
    echo "   POST /memories - Thêm memories"
    echo "   GET /memories/{user_id} - Lấy memories"
    echo "   POST /memories/search - Tìm kiếm memories"
    echo "   DELETE /memories - Xóa memories"
else
    echo "❌ Lỗi: Mem0 không khởi động được"
    echo "Xem logs: docker-compose logs mem0"
    exit 1
fi


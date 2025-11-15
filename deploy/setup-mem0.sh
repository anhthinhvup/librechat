#!/bin/bash

# Script cài đặt Mem0 cho LibreChat
# Chạy script này trên server: bash deploy/setup-mem0.sh

set -e

echo "========================================="
echo "Cài đặt Mem0 cho LibreChat"
echo "========================================="

# Kiểm tra đang ở đúng thư mục
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Lỗi: Không tìm thấy docker-compose.yml"
    echo "Vui lòng chạy script từ thư mục gốc của LibreChat"
    exit 1
fi

# Tạo thư mục cho mem0 data
echo "📁 Tạo thư mục cho mem0 data..."
mkdir -p mem0_data
chmod -R 755 mem0_data

# Kiểm tra .env file
if [ ! -f ".env" ]; then
    echo "❌ Lỗi: Không tìm thấy file .env"
    exit 1
fi

# Thêm biến môi trường vào .env nếu chưa có
if ! grep -q "MEM0_API_URL" .env; then
    echo "" >> .env
    echo "# Mem0 Configuration" >> .env
    echo "MEM0_API_URL=http://mem0-server:8001" >> .env
    echo "MEM0_API_KEY=$(openssl rand -hex 32)" >> .env
    echo "ENABLE_MEM0=true" >> .env
    echo "✅ Đã thêm cấu hình Mem0 vào .env"
fi

# Tạo docker-compose.override.yaml nếu chưa có
if [ ! -f "docker-compose.override.yaml" ]; then
    cat > docker-compose.override.yaml << 'EOF'
services:
  mem0:
    container_name: mem0-server
    image: python:3.11-slim
    restart: always
    working_dir: /app
    command: >
      sh -c "
        pip install --no-cache-dir mem0ai &&
        python -m mem0.server --host 0.0.0.0 --port 8001
      "
    ports:
      - "8001:8001"
    environment:
      - MEM0_API_KEY=${MEM0_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./mem0_data:/app/data
    networks:
      - default
EOF
    echo "✅ Đã tạo docker-compose.override.yaml"
else
    echo "⚠️  docker-compose.override.yaml đã tồn tại, kiểm tra xem đã có mem0 service chưa"
fi

# Khởi động mem0
echo "🚀 Khởi động mem0 service..."
docker-compose up -d mem0

# Đợi mem0 khởi động
echo "⏳ Đợi mem0 khởi động (30 giây)..."
sleep 30

# Kiểm tra mem0 đang chạy
if docker ps | grep -q mem0-server; then
    echo "✅ Mem0 đã khởi động thành công!"
    echo ""
    echo "📊 Kiểm tra logs:"
    echo "   docker-compose logs -f mem0"
    echo ""
    echo "🔍 Kiểm tra health:"
    echo "   curl http://localhost:8001/health"
    echo ""
    echo "📝 Lưu ý:"
    echo "   - Đảm bảo OPENAI_API_KEY đã được cấu hình trong .env"
    echo "   - Mem0 sẽ tự động nhớ thông tin về người dùng từ các cuộc trò chuyện"
    echo "   - Cần tích hợp mem0 vào code LibreChat để sử dụng"
else
    echo "❌ Lỗi: Mem0 không khởi động được"
    echo "Xem logs: docker-compose logs mem0"
    exit 1
fi


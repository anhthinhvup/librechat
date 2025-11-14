#!/bin/bash
# Script nhanh để tắt phone verification - chạy từ bất kỳ đâu

echo "=== Tắt Phone Verification SMS ==="
echo ""

# Tìm thư mục dự án
echo "🔍 Đang tìm thư mục dự án LibreChat..."

# Thử các thư mục phổ biến
POSSIBLE_DIRS=(
    "/opt/librechat"
    "$HOME/librechat"
    "$HOME/LibreChat-main"
    "/var/www/librechat"
    "/home/librechat"
)

PROJECT_DIR=""

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [ -f "$dir/.env" ] || [ -f "$dir/docker-compose.yml" ]; then
        PROJECT_DIR="$dir"
        break
    fi
done

# Nếu không tìm thấy, dùng find
if [ -z "$PROJECT_DIR" ]; then
    echo "Đang tìm kiếm trong hệ thống..."
    FOUND=$(find /opt /home /var/www 2>/dev/null -name ".env" -path "*librechat*" | head -1)
    if [ -n "$FOUND" ]; then
        PROJECT_DIR=$(dirname "$FOUND")
    fi
fi

# Nếu vẫn không tìm thấy, thử tìm container
if [ -z "$PROJECT_DIR" ]; then
    CONTAINER=$(docker ps --format "{{.Names}}" | grep -i librechat | head -1)
    if [ -n "$CONTAINER" ]; then
        echo "⚠️  Tìm thấy container: $CONTAINER"
        echo "Nhưng không tìm thấy thư mục dự án."
        echo ""
        echo "Vui lòng chạy lệnh này thủ công:"
        echo "  cd /opt/librechat  # hoặc thư mục của bạn"
        echo "  echo 'ENABLE_PHONE_VERIFICATION=false' >> .env"
        echo "  docker-compose restart api"
        exit 1
    fi
fi

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Không tìm thấy thư mục dự án LibreChat"
    echo ""
    echo "Vui lòng:"
    echo "  1. Tìm thư mục có file .env hoặc docker-compose.yml"
    echo "  2. cd vào thư mục đó"
    echo "  3. Chạy: echo 'ENABLE_PHONE_VERIFICATION=false' >> .env"
    echo "  4. Chạy: docker-compose restart api"
    exit 1
fi

echo "✅ Tìm thấy: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# Kiểm tra file .env
if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại!"
    if [ -f env.example ]; then
        echo "Tạo từ env.example..."
        cp env.example .env
    else
        echo "❌ Không tìm thấy env.example"
        exit 1
    fi
fi

# Thêm hoặc cập nhật cấu hình
if grep -q "^ENABLE_PHONE_VERIFICATION=" .env 2>/dev/null; then
    echo "📝 Cập nhật ENABLE_PHONE_VERIFICATION=false..."
    sed -i 's/^ENABLE_PHONE_VERIFICATION=.*/ENABLE_PHONE_VERIFICATION=false/' .env
else
    echo "➕ Thêm ENABLE_PHONE_VERIFICATION=false..."
    echo "" >> .env
    echo "# Phone Verification - Disabled" >> .env
    echo "ENABLE_PHONE_VERIFICATION=false" >> .env
fi

echo ""
echo "✅ Đã cấu hình!"
echo ""
echo "📋 Kiểm tra:"
grep "ENABLE_PHONE_VERIFICATION" .env

echo ""
echo "🔄 Restart API..."
if command -v docker-compose &> /dev/null; then
    docker-compose restart api
elif command -v docker &> /dev/null; then
    docker restart LibreChat 2>/dev/null || docker restart $(docker ps --format "{{.Names}}" | grep -i librechat | head -1)
else
    echo "⚠️  Không tìm thấy docker-compose hoặc docker"
    echo "Vui lòng restart thủ công:"
    echo "  docker-compose restart api"
fi

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "Kiểm tra logs:"
echo "  docker logs -f LibreChat | grep registerUser"


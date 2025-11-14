#!/bin/bash
# Script để tắt phone verification SMS
# Chạy: bash deploy/disable-phone-verification.sh

# Tự động detect thư mục project
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Thử các thư mục phổ biến
POSSIBLE_DIRS=(
    "$PROJECT_ROOT"
    "/opt/librechat"
    "$HOME/librechat"
    "$HOME/LibreChat-main"
    "/var/www/librechat"
)

PROJECT_DIR=""

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/.env" ]; then
        PROJECT_DIR="$dir"
        break
    fi
done

# Nếu không tìm thấy, thử tìm bằng find
if [ -z "$PROJECT_DIR" ]; then
    FOUND_DIR=$(find /opt /home /var/www -name ".env" -path "*librechat*" 2>/dev/null | head -1 | xargs dirname)
    if [ -n "$FOUND_DIR" ] && [ -f "$FOUND_DIR/.env" ]; then
        PROJECT_DIR="$FOUND_DIR"
    fi
fi

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Không tìm thấy thư mục dự án LibreChat"
    echo "Hãy chạy script này từ thư mục có file .env"
    echo "Hoặc cd vào thư mục dự án trước:"
    echo "  cd /opt/librechat  # hoặc thư mục của bạn"
    exit 1
fi

echo "✅ Tìm thấy thư mục dự án: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# Kiểm tra file .env
if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại!"
    echo "Tạo file .env từ env.example..."
    if [ -f env.example ]; then
        cp env.example .env
        echo "✅ Đã tạo file .env"
    else
        echo "❌ Không tìm thấy env.example"
        exit 1
    fi
fi

# Kiểm tra đã có ENABLE_PHONE_VERIFICATION chưa
if grep -q "^ENABLE_PHONE_VERIFICATION=" .env 2>/dev/null; then
    echo "⚠️  Đã có ENABLE_PHONE_VERIFICATION trong .env"
    echo "Cập nhật giá trị thành false..."
    # Cập nhật giá trị
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's/^ENABLE_PHONE_VERIFICATION=.*/ENABLE_PHONE_VERIFICATION=false/' .env
    else
        # Linux
        sed -i 's/^ENABLE_PHONE_VERIFICATION=.*/ENABLE_PHONE_VERIFICATION=false/' .env
    fi
    echo "✅ Đã cập nhật ENABLE_PHONE_VERIFICATION=false"
else
    echo "Thêm ENABLE_PHONE_VERIFICATION=false vào .env..."
    echo "" >> .env
    echo "# Phone Verification - Disabled" >> .env
    echo "ENABLE_PHONE_VERIFICATION=false" >> .env
    echo "✅ Đã thêm ENABLE_PHONE_VERIFICATION=false"
fi

echo ""
echo "📋 Kiểm tra cấu hình:"
grep "ENABLE_PHONE_VERIFICATION" .env

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "Bước tiếp theo:"
if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
    echo "  1. Restart API: docker-compose restart api"
    echo "  2. Kiểm tra logs: docker-compose logs -f api | grep registerUser"
else
    echo "  1. Restart server: npm run backend:dev"
    echo "  2. Kiểm tra logs để thấy: Phone verification is disabled"
fi
echo ""
echo "📖 Để bật lại: Sửa ENABLE_PHONE_VERIFICATION=true trong .env"


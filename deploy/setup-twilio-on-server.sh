#!/bin/bash
# Script để cấu hình Twilio SMS provider
# Chạy: bash deploy/setup-twilio-on-server.sh

# Tự động detect thư mục project
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

echo "=== Cấu hình Twilio SMS ==="
echo ""

# Kiểm tra file .env
if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    echo "Tạo file .env từ env.example..."
    cp env.example .env
fi

# Nhập thông tin Twilio
echo "Nhập Twilio Account SID:"
read TWILIO_ACCOUNT_SID

echo "Nhập Twilio Auth Token:"
read -s TWILIO_AUTH_TOKEN
echo ""

echo "Nhập số điện thoại Twilio (format: +1234567890):"
read TWILIO_PHONE

if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ] || [ -z "$TWILIO_PHONE" ]; then
    echo "❌ Tất cả các trường đều bắt buộc!"
    exit 1
fi

# Kiểm tra xem đã có cấu hình SMS chưa
if grep -q "SMS_PROVIDER" .env; then
    echo "⚠️  Đã có cấu hình SMS, sẽ cập nhật..."
    # Xóa các dòng cũ
    sed -i '/^SMS_PROVIDER=/d' .env
    sed -i '/^TWILIO_ACCOUNT_SID=/d' .env
    sed -i '/^TWILIO_AUTH_TOKEN=/d' .env
    sed -i '/^TWILIO_PHONE_NUMBER=/d' .env
fi

# Thêm cấu hình mới
cat >> .env << EOF

# SMS Configuration - Twilio
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN
TWILIO_PHONE_NUMBER=$TWILIO_PHONE
EOF

# Xóa cấu hình HTTP API và AWS nếu có (để tránh conflict)
if grep -q "SMS_HTTP_API_URL" .env; then
    echo "⚠️  Đang xóa cấu hình HTTP API cũ..."
    sed -i '/^SMS_HTTP_/d' .env
fi

if grep -q "AWS_ACCESS_KEY_ID" .env; then
    echo "⚠️  Đang xóa cấu hình AWS SNS cũ..."
    sed -i '/^AWS_ACCESS_KEY_ID=/d' .env
    sed -i '/^AWS_SECRET_ACCESS_KEY=/d' .env
    sed -i '/^AWS_SNS_REGION=/d' .env
fi

echo ""
echo "✅ Đã thêm cấu hình Twilio vào .env"
echo ""
echo "Thông tin đã cấu hình:"
echo "  - Provider: Twilio"
echo "  - Account SID: ${TWILIO_ACCOUNT_SID:0:10}..."
echo "  - Phone Number: $TWILIO_PHONE"
echo ""
echo "⚠️  LƯU Ý: File .env chứa thông tin nhạy cảm, không commit vào git!"
echo ""
echo "📖 Lưu ý về Trial Account:"
echo "  - Trial account chỉ gửi được SMS đến số đã verify"
echo "  - Verify số tại: https://www.twilio.com/console/phone-numbers/verified"
echo "  - Upgrade account để gửi đến bất kỳ số nào"
echo ""
echo "Bước tiếp theo:"
if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
    echo "  1. Restart API: docker-compose restart api"
    echo "  2. Kiểm tra logs: docker-compose logs -f api | grep SMSService"
else
    echo "  1. Restart server: npm run backend:dev"
    echo "  2. Kiểm tra logs để thấy: [SMSService] Twilio client initialized"
fi
echo ""
echo "📖 Xem thêm hướng dẫn: deploy/TWILIO_SETUP.md"

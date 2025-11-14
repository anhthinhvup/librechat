#!/bin/bash
# Script để cấu hình Twilio trên server
# Chạy: bash deploy/setup-twilio-on-server.sh

cd /opt/librechat || exit 1

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

echo ""
echo "✅ Đã thêm cấu hình Twilio vào .env"
echo ""
echo "⚠️  LƯU Ý: File .env chứa thông tin nhạy cảm, không commit vào git!"
echo ""
echo "Bước tiếp theo:"
echo "  1. Install dependencies: cd api && npm install && cd .."
echo "  2. Build lại image: docker build -f Dockerfile.multi --target api-build -t librechat-api:local ."
echo "  3. Restart: docker-compose down && docker-compose up -d"
echo "  4. Kiểm tra logs: docker-compose logs -f api | grep SMSService"

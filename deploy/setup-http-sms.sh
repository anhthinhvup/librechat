#!/bin/bash
# Script để cấu hình HTTP API SMS provider
# Chạy: bash deploy/setup-http-sms.sh

cd "$(dirname "$0")/.." || exit 1

echo "=== Cấu hình HTTP API SMS Provider ==="
echo ""

if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    echo "Tạo file .env từ env.example..."
    cp env.example .env
fi

echo ""
echo "Nhập API URL endpoint của SMS provider:"
echo "(Ví dụ: https://api.example.com/sms/send)"
read SMS_HTTP_API_URL

if [ -z "$SMS_HTTP_API_URL" ]; then
    echo "❌ API URL không được để trống!"
    exit 1
fi

echo ""
echo "Nhập API Key:"
read SMS_HTTP_API_KEY

if [ -z "$SMS_HTTP_API_KEY" ]; then
    echo "❌ API Key không được để trống!"
    exit 1
fi

echo ""
echo "Nhập API Secret (Enter để bỏ qua nếu không cần):"
read SMS_HTTP_API_SECRET

echo ""
echo "Nhập số điện thoại gửi (Enter để bỏ qua nếu không cần):"
echo "(Format: +1234567890)"
read SMS_HTTP_FROM_NUMBER

# Xóa cấu hình SMS cũ nếu có
if grep -q "SMS_PROVIDER" .env; then
    echo "⚠️  Đã có cấu hình SMS, sẽ cập nhật..."
    sed -i '/^SMS_PROVIDER=/d' .env
    sed -i '/^SMS_HTTP_/d' .env
fi

# Xóa cấu hình Twilio và AWS nếu có (để tránh conflict)
if grep -q "TWILIO_ACCOUNT_SID" .env; then
    echo "⚠️  Đang xóa cấu hình Twilio cũ..."
    sed -i '/^TWILIO_ACCOUNT_SID=/d' .env
    sed -i '/^TWILIO_AUTH_TOKEN=/d' .env
    sed -i '/^TWILIO_PHONE_NUMBER=/d' .env
fi

if grep -q "AWS_ACCESS_KEY_ID" .env; then
    echo "⚠️  Đang xóa cấu hình AWS SNS cũ..."
    sed -i '/^AWS_ACCESS_KEY_ID=/d' .env
    sed -i '/^AWS_SECRET_ACCESS_KEY=/d' .env
    sed -i '/^AWS_SNS_REGION=/d' .env
fi

# Thêm cấu hình mới
cat >> .env << EOF

# SMS Configuration - HTTP API
SMS_PROVIDER=http
SMS_HTTP_API_URL=$SMS_HTTP_API_URL
SMS_HTTP_API_KEY=$SMS_HTTP_API_KEY
EOF

if [ -n "$SMS_HTTP_API_SECRET" ]; then
    echo "SMS_HTTP_API_SECRET=$SMS_HTTP_API_SECRET" >> .env
fi

if [ -n "$SMS_HTTP_FROM_NUMBER" ]; then
    echo "SMS_HTTP_FROM_NUMBER=$SMS_HTTP_FROM_NUMBER" >> .env
fi

echo ""
echo "✅ Đã thêm cấu hình HTTP API SMS vào .env"
echo ""
echo "Thông tin đã cấu hình:"
echo "  - Provider: HTTP API"
echo "  - API URL: $SMS_HTTP_API_URL"
echo ""
echo "⚠️  LƯU Ý: File .env chứa thông tin nhạy cảm, không commit vào git!"
echo ""
echo "Bước tiếp theo:"
echo "  1. Nếu cần, chỉnh sửa thêm các biến SMS_HTTP_* trong .env"
echo "  2. Restart API: docker-compose restart api"
echo "  3. Kiểm tra logs: docker-compose logs -f api | grep SMSService"
echo ""
echo "📖 Xem thêm hướng dẫn chi tiết: deploy/HTTP_SMS_SETUP.md"


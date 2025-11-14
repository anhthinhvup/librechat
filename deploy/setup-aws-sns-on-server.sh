#!/bin/bash
# Script để cấu hình AWS SNS trên server
# Chạy: bash deploy/setup-aws-sns-on-server.sh

cd /opt/librechat || exit 1

echo "=== Cấu hình AWS SNS SMS ==="
echo ""

if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    echo "Tạo file .env từ env.example..."
    cp env.example .env
fi

echo ""
echo "Nhập AWS Access Key ID của bạn:"
read AWS_ACCESS_KEY_ID

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "❌ Access Key ID không được để trống!"
    exit 1
fi

echo "Nhập AWS Secret Access Key của bạn:"
read AWS_SECRET_ACCESS_KEY

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ Secret Access Key không được để trống!"
    exit 1
fi

echo "Nhập AWS Region (mặc định: us-east-1):"
read AWS_REGION

if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
fi

# Xóa cấu hình SMS cũ nếu có
if grep -q "SMS_PROVIDER" .env; then
    echo "⚠️  Đã có cấu hình SMS, sẽ cập nhật..."
    sed -i '/^SMS_PROVIDER=/d' .env
    sed -i '/^AWS_ACCESS_KEY_ID=/d' .env
    sed -i '/^AWS_SECRET_ACCESS_KEY=/d' .env
    sed -i '/^AWS_SNS_REGION=/d' .env
    sed -i '/^AWS_REGION=/d' .env
fi

# Xóa cấu hình Twilio nếu có (để tránh conflict)
if grep -q "TWILIO_ACCOUNT_SID" .env; then
    echo "⚠️  Đang xóa cấu hình Twilio cũ..."
    sed -i '/^TWILIO_ACCOUNT_SID=/d' .env
    sed -i '/^TWILIO_AUTH_TOKEN=/d' .env
    sed -i '/^TWILIO_PHONE_NUMBER=/d' .env
fi

cat >> .env << EOF

# SMS Configuration - AWS SNS
SMS_PROVIDER=aws
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_SNS_REGION=$AWS_REGION
EOF

echo ""
echo "✅ Đã thêm cấu hình AWS SNS vào .env"
echo ""
echo "Thông tin đã cấu hình:"
echo "  - Provider: AWS SNS"
echo "  - Region: $AWS_REGION"
echo ""
echo "⚠️  LƯU Ý: File .env chứa thông tin nhạy cảm, không commit vào git!"
echo ""
echo "Bước tiếp theo:"
echo "  1. Restart API: docker-compose restart api"
echo "  2. Kiểm tra logs: docker-compose logs -f api | grep SMSService"
echo "  3. Test đăng ký với số điện thoại"
echo ""


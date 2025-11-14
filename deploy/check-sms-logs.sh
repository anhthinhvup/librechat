#!/bin/bash
# Script để kiểm tra SMS logs và cấu hình
# Chạy: bash deploy/check-sms-logs.sh

cd /opt/librechat || exit 1

echo "=== Kiểm tra SMS Configuration và Logs ==="
echo ""

# 1. Kiểm tra Twilio credentials trong .env
echo "1. Kiểm tra Twilio credentials:"
if grep -q "TWILIO_ACCOUNT_SID" .env 2>/dev/null; then
    echo "✓ TWILIO_ACCOUNT_SID: Đã cấu hình"
    grep "TWILIO_ACCOUNT_SID" .env | sed 's/=.*/=***/' 
else
    echo "✗ TWILIO_ACCOUNT_SID: CHƯA cấu hình"
fi

if grep -q "TWILIO_AUTH_TOKEN" .env 2>/dev/null; then
    echo "✓ TWILIO_AUTH_TOKEN: Đã cấu hình"
    grep "TWILIO_AUTH_TOKEN" .env | sed 's/=.*/=***/' 
else
    echo "✗ TWILIO_AUTH_TOKEN: CHƯA cấu hình"
fi

if grep -q "TWILIO_PHONE_NUMBER" .env 2>/dev/null; then
    echo "✓ TWILIO_PHONE_NUMBER: Đã cấu hình"
    grep "TWILIO_PHONE_NUMBER" .env
else
    echo "✗ TWILIO_PHONE_NUMBER: CHƯA cấu hình"
fi

if grep -q "SMS_PROVIDER" .env 2>/dev/null; then
    echo "✓ SMS_PROVIDER:"
    grep "SMS_PROVIDER" .env
else
    echo "⚠ SMS_PROVIDER: Không có (sẽ dùng auto-detect)"
fi

echo ""

# 2. Kiểm tra SMS service logs
echo "2. Kiểm tra SMS Service logs (50 dòng cuối):"
docker-compose logs --tail=50 api | grep -E "SMSService|sendPhoneVerificationOTP|Twilio|SNS" || echo "Không tìm thấy SMS logs"
echo ""

# 3. Kiểm tra phone verification logs
echo "3. Kiểm tra Phone Verification logs (50 dòng cuối):"
docker-compose logs --tail=100 api | grep -E "sendPhoneVerificationOTP|OTP sent|Failed to send SMS|Development mode" || echo "Không tìm thấy phone verification logs"
echo ""

# 4. Kiểm tra NODE_ENV
echo "4. Kiểm tra NODE_ENV:"
if grep -q "NODE_ENV" .env 2>/dev/null; then
    grep "NODE_ENV" .env
else
    echo "⚠ NODE_ENV: Không có (mặc định là development)"
fi
echo ""

# 5. Đề xuất
echo "=== ĐỀ XUẤT ==="
echo ""
if ! grep -q "TWILIO_ACCOUNT_SID" .env 2>/dev/null; then
    echo "⚠ Twilio chưa được cấu hình!"
    echo "Chạy: bash deploy/setup-twilio-on-server.sh"
    echo ""
fi

echo "Để xem logs real-time khi đăng ký:"
echo "  docker-compose logs -f api | grep -E 'sendPhoneVerificationOTP|SMSService|OTP'"
echo ""


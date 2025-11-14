#!/bin/bash
# Script để kiểm tra SMS logs và cấu hình
# Chạy: bash deploy/check-sms-logs.sh

# Tự động tìm thư mục dự án
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
    if [ -f "$dir/docker-compose.yml" ]; then
        PROJECT_DIR="$dir"
        break
    fi
done

# Nếu không tìm thấy, thử tìm bằng find
if [ -z "$PROJECT_DIR" ]; then
    FOUND_DIR=$(find /opt /home /var/www -name "docker-compose.yml" -path "*librechat*" 2>/dev/null | head -1 | xargs dirname)
    if [ -n "$FOUND_DIR" ] && [ -f "$FOUND_DIR/docker-compose.yml" ]; then
        PROJECT_DIR="$FOUND_DIR"
    fi
fi

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Không tìm thấy thư mục dự án LibreChat"
    echo "Hãy chạy script này từ thư mục có file docker-compose.yml"
    echo "Hoặc cd vào thư mục dự án trước:"
    echo "  cd /opt/librechat  # hoặc thư mục của bạn"
    exit 1
fi

echo "✅ Tìm thấy thư mục dự án: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

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
echo "  cd $PROJECT_DIR"
echo "  docker-compose logs -f api | grep -E 'sendPhoneVerificationOTP|SMSService|OTP'"
echo ""
echo "Hoặc dùng lệnh này từ bất kỳ đâu:"
echo "  docker logs -f LibreChat | grep -E 'sendPhoneVerificationOTP|SMSService|OTP'"
echo ""


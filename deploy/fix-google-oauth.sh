#!/bin/bash

# Script sửa lỗi Google OAuth cho production

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔧 Sửa lỗi Google OAuth cho Production..."

# Kiểm tra .env có tồn tại không
if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    exit 1
fi

# Kiểm tra Google OAuth credentials
echo ""
echo "📋 Kiểm tra Google OAuth credentials hiện tại:"
grep GOOGLE .env | grep -v "^#" || echo "⚠️  Không tìm thấy GOOGLE_CLIENT_ID hoặc GOOGLE_CLIENT_SECRET"

echo ""
echo "🔍 Kiểm tra DOMAIN_SERVER:"
grep DOMAIN_SERVER .env | grep -v "^#" || echo "⚠️  Không tìm thấy DOMAIN_SERVER"

echo ""
echo "📝 Hướng dẫn sửa:"
echo ""
echo "1. Tạo Google OAuth Client ID tại: https://console.cloud.google.com/apis/credentials"
echo "2. Authorized redirect URIs: https://chat.daydemy.com/api/oauth/google/callback"
echo "3. Authorized JavaScript origins: https://chat.daydemy.com"
echo ""
echo "4. Sửa file .env:"
echo "   vi .env"
echo ""
echo "5. Tìm và sửa:"
echo "   GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
echo "   Thành:"
echo "   GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com"
echo ""
echo "   GOOGLE_CLIENT_SECRET=YOUR_GOOGLE_CLIENT_SECRET"
echo "   Thành:"
echo "   GOOGLE_CLIENT_SECRET=GOCSPX-abcdefghijklmnopqrstuvwxyz"
echo ""
echo "6. Sau khi sửa, chạy:"
echo "   docker-compose restart api"
echo ""

# Kiểm tra xem đã có credentials thật chưa
if grep -q "GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID" .env || grep -q "GOOGLE_CLIENT_ID=$" .env; then
    echo "⚠️  Google OAuth credentials chưa được cấu hình!"
    echo "💡 Cần cập nhật GOOGLE_CLIENT_ID và GOOGLE_CLIENT_SECRET trong .env"
else
    echo "✅ Google OAuth credentials đã được cấu hình"
    echo ""
    echo "🔄 Restart container để load .env mới..."
    docker-compose restart api
    sleep 5
    echo ""
    echo "📋 Kiểm tra credentials đã được load:"
    docker exec LibreChat env | grep GOOGLE_CLIENT || echo "⚠️  Không tìm thấy trong container"
fi

echo ""
echo "✅ Hoàn tất!"


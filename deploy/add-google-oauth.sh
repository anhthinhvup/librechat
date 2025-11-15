#!/bin/bash

# Script thêm Google OAuth credentials vào .env

set -e

cd "$(dirname "$0")/.." || exit 1

CLIENT_ID="485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com"
CLIENT_SECRET="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"

echo "🔧 Thêm Google OAuth credentials vào .env..."

# Kiểm tra .env có tồn tại không
if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    exit 1
fi

# Backup .env
BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
cp .env "$BACKUP_FILE"
echo "✅ Đã backup .env thành $BACKUP_FILE"

# Sửa GOOGLE_CLIENT_ID
if grep -q "^GOOGLE_CLIENT_ID=" .env; then
    sed -i "s|^GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=$CLIENT_ID|" .env
    echo "✅ Đã cập nhật GOOGLE_CLIENT_ID"
else
    echo "GOOGLE_CLIENT_ID=$CLIENT_ID" >> .env
    echo "✅ Đã thêm GOOGLE_CLIENT_ID"
fi

# Sửa GOOGLE_CLIENT_SECRET
if grep -q "^GOOGLE_CLIENT_SECRET=" .env; then
    sed -i "s|^GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=$CLIENT_SECRET|" .env
    echo "✅ Đã cập nhật GOOGLE_CLIENT_SECRET"
else
    echo "GOOGLE_CLIENT_SECRET=$CLIENT_SECRET" >> .env
    echo "✅ Đã thêm GOOGLE_CLIENT_SECRET"
fi

# Kiểm tra DOMAIN_SERVER
if ! grep -q "^DOMAIN_SERVER=https://chat.daydemy.com" .env; then
    echo ""
    echo "⚠️  DOMAIN_SERVER có thể chưa đúng!"
    echo "📋 Kiểm tra:"
    grep DOMAIN_SERVER .env || echo "  Không tìm thấy DOMAIN_SERVER"
    echo ""
    echo "💡 Đảm bảo DOMAIN_SERVER=https://chat.daydemy.com"
fi

# Kiểm tra đã sửa đúng chưa
echo ""
echo "📋 Kiểm tra credentials đã được thêm:"
grep GOOGLE_CLIENT .env

# Restart container
echo ""
echo "🔄 Restart container để load .env mới..."
docker-compose restart api

# Đợi container start
sleep 5

# Kiểm tra credentials đã được load
echo ""
echo "📋 Kiểm tra credentials đã được load trong container:"
docker exec LibreChat env | grep GOOGLE_CLIENT || echo "⚠️  Không tìm thấy trong container"

echo ""
echo "✅ Hoàn tất!"
echo ""
echo "💡 Kiểm tra website: https://chat.daydemy.com/register"
echo "💡 Click 'Continue with Google' để test"


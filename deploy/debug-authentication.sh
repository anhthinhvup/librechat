#!/bin/bash

# Script debug lỗi Authentication failed

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔍 Debug lỗi Authentication failed..."
echo ""

# 1. Kiểm tra .env file
echo "📋 1. Kiểm tra .env file:"
echo "----------------------------------------"
grep -E "GOOGLE_CLIENT|JWT_SECRET|JWT_REFRESH|DOMAIN_SERVER" .env | grep -v "^#" || echo "⚠️  Không tìm thấy các biến này"
echo ""

# 2. Kiểm tra credentials trong container
echo "📋 2. Kiểm tra credentials trong container:"
echo "----------------------------------------"
echo "GOOGLE_CLIENT_ID:"
docker exec LibreChat env | grep GOOGLE_CLIENT_ID || echo "  ❌ Không tìm thấy"
echo ""
echo "GOOGLE_CLIENT_SECRET:"
docker exec LibreChat env | grep GOOGLE_CLIENT_SECRET || echo "  ❌ Không tìm thấy"
echo ""
echo "JWT_SECRET:"
docker exec LibreChat env | grep JWT_SECRET | head -1 || echo "  ❌ Không tìm thấy"
echo ""
echo "JWT_REFRESH_SECRET:"
docker exec LibreChat env | grep JWT_REFRESH_SECRET || echo "  ❌ Không tìm thấy"
echo ""
echo "DOMAIN_SERVER:"
docker exec LibreChat env | grep DOMAIN_SERVER || echo "  ❌ Không tìm thấy"
echo ""

# 3. Kiểm tra MongoDB
echo "📋 3. Kiểm tra MongoDB:"
echo "----------------------------------------"
if docker ps | grep -q chat-mongodb; then
    echo "✅ MongoDB đang chạy"
    MONGO_URI=$(docker exec LibreChat env | grep MONGO_URI)
    echo "  $MONGO_URI"
else
    echo "❌ MongoDB không chạy!"
fi
echo ""

# 4. Kiểm tra logs gần đây
echo "📋 4. Logs gần đây (có lỗi auth/login):"
echo "----------------------------------------"
docker logs LibreChat --tail 50 | grep -i "auth\|login\|jwt\|error\|fail" | tail -10 || echo "  Không tìm thấy logs liên quan"
echo ""

# 5. Kiểm tra API
echo "📋 5. Kiểm tra API:"
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ API phản hồi (HTTP $HTTP_CODE)"
else
    echo "❌ API không phản hồi (HTTP $HTTP_CODE)"
fi
echo ""

# 6. Đề xuất sửa
echo "📋 6. Đề xuất sửa:"
echo "----------------------------------------"

# Kiểm tra JWT_SECRET
if ! docker exec LibreChat env | grep -q "JWT_SECRET=" || docker exec LibreChat env | grep "JWT_SECRET=" | grep -q "CHANGE_THIS\|YOUR_"; then
    echo "⚠️  JWT_SECRET chưa được cấu hình hoặc là placeholder"
    echo "💡 Chạy:"
    echo "   JWT_SECRET=\$(openssl rand -base64 32)"
    echo "   JWT_REFRESH_SECRET=\$(openssl rand -base64 32)"
    echo "   sed -i \"s|JWT_SECRET=.*|JWT_SECRET=\$JWT_SECRET|\" .env"
    echo "   sed -i \"s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=\$JWT_REFRESH_SECRET|\" .env"
    echo "   docker-compose restart api"
    echo ""
fi

# Kiểm tra Google OAuth
if ! docker exec LibreChat env | grep -q "GOOGLE_CLIENT_ID=485772400461"; then
    echo "⚠️  Google OAuth credentials chưa được load"
    echo "💡 Chạy:"
    echo "   sed -i 's|GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com|' .env"
    echo "   sed -i 's|GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=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|' .env"
    echo "   docker-compose restart api"
    echo ""
fi

# Kiểm tra DOMAIN_SERVER
if ! docker exec LibreChat env | grep -q "DOMAIN_SERVER=https://chat.daydemy.com"; then
    echo "⚠️  DOMAIN_SERVER chưa đúng"
    echo "💡 Chạy:"
    echo "   sed -i 's|DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.daydemy.com|' .env"
    echo "   docker-compose restart api"
    echo ""
fi

echo "✅ Hoàn tất debug!"
echo ""
echo "💡 Xem logs real-time khi đăng nhập:"
echo "   docker logs LibreChat --tail 100 -f"


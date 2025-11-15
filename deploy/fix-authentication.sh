#!/bin/bash

# Script sửa lỗi Authentication failed

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔧 Sửa lỗi Authentication failed..."

# 1. Kiểm tra Google OAuth credentials
echo ""
echo "📋 Kiểm tra Google OAuth credentials:"
if grep -q "GOOGLE_CLIENT_ID=485772400461" .env; then
    echo "✅ Google OAuth credentials đã được cấu hình"
else
    echo "⚠️  Google OAuth credentials chưa được cấu hình"
    echo "💡 Đang thêm credentials..."
    sed -i 's|GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=485772400461-dt81m035g7e106m1s76nkap7kijhg51u.apps.googleusercontent.com|' .env
    sed -i 's|GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=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|' .env
    echo "✅ Đã thêm Google OAuth credentials"
fi

# 2. Kiểm tra DOMAIN_SERVER
echo ""
echo "📋 Kiểm tra DOMAIN_SERVER:"
if grep -q "DOMAIN_SERVER=https://chat.daydemy.com" .env; then
    echo "✅ DOMAIN_SERVER đúng"
else
    echo "⚠️  DOMAIN_SERVER chưa đúng, đang sửa..."
    sed -i 's|DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.daydemy.com|' .env
    echo "✅ Đã sửa DOMAIN_SERVER"
fi

# 3. Kiểm tra JWT secrets
echo ""
echo "📋 Kiểm tra JWT secrets:"
if grep -q "^JWT_SECRET=" .env && ! grep -q "CHANGE_THIS\|YOUR_" .env; then
    echo "✅ JWT secrets đã được cấu hình"
else
    echo "⚠️  JWT secrets chưa được cấu hình, đang tạo mới..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    
    if grep -q "^JWT_SECRET=" .env; then
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    else
        echo "JWT_SECRET=$JWT_SECRET" >> .env
    fi
    
    if grep -q "^JWT_REFRESH_SECRET=" .env; then
        sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
    else
        echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" >> .env
    fi
    
    echo "✅ Đã tạo JWT secrets mới"
fi

# 4. Kiểm tra MongoDB
echo ""
echo "📋 Kiểm tra MongoDB:"
if docker ps | grep -q chat-mongodb; then
    echo "✅ MongoDB đang chạy"
else
    echo "❌ MongoDB không chạy!"
    echo "💡 Đang start MongoDB..."
    docker-compose up -d mongodb
    sleep 10
fi

# 5. Restart API
echo ""
echo "🔄 Restart API để load cấu hình mới..."
docker-compose restart api

# Đợi API start
echo "⏳ Đợi API khởi động..."
sleep 10

# 6. Kiểm tra logs
echo ""
echo "📋 Kiểm tra logs (20 dòng cuối):"
docker logs LibreChat --tail 20 | grep -i "error\|auth\|oauth\|listening" | tail -10 || docker logs LibreChat --tail 10

# 7. Kiểm tra API
echo ""
echo "🌐 Kiểm tra API:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3080 || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ API phản hồi (HTTP $HTTP_CODE)"
else
    echo "⚠️  API không phản hồi (HTTP $HTTP_CODE)"
fi

echo ""
echo "✅ Hoàn tất!"
echo ""
echo "💡 Kiểm tra website: https://chat.daydemy.com/login"
echo "💡 Thử đăng nhập lại"


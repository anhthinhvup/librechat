#!/bin/bash

# Script sửa lỗi không đăng nhập được

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔧 Sửa lỗi không đăng nhập được..."
echo ""

# 1. Kiểm tra JWT secrets
echo "📋 1. Kiểm tra JWT secrets:"
echo "----------------------------------------"

# Kiểm tra JWT_SECRET
if grep -q "^JWT_SECRET=" .env && ! grep -q "CHANGE_THIS\|YOUR_" .env | grep JWT_SECRET; then
    echo "✅ JWT_SECRET đã có"
else
    echo "⚠️  JWT_SECRET chưa có hoặc là placeholder, đang tạo mới..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    if grep -q "^JWT_SECRET=" .env; then
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    else
        echo "JWT_SECRET=$JWT_SECRET" >> .env
    fi
    echo "✅ Đã tạo JWT_SECRET"
fi

# Kiểm tra JWT_REFRESH_SECRET
if grep -q "^JWT_REFRESH_SECRET=" .env && ! grep -q "CHANGE_THIS\|YOUR_" .env | grep JWT_REFRESH; then
    echo "✅ JWT_REFRESH_SECRET đã có"
else
    echo "⚠️  JWT_REFRESH_SECRET chưa có hoặc là placeholder, đang tạo mới..."
    JWT_REFRESH_SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    if grep -q "^JWT_REFRESH_SECRET=" .env; then
        sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
    else
        echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" >> .env
    fi
    echo "✅ Đã tạo JWT_REFRESH_SECRET"
fi

echo ""

# 2. Kiểm tra trong container
echo "📋 2. Kiểm tra JWT secrets trong container:"
echo "----------------------------------------"
docker exec LibreChat env | grep JWT || echo "⚠️  Không tìm thấy JWT secrets trong container"
echo ""

# 3. Restart API
echo "🔄 3. Restart API để load cấu hình mới..."
docker-compose restart api

# Đợi API start
echo "⏳ Đợi API khởi động..."
sleep 10

# 4. Kiểm tra logs
echo ""
echo "📋 4. Kiểm tra logs (20 dòng cuối):"
docker logs LibreChat --tail 20 | grep -i "error\|auth\|listening" | tail -10 || docker logs LibreChat --tail 10

# 5. Kiểm tra user trong database
echo ""
echo "📋 5. Kiểm tra user trong database:"
echo "----------------------------------------"
USER_EXISTS=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({email:'phamvanthinhcontact2004@gmail.com'})" 2>/dev/null | tr -d '\r\n' || echo "0")
if [ "$USER_EXISTS" = "1" ]; then
    echo "✅ User tồn tại trong database"
    echo ""
    echo "📋 Thông tin user:"
    docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.findOne({email:'phamvanthinhcontact2004@gmail.com'}, {email:1, provider:1, createdAt:1})" 2>/dev/null | python3 -m json.tool 2>/dev/null || docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.findOne({email:'phamvanthinhcontact2004@gmail.com'}, {email:1, provider:1, createdAt:1})" 2>/dev/null
else
    echo "❌ User không tồn tại trong database"
    echo "💡 Có thể đăng ký chưa hoàn tất"
fi

echo ""
echo "✅ Hoàn tất!"
echo ""
echo "💡 Thử đăng nhập lại tại: https://chat.daydemy.com/login"
echo "💡 Đảm bảo nhập đúng email và password"
echo ""
echo "💡 Nếu vẫn lỗi, xem logs real-time:"
echo "   docker logs LibreChat --tail 100 -f"


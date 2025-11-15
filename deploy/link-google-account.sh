#!/bin/bash

# Script link Google account với user hiện có (CẨN THẬN!)

set -e

cd "$(dirname "$0")/.." || exit 1

EMAIL="phamvanthinhcontact2004@gmail.com"

echo "⚠️  CẢNH BÁO: Script này sẽ sửa database!"
echo "📋 Email: $EMAIL"
echo ""
read -p "Bạn có chắc muốn tiếp tục? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy"
    exit 1
fi

echo ""
echo "🔍 Tìm user trong database..."
USER_INFO=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "JSON.stringify(db.users.findOne({email:'$EMAIL'}))" 2>/dev/null)

if [ -z "$USER_INFO" ] || [ "$USER_INFO" = "null" ]; then
    echo "❌ Không tìm thấy user với email: $EMAIL"
    exit 1
fi

echo "✅ Tìm thấy user:"
echo "$USER_INFO" | python3 -m json.tool 2>/dev/null || echo "$USER_INFO"

echo ""
echo "💡 Để link Google account, bạn cần:"
echo "1. Thử đăng nhập bằng Google OAuth một lần"
echo "2. Xem logs để lấy Google ID:"
echo "   docker logs LibreChat --tail 50 | grep googleId"
echo ""
echo "3. Sau đó chạy lệnh MongoDB:"
echo "   docker exec -it chat-mongodb mongosh LibreChat"
echo ""
echo "4. Update user:"
echo "   db.users.updateOne("
echo "     { email: '$EMAIL' },"
echo "     { \$set: { provider: 'google', googleId: 'GOOGLE_ID_HERE' } }"
echo "   )"
echo ""
echo "⚠️  Hoặc đơn giản hơn: Đăng nhập bằng email/password!"


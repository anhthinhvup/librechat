#!/bin/bash

# Script set role admin cho phamvanthinhcontact2004@gmail.com

set -e

cd "$(dirname "$0")/.." || exit 1

EMAIL="phamvanthinhcontact2004@gmail.com"

echo "👤 Set role admin cho user: $EMAIL"
echo ""

# Kiểm tra user có tồn tại không
USER_EXISTS=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({email:'$EMAIL'})" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    echo "❌ User không tồn tại: $EMAIL"
    echo ""
    echo "💡 User có thể chưa đăng ký hoặc đã bị xóa"
    exit 1
fi

# Xem thông tin user hiện tại
echo "📋 Thông tin user hiện tại:"
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var user = db.users.findOne({email:'$EMAIL'}, {email:1, name:1, role:1, provider:1});
  if (user) {
    print('Email: ' + user.email);
    print('Name: ' + (user.name || 'N/A'));
    print('Current Role: ' + (user.role || 'USER'));
    print('Provider: ' + user.provider);
  }
" 2>/dev/null

echo ""
echo "🔄 Đang set role ADMIN..."

# Set role admin
RESULT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var result = db.users.updateOne(
    {email: '$EMAIL'},
    {\$set: {role: 'ADMIN'}}
  );
  print('Matched: ' + result.matchedCount);
  print('Modified: ' + result.modifiedCount);
" 2>/dev/null)

echo "$RESULT"

# Kiểm tra
echo ""
echo "📋 Kiểm tra sau khi update:"
CHECK_RESULT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var user = db.users.findOne({email:'$EMAIL'}, {email:1, role:1});
  if (user && user.role === 'ADMIN') {
    print('✅ User đã được set role ADMIN');
    print('Email: ' + user.email);
    print('Role: ' + user.role);
  } else if (user) {
    print('❌ Lỗi: Role vẫn là ' + (user.role || 'USER'));
  } else {
    print('❌ Không tìm thấy user');
  }
" 2>/dev/null)

echo "$CHECK_RESULT"

echo ""
echo "✅ Hoàn tất!"
echo ""
echo "💡 User $EMAIL giờ đã có quyền ADMIN"
echo "💡 Đăng nhập lại để sử dụng quyền admin"


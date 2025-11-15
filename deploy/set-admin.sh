#!/bin/bash

# Script set role admin cho user

set -e

cd "$(dirname "$0")/.." || exit 1

if [ -z "$1" ]; then
    echo "❌ Thiếu email!"
    echo ""
    echo "Cách dùng:"
    echo "  ./deploy/set-admin.sh EMAIL"
    echo ""
    echo "Ví dụ:"
    echo "  ./deploy/set-admin.sh phamvanthinhcontact2004@gmail.com"
    exit 1
fi

EMAIL="$1"

echo "👤 Set role admin cho user: $EMAIL"
echo ""

# Kiểm tra user có tồn tại không
USER_EXISTS=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({email:'$EMAIL'})" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    echo "❌ User không tồn tại: $EMAIL"
    exit 1
fi

# Xem thông tin user hiện tại
echo "📋 Thông tin user hiện tại:"
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var user = db.users.findOne({email:'$EMAIL'}, {email:1, name:1, role:1, provider:1});
  print('Email: ' + user.email);
  print('Name: ' + (user.name || 'N/A'));
  print('Current Role: ' + (user.role || 'USER'));
  print('Provider: ' + user.provider);
" 2>/dev/null

echo ""
read -p "Bạn có chắc muốn set role ADMIN cho user này? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy"
    exit 1
fi

# Set role admin
echo ""
echo "🔄 Đang set role ADMIN..."
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var result = db.users.updateOne(
    {email: '$EMAIL'},
    {\$set: {role: 'ADMIN'}}
  );
  print('Matched: ' + result.matchedCount);
  print('Modified: ' + result.modifiedCount);
" 2>/dev/null

# Kiểm tra
echo ""
echo "📋 Kiểm tra sau khi update:"
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  var user = db.users.findOne({email:'$EMAIL'}, {email:1, role:1});
  if (user.role === 'ADMIN') {
    print('✅ User đã được set role ADMIN');
  } else {
    print('❌ Lỗi: Role vẫn là ' + user.role);
  }
" 2>/dev/null

echo ""
echo "✅ Hoàn tất!"


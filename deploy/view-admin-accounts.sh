#!/bin/bash

# Script xem và quản lý account admin

set -e

cd "$(dirname "$0")/.." || exit 1

echo "👤 Xem account admin trong database..."
echo ""

# 1. Xem tất cả users và role
echo "📋 Tất cả users và role:"
echo "----------------------------------------"
docker exec chat-mongodb mongosh LibreChat --quiet --eval "
  db.users.find({}, {email:1, name:1, role:1, provider:1, createdAt:1}).sort({createdAt: -1}).forEach(
    function(user) {
      print('Email: ' + user.email);
      print('Name: ' + (user.name || 'N/A'));
      print('Role: ' + (user.role || 'USER'));
      print('Provider: ' + user.provider);
      print('Created: ' + user.createdAt);
      print('---');
    }
  )
" 2>/dev/null || echo "❌ Không thể kết nối MongoDB"

echo ""

# 2. Tìm admin users
echo "📋 Admin users:"
echo "----------------------------------------"
ADMIN_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({role:'ADMIN'})" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$ADMIN_COUNT" = "0" ]; then
    echo "⚠️  Không có admin user nào"
    echo ""
    echo "💡 Để tạo admin user, chạy:"
    echo "   ./deploy/set-admin.sh EMAIL"
else
    echo "✅ Tìm thấy $ADMIN_COUNT admin user(s):"
    echo ""
    docker exec chat-mongodb mongosh LibreChat --quiet --eval "
      db.users.find({role:'ADMIN'}, {email:1, name:1, role:1, provider:1}).forEach(
        function(user) {
          print('Email: ' + user.email);
          print('Name: ' + (user.name || 'N/A'));
          print('Provider: ' + user.provider);
          print('---');
        }
      )
    " 2>/dev/null
fi

echo ""
echo "✅ Hoàn tất!"


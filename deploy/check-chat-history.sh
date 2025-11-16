#!/bin/bash

# Script kiểm tra lịch sử chat trong MongoDB

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔍 Kiểm tra lịch sử chat trong MongoDB..."

# Kiểm tra MongoDB có chạy không
if ! docker ps | grep -q chat-mongodb; then
    echo "❌ MongoDB container không chạy!"
    echo "💡 Chạy: docker-compose up -d mongodb"
    exit 1
fi

echo ""
echo "📊 Thống kê lịch sử chat:"
echo ""

# Kiểm tra số lượng conversations
CONVO_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.conversations.countDocuments()" 2>/dev/null | tr -d '\r\n' || echo "0")
echo "📝 Số lượng conversations: $CONVO_COUNT"

# Kiểm tra số lượng messages
MSG_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.messages.countDocuments()" 2>/dev/null | tr -d '\r\n' || echo "0")
echo "💬 Số lượng messages: $MSG_COUNT"

# Kiểm tra số lượng users
USER_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments()" 2>/dev/null | tr -d '\r\n' || echo "0")
echo "👤 Số lượng users: $USER_COUNT"

echo ""
if [ "$CONVO_COUNT" = "0" ] && [ "$MSG_COUNT" = "0" ]; then
    echo "⚠️  Không có dữ liệu chat trong MongoDB!"
    echo "💡 Có thể đã mất khi reset MongoDB trước đó"
    echo ""
    echo "📋 Kiểm tra có backup không:"
    if [ -d "data-node.backup"* ] 2>/dev/null; then
        echo "✅ Tìm thấy backup:"
        ls -la data-node.backup* | head -5
        echo ""
        echo "💡 Để khôi phục, xem: deploy/CHECK_CHAT_HISTORY.md"
    else
        echo "❌ Không tìm thấy backup"
    fi
else
    echo "✅ Có dữ liệu chat trong MongoDB!"
    echo ""
    echo "📋 Xem 5 conversations gần nhất:"
    docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.conversations.find().sort({updatedAt: -1}).limit(5).forEach(doc => print('  - ' + doc.title + ' (ID: ' + doc.conversationId + ')'))" 2>/dev/null || echo "  Không thể đọc conversations"
fi

echo ""
echo "✅ Hoàn tất!"


#!/bin/bash

# Script xóa user và hướng dẫn đăng ký lại bằng Google

set -e

cd "$(dirname "$0")/.." || exit 1

EMAIL="phamvanthinhcontact2004@gmail.com"

echo "⚠️  CẢNH BÁO: Script này sẽ XÓA user và TẤT CẢ data!"
echo "📋 Email: $EMAIL"
echo ""
echo "Sẽ mất:"
echo "  - Tất cả conversations"
echo "  - Tất cả messages"
echo "  - Các cài đặt cá nhân"
echo ""
read -p "Bạn có chắc muốn tiếp tục? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy"
    exit 1
fi

echo ""
echo "🔍 Kiểm tra user trong database..."

# Kiểm tra user có tồn tại không
USER_EXISTS=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({email:'$EMAIL'})" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    echo "✅ User không tồn tại, có thể đã xóa hoặc chưa đăng ký"
    echo ""
    echo "💡 Bạn có thể đăng ký bằng Google OAuth tại:"
    echo "   https://chat.daydemy.com/register"
    exit 0
fi

echo "✅ Tìm thấy user"
echo ""

# Lấy user ID
USER_ID=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.findOne({email:'$EMAIL'})._id" 2>/dev/null | tr -d '\r\n' || echo "")

if [ -z "$USER_ID" ]; then
    echo "❌ Không lấy được user ID"
    exit 1
fi

echo "📋 User ID: $USER_ID"
echo ""

# Đếm conversations và messages
CONVO_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.conversations.countDocuments({user:'$USER_ID'})" 2>/dev/null | tr -d '\r\n' || echo "0")
MSG_COUNT=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.messages.countDocuments({user:'$USER_ID'})" 2>/dev/null | tr -d '\r\n' || echo "0")

echo "📊 Số lượng sẽ bị xóa:"
echo "  - Conversations: $CONVO_COUNT"
echo "  - Messages: $MSG_COUNT"
echo ""

read -p "Xác nhận xóa? (yes/no): " confirm2

if [ "$confirm2" != "yes" ]; then
    echo "❌ Đã hủy"
    exit 1
fi

echo ""
echo "🗑️  Đang xóa..."

# Xóa conversations
if [ "$CONVO_COUNT" != "0" ]; then
    docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.conversations.deleteMany({user:'$USER_ID'})" > /dev/null 2>&1
    echo "✅ Đã xóa $CONVO_COUNT conversations"
fi

# Xóa messages
if [ "$MSG_COUNT" != "0" ]; then
    docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.messages.deleteMany({user:'$USER_ID'})" > /dev/null 2>&1
    echo "✅ Đã xóa $MSG_COUNT messages"
fi

# Xóa user
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.deleteOne({email:'$EMAIL'})" > /dev/null 2>&1
echo "✅ Đã xóa user"

# Kiểm tra
USER_EXISTS_AFTER=$(docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.countDocuments({email:'$EMAIL'})" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$USER_EXISTS_AFTER" = "0" ]; then
    echo ""
    echo "✅ Hoàn tất! User đã được xóa"
    echo ""
    echo "📋 Bước tiếp theo:"
    echo "1. Truy cập: https://chat.daydemy.com/register"
    echo "2. Click 'Continue with Google'"
    echo "3. Chọn tài khoản Google của bạn"
    echo "4. Cho phép quyền truy cập"
    echo "5. Đăng ký hoàn tất"
    echo ""
    echo "✅ Sau đó bạn sẽ có thể đăng nhập bằng Google OAuth!"
else
    echo ""
    echo "❌ Lỗi: User vẫn còn trong database"
    echo "💡 Kiểm tra lại:"
    echo "   docker exec chat-mongodb mongosh LibreChat --quiet --eval \"db.users.findOne({email:'$EMAIL'})\""
fi


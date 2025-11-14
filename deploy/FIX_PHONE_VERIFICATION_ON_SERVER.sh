#!/bin/bash
# Script sửa trực tiếp trong container để ẩn phone field
# Chạy: bash deploy/FIX_PHONE_VERIFICATION_ON_SERVER.sh

cd /opt/librechat || exit 1

echo "=== Sửa Phone Verification trên Server ==="
echo ""

# Kiểm tra container đang chạy
if ! docker ps | grep -q LibreChat-API; then
    echo "❌ Container LibreChat-API không chạy!"
    exit 1
fi

echo "1. Backup file cũ trong container..."
docker exec LibreChat-API cp /app/client/src/components/Auth/Registration.tsx /app/client/src/components/Auth/Registration.tsx.backup

echo "2. Sửa file trong container..."
# Comment out phone field
docker exec LibreChat-API sh -c "sed -i \"s/{renderInput('phone'/{{\/* renderInput('phone'/g\" /app/client/src/components/Auth/Registration.tsx"
docker exec LibreChat-API sh -c "sed -i \"s/})}/}) *\/}/g\" /app/client/src/components/Auth/Registration.tsx"

echo "3. Restart container..."
docker-compose restart api

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "Lưu ý: Thay đổi này sẽ mất khi container được rebuild."
echo "Để giữ lâu dài, cần build lại image với code mới."


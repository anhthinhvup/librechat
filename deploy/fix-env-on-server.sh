#!/bin/bash
# Script để tạo và cấu hình .env trên server

cd /opt/librechat || exit

echo "=== Tạo file .env từ template ==="

# Copy từ template
if [ -f "deploy/env.production" ]; then
    cp deploy/env.production .env
    echo "✓ Đã copy deploy/env.production -> .env"
else
    echo "✗ Không tìm thấy deploy/env.production"
    exit 1
fi

# Generate MEILI_MASTER_KEY
if grep -q "MEILI_MASTER_KEY=CHANGE_THIS" .env; then
    MEILI_KEY=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/MEILI_MASTER_KEY=CHANGE_THIS_TO_SECURE_RANDOM_STRING/MEILI_MASTER_KEY=$MEILI_KEY/" .env
    echo "✓ Đã generate MEILI_MASTER_KEY"
fi

# Generate JWT_SECRET
if grep -q "JWT_SECRET=CHANGE_THIS" .env; then
    JWT_SEC=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/JWT_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_SECRET=$JWT_SEC/" .env
    echo "✓ Đã generate JWT_SECRET"
fi

# Generate JWT_REFRESH_SECRET
if grep -q "JWT_REFRESH_SECRET=CHANGE_THIS" .env; then
    JWT_REFRESH=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/JWT_REFRESH_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_REFRESH_SECRET=$JWT_REFRESH/" .env
    echo "✓ Đã generate JWT_REFRESH_SECRET"
fi

# Kiểm tra các biến quan trọng
echo ""
echo "=== Kiểm tra các biến quan trọng ==="
echo "PORT: $(grep '^PORT=' .env | cut -d'=' -f2)"
echo "UID: $(grep '^UID=' .env | cut -d'=' -f2)"
echo "GID: $(grep '^GID=' .env | cut -d'=' -f2)"
echo "MEILI_MASTER_KEY: $(grep '^MEILI_MASTER_KEY=' .env | cut -d'=' -f2 | cut -c1-20)..."
echo "JWT_SECRET: $(grep '^JWT_SECRET=' .env | cut -d'=' -f2 | cut -c1-20)..."
echo "JWT_REFRESH_SECRET: $(grep '^JWT_REFRESH_SECRET=' .env | cut -d'=' -f2 | cut -c1-20)..."

echo ""
echo "⚠️  QUAN TRỌNG: Cần cập nhật Google OAuth credentials trong .env:"
echo "   - GOOGLE_CLIENT_ID"
echo "   - GOOGLE_CLIENT_SECRET"
echo ""
echo "Sử dụng: nano .env"


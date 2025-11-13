#!/bin/bash
# Script để setup server từ đầu (fresh install)
# Chạy: bash deploy/FRESH_INSTALL.sh

set -e

echo "=== Fresh Install LibreChat từ GitHub ==="

# Bước 1: Xóa thư mục cũ (nếu có)
if [ -d "/opt/librechat" ]; then
    echo "⚠️  Thư mục /opt/librechat đã tồn tại!"
    read -p "Bạn có muốn xóa và clone lại? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Hủy bỏ."
        exit 1
    fi
    echo "Đang xóa thư mục cũ..."
    rm -rf /opt/librechat
fi

# Bước 2: Clone từ GitHub
echo "Đang clone từ GitHub..."
cd /opt
git clone https://github.com/anhthinhvup/librechat.git librechat
cd librechat

# Bước 3: Setup Git workflow
echo "Đang setup Git workflow..."
bash deploy/git-setup.sh

# Bước 4: Tạo .env
echo "Đang tạo file .env..."
if [ ! -f ".env" ]; then
    cp deploy/env.production .env
    
    # Generate secrets
    MEILI_KEY=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/MEILI_MASTER_KEY=CHANGE_THIS_TO_SECURE_RANDOM_STRING/MEILI_MASTER_KEY=$MEILI_KEY/" .env
    
    JWT_SEC=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/JWT_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_SECRET=$JWT_SEC/" .env
    
    JWT_REFRESH=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s/JWT_REFRESH_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_REFRESH_SECRET=$JWT_REFRESH/" .env
    
    echo "✓ Đã tạo .env với secrets đã generate"
    echo "⚠️  Cần cập nhật Google OAuth credentials trong .env"
else
    echo "✓ File .env đã tồn tại, bỏ qua"
fi

# Bước 5: Copy docker-compose.yml
echo "Đang copy docker-compose.yml..."
cp deploy/docker-compose.production.yml docker-compose.yml

# Bước 6: Tạo librechat.yaml (nếu chưa có)
if [ ! -f "librechat.yaml" ]; then
    echo "⚠️  File librechat.yaml chưa có"
    echo "   Tạo thủ công hoặc chạy: bash deploy/create-librechat-yaml.sh"
fi

echo ""
echo "=== Hoàn thành setup ==="
echo ""
echo "Bước tiếp theo:"
echo "1. Cập nhật Google OAuth trong .env (nếu cần):"
echo "   nano .env"
echo ""
echo "2. Start containers:"
echo "   docker-compose up -d"
echo ""
echo "3. Kiểm tra logs:"
echo "   docker-compose logs -f api"
echo ""
echo "4. Khi có code mới, chỉ cần chạy:"
echo "   librechat-update"


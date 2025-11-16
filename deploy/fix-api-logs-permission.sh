#!/bin/bash

# Script sửa lỗi permission cho /app/api/logs/

set -e

cd "$(dirname "$0")/.." || exit 1

echo "🔧 Sửa lỗi permission cho /app/api/logs/..."

# 1. Tạo thư mục api/logs trên host
echo "📁 Tạo thư mục api/logs..."
mkdir -p api/logs

# 2. Set quyền theo UID/GID
echo "🔐 Set quyền cho api/logs..."
if grep -q "^UID=" .env && grep -q "^GID=" .env; then
    UID_VAL=$(grep "^UID=" .env | cut -d'=' -f2 | tr -d ' ')
    GID_VAL=$(grep "^GID=" .env | cut -d'=' -f2 | tr -d ' ')
    chown -R $UID_VAL:$GID_VAL api/logs
    chmod -R 755 api/logs
    echo "✅ Set quyền $UID_VAL:$GID_VAL"
else
    chmod -R 777 api/logs
    echo "✅ Set quyền 777 (UID/GID không tìm thấy)"
fi

# 3. Tạo hoặc cập nhật docker-compose.override.yaml
echo "📝 Tạo docker-compose.override.yaml..."
if [ -f docker-compose.override.yaml ]; then
    # Kiểm tra đã có volume api/logs chưa
    if ! grep -q "api/logs" docker-compose.override.yaml; then
        # Thêm volume vào file hiện tại
        if grep -q "volumes:" docker-compose.override.yaml; then
            sed -i '/volumes:/a\      - ./api/logs:/app/api/logs' docker-compose.override.yaml
        else
            cat >> docker-compose.override.yaml << 'EOF'
    volumes:
      - ./api/logs:/app/api/logs
EOF
        fi
    fi
else
    # Tạo file mới
    cat > docker-compose.override.yaml << 'EOF'
services:
  api:
    volumes:
      - ./api/logs:/app/api/logs
EOF
fi

# 4. Restart container
echo "🔄 Restart container..."
docker-compose down
docker-compose up -d

# 5. Đợi container start
echo "⏳ Đợi container start..."
sleep 5

# 6. Kiểm tra
echo "✅ Kiểm tra container..."
if docker ps | grep -q LibreChat; then
    echo "✅ Container đang chạy"
    echo ""
    echo "📋 Logs (20 dòng cuối):"
    docker logs LibreChat --tail 20
    echo ""
    if docker logs LibreChat --tail 20 2>&1 | grep -q "permission\|EACCES"; then
        echo "⚠️  Vẫn còn lỗi permission, kiểm tra lại quyền:"
        ls -la api/logs/
    else
        echo "✅ Không còn lỗi permission!"
    fi
else
    echo "❌ Container không chạy, xem logs:"
    docker logs LibreChat --tail 50
fi

echo ""
echo "✅ Hoàn tất!"


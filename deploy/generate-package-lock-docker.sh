#!/bin/bash
# Script để tạo package-lock.json bằng Docker container
# Chạy: bash deploy/generate-package-lock-docker.sh

cd /opt/librechat || exit 1

echo "=== Tạo package-lock.json bằng Docker ==="
echo ""

# Tạo package-lock.json ở root
echo "Đang tạo package-lock.json ở root..."
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  node:20-alpine \
  sh -c "npm install --package-lock-only && chmod 666 package-lock.json"

if [ -f "package-lock.json" ]; then
    echo "✅ Đã tạo package-lock.json"
else
    echo "❌ Không tạo được package-lock.json"
    exit 1
fi

# Kiểm tra xem có api/package.json không
if [ -f "api/package.json" ]; then
    echo ""
    echo "Đang tạo api/package-lock.json..."
    docker run --rm \
      -v $(pwd):/app \
      -w /app/api \
      node:20-alpine \
      sh -c "npm install --package-lock-only && chmod 666 package-lock.json"
    
    if [ -f "api/package-lock.json" ]; then
        echo "✅ Đã tạo api/package-lock.json"
    else
        echo "⚠️  Không tạo được api/package-lock.json (có thể không cần)"
    fi
fi

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "Bước tiếp theo:"
echo "  git add package-lock.json"
if [ -f "api/package-lock.json" ]; then
    echo "  git add api/package-lock.json"
fi
echo "  git commit -m 'Update package-lock.json for Twilio and AWS SNS dependencies'"
echo "  git push origin master"


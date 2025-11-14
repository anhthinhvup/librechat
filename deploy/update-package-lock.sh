#!/bin/bash
# Script để cập nhật package-lock.json sau khi thêm dependencies mới
# Chạy trên server: bash deploy/update-package-lock.sh

cd /opt/librechat || exit 1

echo "=== Cập nhật package-lock.json ==="
echo ""

# Install dependencies ở root để cập nhật package-lock.json
echo "Đang cập nhật package-lock.json ở root..."
npm install --package-lock-only

# Install dependencies trong api để cập nhật api/package-lock.json
echo ""
echo "Đang cập nhật api/package-lock.json..."
cd api
npm install --package-lock-only
cd ..

echo ""
echo "✅ Đã cập nhật package-lock.json"
echo ""
echo "Bước tiếp theo:"
echo "  1. Commit package-lock.json: git add package-lock.json api/package-lock.json && git commit -m 'Update package-lock.json for Twilio and AWS SNS' && git push"
echo "  2. Build lại image: docker build -f Dockerfile.multi --target api-build -t librechat-api:local ."
echo "  3. Restart: docker-compose down && docker-compose up -d"


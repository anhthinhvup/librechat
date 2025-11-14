#!/bin/bash
# Script để cấu hình git và commit package-lock.json
# Chạy: bash deploy/fix-git-and-commit-lock.sh

cd /opt/librechat || exit 1

echo "=== Cấu hình Git và commit package-lock.json ==="
echo ""

# Cấu hình git nếu chưa có
if [ -z "$(git config user.email)" ]; then
    echo "Cấu hình Git user..."
    echo "Nhập email của bạn:"
    read GIT_EMAIL
    echo "Nhập tên của bạn:"
    read GIT_NAME
    
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_NAME"
    echo "✅ Đã cấu hình Git"
fi

# Kiểm tra package-lock.json
echo ""
echo "Kiểm tra package-lock.json..."

FILES_TO_ADD=""

if [ -f "package-lock.json" ]; then
    echo "  ✓ Tìm thấy package-lock.json ở root"
    FILES_TO_ADD="package-lock.json"
fi

if [ -f "api/package-lock.json" ]; then
    echo "  ✓ Tìm thấy api/package-lock.json"
    if [ -n "$FILES_TO_ADD" ]; then
        FILES_TO_ADD="$FILES_TO_ADD api/package-lock.json"
    else
        FILES_TO_ADD="api/package-lock.json"
    fi
fi

if [ -z "$FILES_TO_ADD" ]; then
    echo "  ❌ Không tìm thấy package-lock.json nào!"
    echo "  Chạy: bash deploy/update-package-lock.sh trước"
    exit 1
fi

# Commit và push
echo ""
echo "Đang commit package-lock.json..."
git add $FILES_TO_ADD

if git diff --cached --quiet; then
    echo "  ⚠️  Không có thay đổi để commit"
else
    git commit -m "Update package-lock.json for Twilio and AWS SNS dependencies"
    echo "✅ Đã commit"
    
    echo ""
    echo "Đang push lên GitHub..."
    git push origin master
    echo "✅ Đã push"
fi

echo ""
echo "Hoàn thành!"


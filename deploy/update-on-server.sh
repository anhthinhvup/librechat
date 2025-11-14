#!/bin/bash
# Script chạy trên server để cập nhật code
# Chạy: bash update-on-server.sh

echo "=== Cập nhật code trên server ==="

cd /opt/librechat || exit

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Đang pull code mới từ GitHub (branch: $BRANCH)..."
git pull origin $BRANCH

if [ $? -ne 0 ]; then
    echo "✗ Có lỗi khi pull code!"
    exit 1
fi

echo "Đang restart Docker containers..."
docker-compose down
docker-compose up -d

echo "Đang kiểm tra logs..."
sleep 3
docker-compose ps

echo ""
echo "✓ Hoàn thành! Kiểm tra logs nếu cần:"
echo "  docker-compose logs -f api"


# Chạy: bash update-on-server.sh

echo "=== Cập nhật code trên server ==="

cd /opt/librechat || exit

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Đang pull code mới từ GitHub (branch: $BRANCH)..."
git pull origin $BRANCH

if [ $? -ne 0 ]; then
    echo "✗ Có lỗi khi pull code!"
    exit 1
fi

echo "Đang restart Docker containers..."
docker-compose down
docker-compose up -d

echo "Đang kiểm tra logs..."
sleep 3
docker-compose ps

echo ""
echo "✓ Hoàn thành! Kiểm tra logs nếu cần:"
echo "  docker-compose logs -f api"



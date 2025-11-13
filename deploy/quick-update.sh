#!/bin/bash
# Script nhanh để cập nhật code và restart
# Usage: bash quick-update.sh [branch-name]

BRANCH=${1:-$(git rev-parse --abbrev-ref HEAD)}
cd /opt/librechat || exit 1

echo "=== Quick Update LibreChat ==="
echo "Branch: $BRANCH"

# Pull code
git pull origin $BRANCH || {
    echo "✗ Lỗi khi pull code!"
    exit 1
}

# Restart containers
docker-compose down
docker-compose up -d

echo "✓ Done! Check logs: docker-compose logs -f api"


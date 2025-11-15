#!/bin/bash
# Script fix mem0 reverse proxy - loại bỏ base_url khỏi env trước khi mem0 đọc
set -e

cd /opt/librechat

echo "🔧 Fixing mem0 reverse proxy..."

# Copy code mới
docker cp mem0_server/app.py mem0-server:/app/app.py

# Tạo script Python để test và patch trong container
docker exec mem0-server python3 << 'PYEOF'
import os
import sys

# Unset OPENAI_API_BASE_URL trong process này (không ảnh hưởng container env)
# Nhưng mem0 đã import rồi, cần restart container

# Test xem mem0 có đọc base_url từ đâu
print("Testing mem0 config...")
print(f"OPENAI_API_BASE_URL in env: {os.getenv('OPENAI_API_BASE_URL')}")

# Xem code app.py hiện tại
with open('/app/app.py', 'r') as f:
    content = f.read()
    if 'base_url' in content.lower():
        print("⚠️  app.py vẫn có base_url trong code")
    else:
        print("✅ app.py không có base_url trong config dict")
PYEOF

# Sửa docker-compose để không truyền OPENAI_API_BASE_URL vào container
# Hoặc unset nó trong container
echo ""
echo "📝 Cập nhật docker-compose để không truyền OPENAI_API_BASE_URL..."
cat > docker-compose.override.yaml << 'YAMLEOF'
services:
  mem0:
    build:
      context: ./mem0_server
      dockerfile: Dockerfile
    container_name: mem0-server
    restart: always
    ports:
      - "8001:8001"
    environment:
      - MEM0_API_KEY=${MEM0_API_KEY:-}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      # Không truyền OPENAI_API_BASE_URL vào container
      # Sẽ dùng httpx patch để redirect
      - PORT=8001
    volumes:
      - ./mem0_data:/app/data
    networks:
      - default
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
YAMLEOF

# Rebuild và restart
echo "🔄 Rebuild và restart..."
docker-compose build mem0
docker rm -f mem0-server 2>/dev/null || true
docker-compose up -d mem0

sleep 10

# Test
echo ""
echo "🧪 Testing..."
curl -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_no_env",
    "messages": [
      {"role": "user", "content": "Test"},
      {"role": "assistant", "content": "OK"}
    ]
  }'

echo ""
echo "📊 Logs:"
docker-compose logs --tail=20 mem0 | grep -E "Error|Patched|HTTP Request|langhit"


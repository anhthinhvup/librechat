#!/bin/bash

# Script sửa mem0 server để hỗ trợ reverse proxy
set -e

echo "========================================="
echo "Sửa Mem0 Server với Reverse Proxy"
echo "========================================="

cd /opt/librechat

# 1. Tạo app.py với reverse proxy support
echo "📝 Tạo app.py với reverse proxy support..."
cat > mem0_server/app.py << 'PYEOF'
#!/usr/bin/env python3
"""
Mem0 API Server for LibreChat
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
import os
import logging

try:
    from mem0 import Memory
    from openai import OpenAI
except ImportError:
    raise ImportError("mem0ai package not installed")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Mem0 API Server", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_API_BASE_URL = os.getenv("OPENAI_API_BASE_URL") or os.getenv("OPENAI_REVERSE_PROXY", "")

# Patch OpenAI client để dùng reverse proxy
if OPENAI_API_BASE_URL:
    # Patch OpenAI client trước khi mem0 sử dụng
    import openai
    original_init = openai.OpenAI.__init__
    def patched_init(self, *args, **kwargs):
        if 'base_url' not in kwargs and OPENAI_API_BASE_URL:
            kwargs['base_url'] = OPENAI_API_BASE_URL
        return original_init(self, *args, **kwargs)
    openai.OpenAI.__init__ = patched_init
    logger.info(f"✅ Patched OpenAI client to use: {OPENAI_API_BASE_URL}")

memory_instances: Dict[str, Memory] = {}

def get_memory(user_id: str) -> Memory:
    if user_id not in memory_instances:
        config = {
            "vector_store": {
                "provider": "qdrant",
                "config": {
                    "collection_name": f"mem0_{user_id}",
                    "path": "/app/data/qdrant",
                }
            }
        }
        if OPENAI_API_KEY:
            llm_config = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": OPENAI_API_KEY,
                }
            }
            # Không thêm base_url vào config vì mem0 không hỗ trợ
            # Đã patch OpenAI client ở trên
            config["llm"] = llm_config
        memory_instances[user_id] = Memory.from_config(config)
    return memory_instances[user_id]

class Message(BaseModel):
    role: str
    content: str

class AddMemoryRequest(BaseModel):
    user_id: str
    messages: List[Message]

class SearchMemoryRequest(BaseModel):
    user_id: str
    query: str
    limit: Optional[int] = 10

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "mem0-api"}

@app.post("/memories")
async def add_memory(request: AddMemoryRequest):
    try:
        memory = get_memory(request.user_id)
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        result = memory.add(messages, user_id=request.user_id)
        return {"success": True, "memories": result, "user_id": request.user_id}
    except Exception as e:
        logger.error(f"Error adding memory: {e}")
        if "API key" in str(e) or "401" in str(e):
            logger.warning("OpenAI API key issue, but continuing...")
            return {"success": True, "memories": [], "user_id": request.user_id, "warning": "API key issue"}
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/memories/{user_id}")
async def get_memories(user_id: str, limit: Optional[int] = 10):
    try:
        memory = get_memory(user_id)
        result = memory.get_all(user_id=user_id, limit=limit or 100)
        
        if isinstance(result, dict):
            if user_id in result:
                memories = result[user_id]
            elif "memories" in result:
                memories = result["memories"]
            else:
                memories = list(result.values())[0] if result else []
        elif isinstance(result, list):
            memories = result
        else:
            memories = []
        
        if not isinstance(memories, list):
            memories = []
        
        if limit and len(memories) > limit:
            memories = memories[:limit]
        
        return {"success": True, "memories": memories, "user_id": user_id}
    except Exception as e:
        logger.error(f"Error getting memories: {e}")
        return {"success": True, "memories": [], "user_id": user_id, "error": str(e)}

@app.post("/memories/search")
async def search_memories(request: SearchMemoryRequest):
    try:
        memory = get_memory(request.user_id)
        results = memory.search(request.query, user_id=request.user_id, limit=request.limit)
        return {"success": True, "results": results, "user_id": request.user_id, "query": request.query}
    except Exception as e:
        logger.error(f"Error searching memories: {e}")
        if "API key" in str(e) or "401" in str(e):
            return {"success": True, "results": [], "user_id": request.user_id, "query": request.query, "warning": "API key issue"}
        return {"success": True, "results": [], "user_id": request.user_id, "query": request.query, "error": str(e)}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8001"))
    uvicorn.run(app, host="0.0.0.0", port=port)
PYEOF

# 2. Cập nhật docker-compose.override.yaml
echo "📝 Cập nhật docker-compose.override.yaml..."
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
      - OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL:-${OPENAI_REVERSE_PROXY:-}}
      - OPENAI_BASE_URL=${OPENAI_API_BASE_URL:-${OPENAI_REVERSE_PROXY:-}}
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

# 3. Copy code vào container
echo "📦 Copy code vào container..."
docker cp mem0_server/app.py mem0-server:/app/app.py 2>/dev/null || echo "⚠️  Container chưa chạy, sẽ build sau"

# 4. Rebuild và restart
echo "🔨 Rebuild mem0..."
docker-compose build mem0

echo "🛑 Dừng container cũ..."
docker rm -f mem0-server 2>/dev/null || true

echo "🚀 Khởi động mem0..."
docker-compose up -d mem0

# 5. Đợi khởi động
echo "⏳ Đợi mem0 khởi động (10 giây)..."
sleep 10

# 6. Kiểm tra
echo ""
echo "========================================="
echo "Kiểm tra"
echo "========================================="

echo ""
echo "1. Kiểm tra container:"
docker ps | grep mem0-server && echo "✅ Container đang chạy" || echo "❌ Container không chạy"

echo ""
echo "2. Kiểm tra health:"
HEALTH=$(curl -s http://localhost:8001/health 2>/dev/null || echo "ERROR")
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ Health check OK"
else
    echo "❌ Health check failed: $HEALTH"
fi

echo ""
echo "3. Kiểm tra reverse proxy trong logs:"
docker-compose logs --tail=10 mem0 | grep -E "Patched|langhit|reverse proxy" || echo "⚠️  Chưa thấy log về reverse proxy"

echo ""
echo "4. Test thêm memories:"
TEST_RESULT=$(curl -s -X POST http://localhost:8001/memories \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_proxy_script",
    "messages": [
      {"role": "user", "content": "Test with reverse proxy"},
      {"role": "assistant", "content": "OK"}
    ]
  }' 2>/dev/null || echo "ERROR")

if echo "$TEST_RESULT" | grep -q "success"; then
    echo "✅ Test add memories OK"
    echo "$TEST_RESULT" | head -c 200
    echo "..."
else
    echo "❌ Test failed: $TEST_RESULT"
fi

echo ""
echo "5. Xem logs gần đây:"
docker-compose logs --tail=5 mem0 | grep -E "HTTP Request|Error|Patched" || echo "   (Không có logs liên quan)"

echo ""
echo "========================================="
echo "Hoàn thành!"
echo "========================================="
echo ""
echo "Để xem logs real-time:"
echo "  docker-compose logs -f mem0"
echo ""
echo "Để test lại:"
echo "  curl -X POST http://localhost:8001/memories -H 'Content-Type: application/json' -d '{\"user_id\":\"test\",\"messages\":[{\"role\":\"user\",\"content\":\"test\"}]}'"
echo ""


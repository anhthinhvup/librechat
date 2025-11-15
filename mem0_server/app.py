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

import openai
import httpx
import json
import requests
from typing import Dict, Any, List

# Cấu hình reverse proxy
# Lưu giá trị TRƯỚC KHI unset để mem0 không đọc
OPENAI_API_BASE_URL = os.getenv("OPENAI_API_BASE_URL") or os.getenv("OPENAI_REVERSE_PROXY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

# Unset env để mem0 không đọc base_url
if OPENAI_API_BASE_URL:
    if "OPENAI_API_BASE_URL" in os.environ:
        del os.environ["OPENAI_API_BASE_URL"]
    if "OPENAI_BASE_URL" in os.environ:
        del os.environ["OPENAI_BASE_URL"]
    # Giữ lại OPENAI_REVERSE_PROXY để code đọc được
    if "OPENAI_REVERSE_PROXY" not in os.environ and OPENAI_API_BASE_URL:
        os.environ["OPENAI_REVERSE_PROXY"] = OPENAI_API_BASE_URL

# Custom LLM Provider dùng requests/httpx trực tiếp với reverse proxy
class CustomOpenAIProvider:
    """Custom LLM provider dùng requests/httpx trực tiếp, không dùng thư viện OpenAI"""
    
    def __init__(self, api_key: str, base_url: str, model: str = "gpt-4o-mini"):
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.session = requests.Session()
    
    def chat_completions(self, messages: List[Dict[str, str]], **kwargs) -> Dict[str, Any]:
        """Gọi chat/completions API"""
        url = f"{self.base_url}/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }
        payload = {
            "model": self.model,
            "messages": messages,
            **kwargs
        }
        response = self.session.post(url, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        return response.json()
    
    def __call__(self, messages: List[Dict[str, str]], **kwargs) -> str:
        """Wrapper để tương thích với mem0"""
        result = self.chat_completions(messages, **kwargs)
        return result["choices"][0]["message"]["content"]

try:
    from mem0 import Memory
except ImportError:
    raise ImportError("mem0ai package not installed")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Dùng API chính thức của OpenAI - không cần patch

app = FastAPI(title="Mem0 API Server", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
            },
            # Dùng local embedding model - KHÔNG tốn quota, KHÔNG cần OpenAI
            "embedder": {
                "provider": "sentence-transformers",
                "config": {
                    "model": "all-MiniLM-L6-v2",  # Model nhẹ, miễn phí
                    # Hoặc dùng model khác: "paraphrase-MiniLM-L6-v2", "all-mpnet-base-v2"
                }
            }
        }
        if OPENAI_API_KEY:
            # Dùng OpenAI provider - mem0 sẽ tự tạo client
            # Không thêm base_url vào config để tránh lỗi
            llm_config = {
                "model": "gpt-4o-mini",
                "api_key": OPENAI_API_KEY,
            }
            # Nếu có reverse proxy, sẽ patch client sau
            config["llm"] = {
                "provider": "openai",
                "config": llm_config
            }
        memory = Memory.from_config(config)
        
        # Patch client sau khi Memory được tạo để dùng reverse proxy
        if OPENAI_API_KEY and OPENAI_API_BASE_URL:
            try:
                # Tìm và patch OpenAI client trong memory
                if hasattr(memory, 'llm') and memory.llm:
                    # Tìm client trong llm object
                    if hasattr(memory.llm, 'client'):
                        memory.llm.client.base_url = OPENAI_API_BASE_URL
                        logger.info(f"✅ Patched llm.client.base_url for user {user_id}")
                    elif hasattr(memory.llm, '_client'):
                        memory.llm._client.base_url = OPENAI_API_BASE_URL
                        logger.info(f"✅ Patched llm._client.base_url for user {user_id}")
                    # Hoặc tìm trong config
                    elif hasattr(memory.llm, 'config') and memory.llm.config:
                        if hasattr(memory.llm.config, 'client'):
                            memory.llm.config.client.base_url = OPENAI_API_BASE_URL
                            logger.info(f"✅ Patched llm.config.client.base_url for user {user_id}")
            except Exception as e:
                logger.debug(f"Could not patch client: {e}")
        
        memory_instances[user_id] = memory
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
        logger.error(f"Error: {e}")
        if "API key" in str(e) or "401" in str(e):
            return {"success": True, "memories": [], "user_id": request.user_id, "warning": "API key issue"}
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/memories/{user_id}")
async def get_memories(user_id: str, limit: Optional[int] = 10):
    try:
        memory = get_memory(user_id)
        result = memory.get_all(user_id=user_id, limit=limit or 100)
        if isinstance(result, dict):
            memories = result.get(user_id, result.get("memories", list(result.values())[0] if result else []))
        else:
            memories = result if isinstance(result, list) else []
        if limit and len(memories) > limit:
            memories = memories[:limit]
        return {"success": True, "memories": memories, "user_id": user_id}
    except Exception as e:
        logger.error(f"Error: {e}")
        return {"success": True, "memories": [], "user_id": user_id}

@app.post("/memories/search")
async def search_memories(request: SearchMemoryRequest):
    try:
        memory = get_memory(request.user_id)
        results = memory.search(request.query, user_id=request.user_id, limit=request.limit)
        return {"success": True, "results": results, "user_id": request.user_id, "query": request.query}
    except Exception as e:
        logger.error(f"Error: {e}")
        return {"success": True, "results": [], "user_id": request.user_id, "query": request.query}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8001")))

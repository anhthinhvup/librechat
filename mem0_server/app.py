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
    import openai
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

# Patch để dùng reverse proxy
if OPENAI_API_BASE_URL:
    # Patch OpenAI client
    original_openai_init = openai.OpenAI.__init__
    def patched_openai_init(self, *args, **kwargs):
        if "base_url" not in kwargs and OPENAI_API_BASE_URL:
            kwargs["base_url"] = OPENAI_API_BASE_URL
        return original_openai_init(self, *args, **kwargs)
    openai.OpenAI.__init__ = patched_openai_init
    
    # Patch mem0's OpenAIConfig để loại bỏ base_url
    try:
        from mem0.config import OpenAIConfig
        original_config_init = OpenAIConfig.__init__
        def patched_config_init(self, *args, **kwargs):
            # Loại bỏ base_url khỏi kwargs
            kwargs.pop("base_url", None)
            return original_config_init(self, *args, **kwargs)
        OpenAIConfig.__init__ = patched_config_init
    except (ImportError, AttributeError):
        pass
    
    logger.info(f"✅ Patched to use reverse proxy: {OPENAI_API_BASE_URL}")

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
            config["llm"] = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": OPENAI_API_KEY,
                }
            }
        memory = Memory.from_config(config)
        
        # Patch client sau khi Memory được tạo
        if OPENAI_API_BASE_URL and hasattr(memory, 'config') and memory.config:
            llm_config = memory.config.get('llm', {})
            if llm_config and hasattr(llm_config, 'client'):
                try:
                    llm_config.client.base_url = OPENAI_API_BASE_URL
                    logger.debug(f"Set base_url for user {user_id}")
                except:
                    pass
        
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

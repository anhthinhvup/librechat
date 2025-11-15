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

# Patch TRƯỚC KHI import Memory
# Lưu base_url nhưng không set vào env để mem0 không đọc
OPENAI_API_BASE_URL = os.getenv("OPENAI_API_BASE_URL") or os.getenv("OPENAI_REVERSE_PROXY", "")
# Unset trong process này để mem0 không đọc
if OPENAI_API_BASE_URL:
    if "OPENAI_API_BASE_URL" in os.environ:
        del os.environ["OPENAI_API_BASE_URL"]
    if "OPENAI_REVERSE_PROXY" in os.environ:
        del os.environ["OPENAI_REVERSE_PROXY"]

# Patch httpx client để dùng reverse proxy
if OPENAI_API_BASE_URL:
    # Patch httpx để redirect requests - patch cả sync và async
    original_httpx_request = httpx.Client.request
    original_httpx_async_request = httpx.AsyncClient.request
    original_httpx_send = httpx.Client.send
    original_httpx_async_send = httpx.AsyncClient.send
    
    def patched_httpx_request(self, method, url, **kwargs):
        if isinstance(url, str) and "api.openai.com" in url:
            url = url.replace("https://api.openai.com", OPENAI_API_BASE_URL.rstrip("/"))
        return original_httpx_request(self, method, url, **kwargs)
    
    async def patched_httpx_async_request(self, method, url, **kwargs):
        if isinstance(url, str) and "api.openai.com" in url:
            url = url.replace("https://api.openai.com", OPENAI_API_BASE_URL.rstrip("/"))
        return await original_httpx_async_request(self, method, url, **kwargs)
    
    def patched_httpx_send(self, request, **kwargs):
        if hasattr(request, 'url'):
            url_str = str(request.url)
            if "api.openai.com" in url_str:
                new_url = url_str.replace("https://api.openai.com", OPENAI_API_BASE_URL.rstrip("/"))
                from httpx import URL
                request.url = URL(new_url)
        return original_httpx_send(self, request, **kwargs)
    
    async def patched_httpx_async_send(self, request, **kwargs):
        if hasattr(request, 'url'):
            url_str = str(request.url)
            if "api.openai.com" in url_str:
                new_url = url_str.replace("https://api.openai.com", OPENAI_API_BASE_URL.rstrip("/"))
                from httpx import URL
                request.url = URL(new_url)
        return await original_httpx_async_send(self, request, **kwargs)
    
    httpx.Client.request = patched_httpx_request
    httpx.AsyncClient.request = patched_httpx_async_request
    httpx.Client.send = patched_httpx_send
    httpx.AsyncClient.send = patched_httpx_async_send
    
    # Patch OpenAI client
    original_openai_init = openai.OpenAI.__init__
    def patched_openai_init(self, *args, **kwargs):
        if "base_url" not in kwargs and OPENAI_API_BASE_URL:
            kwargs["base_url"] = OPENAI_API_BASE_URL
        return original_openai_init(self, *args, **kwargs)
    openai.OpenAI.__init__ = patched_openai_init

try:
    from mem0 import Memory
    # Patch OpenAIConfig TRƯỚC KHI Memory được tạo
    if OPENAI_API_BASE_URL:
        try:
            from mem0.config import OpenAIConfig
            original_config_init = OpenAIConfig.__init__
            def patched_config_init(self, *args, **kwargs):
                # Loại bỏ base_url và các biến liên quan
                kwargs.pop("base_url", None)
                kwargs.pop("api_base", None)
                kwargs.pop("api_base_url", None)
                result = original_config_init(self, *args, **kwargs)
                # Set base_url cho client SAU KHI init
                if hasattr(self, "client") and self.client:
                    self.client.base_url = OPENAI_API_BASE_URL
                elif hasattr(self, "_client") and self._client:
                    self._client.base_url = OPENAI_API_BASE_URL
                return result
            OpenAIConfig.__init__ = patched_config_init
        except Exception as e:
            import logging
            logging.getLogger(__name__).debug(f"Could not patch OpenAIConfig: {e}")
except ImportError:
    raise ImportError("mem0ai package not installed")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if OPENAI_API_BASE_URL:
    logger.info(f"✅ Patched httpx and OpenAI to use reverse proxy: {OPENAI_API_BASE_URL}")

app = FastAPI(title="Mem0 API Server", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

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
            llm_config_dict = {
                "model": "gpt-4o-mini",
                "api_key": OPENAI_API_KEY,
            }
            # KHÔNG thêm base_url vào config dict
            # mem0 sẽ tự tạo client, sau đó chúng ta patch
            config["llm"] = {
                "provider": "openai",
                "config": llm_config_dict
            }
        memory = Memory.from_config(config)
        
        # Patch client sau khi Memory được tạo
        if OPENAI_API_BASE_URL:
            try:
                # Tìm client trong memory object
                # Thử nhiều cách để tìm client
                client = None
                if hasattr(memory, 'llm') and memory.llm:
                    if hasattr(memory.llm, 'client'):
                        client = memory.llm.client
                    elif hasattr(memory.llm, '_client'):
                        client = memory.llm._client
                elif hasattr(memory, 'config') and memory.config:
                    llm_config = memory.config.get('llm')
                    if llm_config:
                        if hasattr(llm_config, 'client'):
                            client = llm_config.client
                        elif hasattr(llm_config, '_client'):
                            client = llm_config._client
                
                if client:
                    client.base_url = OPENAI_API_BASE_URL
                    logger.debug(f"✅ Set base_url for user {user_id}")
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

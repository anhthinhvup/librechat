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

# Cấu hình reverse proxy (langhit.com)
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_REVERSE_PROXY = os.getenv("OPENAI_REVERSE_PROXY", "") or os.getenv("OPENAI_API_BASE_URL", "")
REVERSE_PROXY_URL = OPENAI_REVERSE_PROXY.rstrip("/") if OPENAI_REVERSE_PROXY else None

# Patch httpx TRƯỚC KHI import mem0 để redirect tất cả requests
if REVERSE_PROXY_URL:
    import httpx
    from httpx import URL
    
    # Patch httpx._client.BaseClient._prepare_request - level thấp nhất
    try:
        from httpx._client import BaseClient
        original_prepare_request = BaseClient._prepare_request
        
        def patched_prepare_request(self, request):
            if hasattr(request, 'url'):
                url_str = str(request.url)
                if "api.openai.com" in url_str:
                    new_url = url_str.replace("https://api.openai.com", REVERSE_PROXY_URL)
                    request.url = URL(new_url)
            return original_prepare_request(self, request)
        
        BaseClient._prepare_request = patched_prepare_request
    except:
        pass
    
    # Patch httpx.Client và AsyncClient
    original_client_init = httpx.Client.__init__
    original_async_client_init = httpx.AsyncClient.__init__
    
    def patched_client_init(self, *args, **kwargs):
        if "base_url" not in kwargs:
            kwargs["base_url"] = REVERSE_PROXY_URL
        return original_client_init(self, *args, **kwargs)
    
    async def patched_async_client_init(self, *args, **kwargs):
        if "base_url" not in kwargs:
            kwargs["base_url"] = REVERSE_PROXY_URL
        return original_async_client_init(self, *args, **kwargs)
    
    httpx.Client.__init__ = patched_client_init
    httpx.AsyncClient.__init__ = patched_async_client_init
    
    # Patch httpx transport
    try:
        from httpx._transports.default import HTTPTransport, AsyncHTTPTransport
        
        original_handle_request = HTTPTransport.handle_request
        original_handle_async_request = AsyncHTTPTransport.handle_async_request
        
        def patched_handle_request(self, request):
            if hasattr(request, 'url') and "api.openai.com" in str(request.url):
                new_url = str(request.url).replace("https://api.openai.com", REVERSE_PROXY_URL)
                request.url = URL(new_url)
            return original_handle_request(self, request)
        
        async def patched_handle_async_request(self, request):
            if hasattr(request, 'url') and "api.openai.com" in str(request.url):
                new_url = str(request.url).replace("https://api.openai.com", REVERSE_PROXY_URL)
                request.url = URL(new_url)
            return await original_handle_async_request(self, request)
        
        HTTPTransport.handle_request = patched_handle_request
        AsyncHTTPTransport.handle_async_request = patched_handle_async_request
    except:
        pass
    
    # Patch OpenAI client
    import openai
    original_openai_init = openai.OpenAI.__init__
    
    def patched_openai_init(self, *args, **kwargs):
        if "base_url" not in kwargs:
            kwargs["base_url"] = REVERSE_PROXY_URL
        return original_openai_init(self, *args, **kwargs)
    
    openai.OpenAI.__init__ = patched_openai_init

try:
    from mem0 import Memory
    # Patch OpenAIConfig TRƯỚC KHI Memory được tạo để loại bỏ base_url
    if REVERSE_PROXY_URL:
        try:
            from mem0.config import OpenAIConfig
            original_config_init = OpenAIConfig.__init__
            
            def patched_config_init(self, *args, **kwargs):
                # Loại bỏ base_url từ mọi nơi
                kwargs.pop("base_url", None)
                kwargs.pop("api_base", None)
                kwargs.pop("api_base_url", None)
                # Loại bỏ từ args
                new_args = []
                for arg in args:
                    if isinstance(arg, dict):
                        arg = {k: v for k, v in arg.items() if k not in ["base_url", "api_base", "api_base_url"]}
                        if "config" in arg and isinstance(arg["config"], dict):
                            arg["config"] = {k: v for k, v in arg["config"].items() if k not in ["base_url", "api_base", "api_base_url"]}
                    new_args.append(arg)
                args = tuple(new_args)
                # Gọi original
                result = original_config_init(self, *args, **kwargs)
                # Set base_url cho client SAU KHI init
                if hasattr(self, "client") and self.client:
                    self.client.base_url = REVERSE_PROXY_URL
                elif hasattr(self, "_client") and self._client:
                    self._client.base_url = REVERSE_PROXY_URL
                return result
            
            OpenAIConfig.__init__ = patched_config_init
        except Exception as e:
            import logging
            logging.getLogger(__name__).debug(f"Could not patch OpenAIConfig: {e}")
except ImportError:
    raise ImportError("mem0ai package not installed")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Custom LLM Provider dùng requests/httpx trực tiếp với DeepSeek API (miễn phí)
class CustomOpenAIProvider:
    """Custom LLM provider dùng HTTP request trực tiếp, hỗ trợ DeepSeek và OpenAI"""
    
    def __init__(self, api_key: str, base_url: str, model: str = "deepseek-chat"):
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.session = requests.Session()
        logger.info(f"✅ Custom LLM Provider initialized: {self.base_url} (model: {self.model})")
    
    def generate(self, messages: List[Dict[str, str]], **kwargs) -> str:
        """Generate response từ messages - interface cho mem0"""
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
        try:
            response = self.session.post(url, headers=headers, json=payload, timeout=60)
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
        except Exception as e:
            logger.error(f"Custom LLM Provider error: {e}")
            raise
    
    def __call__(self, messages: List[Dict[str, str]], **kwargs) -> str:
        """Wrapper để tương thích với mem0"""
        return self.generate(messages, **kwargs)

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
            # Dùng local embedding model - KHÔNG tốn quota
            # Mem0 hỗ trợ sentence-transformers
            "embedder": {
                "provider": "sentence-transformers",
                "config": {
                    "model": "all-MiniLM-L6-v2",  # Model nhẹ, miễn phí
                    # Hoặc dùng model khác: "paraphrase-MiniLM-L6-v2", "all-mpnet-base-v2"
                }
            }
        }
        if OPENAI_API_KEY:
            # Dùng OpenAI provider - httpx đã được patch để redirect sang reverse proxy
            config["llm"] = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": OPENAI_API_KEY,
                }
            }
            if REVERSE_PROXY_URL:
                logger.info(f"✅ Using OpenAI provider with reverse proxy: {REVERSE_PROXY_URL} for user {user_id}")
            else:
                logger.info(f"✅ Using OpenAI provider (direct) for user {user_id}")
        memory = Memory.from_config(config)
        
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

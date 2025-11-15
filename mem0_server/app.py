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

# Cấu hình custom provider cho mem0
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
CUSTOM_LLM_ENDPOINT = os.getenv("CUSTOM_LLM_ENDPOINT", "") or os.getenv("OPENAI_REVERSE_PROXY", "")
CUSTOM_LLM_API_KEY = os.getenv("CUSTOM_LLM_API_KEY", "") or OPENAI_API_KEY
USE_CUSTOM_PROVIDER = os.getenv("MEM0_LLM_PROVIDER", "").lower() == "custom" or bool(CUSTOM_LLM_ENDPOINT)

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
        if USE_CUSTOM_PROVIDER and CUSTOM_LLM_ENDPOINT:
            # Mem0 có thể không hỗ trợ "custom" provider trực tiếp
            # Thử dùng OpenAI provider nhưng patch client sau
            config["llm"] = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": CUSTOM_LLM_API_KEY,
                }
            }
            logger.info(f"✅ Will use custom endpoint: {CUSTOM_LLM_ENDPOINT}")
        elif OPENAI_API_KEY:
            # Fallback: dùng OpenAI provider
            config["llm"] = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": OPENAI_API_KEY,
                }
            }
        memory = Memory.from_config(config)
        
        # Patch client sau khi Memory được tạo để dùng custom endpoint
        if USE_CUSTOM_PROVIDER and CUSTOM_LLM_ENDPOINT:
            try:
                # Tìm và patch OpenAI client trong memory
                if hasattr(memory, 'llm') and memory.llm:
                    # Thử nhiều cách để tìm client
                    if hasattr(memory.llm, 'client'):
                        memory.llm.client.base_url = CUSTOM_LLM_ENDPOINT.rstrip("/")
                        logger.info(f"✅ Patched llm.client.base_url to {CUSTOM_LLM_ENDPOINT} for user {user_id}")
                    elif hasattr(memory.llm, '_client'):
                        memory.llm._client.base_url = CUSTOM_LLM_ENDPOINT.rstrip("/")
                        logger.info(f"✅ Patched llm._client.base_url to {CUSTOM_LLM_ENDPOINT} for user {user_id}")
                    # Hoặc tìm trong config
                    elif hasattr(memory.llm, 'config') and memory.llm.config:
                        if hasattr(memory.llm.config, 'client'):
                            memory.llm.config.client.base_url = CUSTOM_LLM_ENDPOINT.rstrip("/")
                            logger.info(f"✅ Patched llm.config.client.base_url to {CUSTOM_LLM_ENDPOINT} for user {user_id}")
                    # Hoặc tìm bằng cách inspect
                    else:
                        import inspect
                        for attr_name in dir(memory.llm):
                            if 'client' in attr_name.lower() and not attr_name.startswith('__'):
                                try:
                                    attr = getattr(memory.llm, attr_name)
                                    if hasattr(attr, 'base_url'):
                                        attr.base_url = CUSTOM_LLM_ENDPOINT.rstrip("/")
                                        logger.info(f"✅ Patched llm.{attr_name}.base_url to {CUSTOM_LLM_ENDPOINT} for user {user_id}")
                                        break
                                except:
                                    pass
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

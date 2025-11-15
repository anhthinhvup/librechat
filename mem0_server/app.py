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

# Dùng DeepSeek API (miễn phí, OpenAI-compatible) với HTTP request trực tiếp
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "") or os.getenv("OPENAI_API_KEY", "")
DEEPSEEK_API_BASE_URL = os.getenv("DEEPSEEK_API_BASE_URL", "https://api.deepseek.com")
USE_DEEPSEEK = os.getenv("USE_DEEPSEEK", "true").lower() == "true"

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
        if USE_DEEPSEEK and DEEPSEEK_API_KEY:
            # Dùng DeepSeek API (miễn phí, OpenAI-compatible)
            custom_provider = CustomOpenAIProvider(
                api_key=DEEPSEEK_API_KEY,
                base_url=DEEPSEEK_API_BASE_URL,
                model="deepseek-chat"  # DeepSeek model
            )
            config["llm"] = custom_provider
            logger.info(f"✅ Using DeepSeek API (free) for user {user_id}")
        elif OPENAI_API_KEY:
            # Fallback: dùng OpenAI API
            custom_provider = CustomOpenAIProvider(
                api_key=OPENAI_API_KEY,
                base_url="https://api.openai.com/v1",
                model="gpt-4o-mini"
            )
            config["llm"] = custom_provider
            logger.info(f"✅ Using OpenAI API for user {user_id}")
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

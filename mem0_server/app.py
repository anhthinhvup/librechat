#!/usr/bin/env python3
"""
Mem0 API Server for LibreChat
Provides memory management API endpoints
"""

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import os
import logging

try:
    from mem0 import Memory
except ImportError:
    raise ImportError("mem0ai package not installed. Run: pip install mem0ai")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Mem0 API Server", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Mem0
MEM0_API_KEY = os.getenv("MEM0_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

if not OPENAI_API_KEY:
    logger.warning("OPENAI_API_KEY not set. Mem0 may not work properly.")

# Initialize memory instances per user (in-memory cache)
memory_instances: Dict[str, Memory] = {}

def get_memory(user_id: str) -> Memory:
    """Get or create memory instance for user"""
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
        memory_instances[user_id] = Memory.from_config(config)
    return memory_instances[user_id]


# Request/Response models
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


class DeleteMemoryRequest(BaseModel):
    user_id: str
    memory_id: Optional[str] = None


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "mem0-api"}


@app.post("/memories")
async def add_memory(request: AddMemoryRequest):
    """Add memories from conversation messages"""
    try:
        memory = get_memory(request.user_id)
        
        # Convert messages to mem0 format
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        
        # Add memories
        result = memory.add(messages)
        
        return {
            "success": True,
            "memories": result,
            "user_id": request.user_id
        }
    except Exception as e:
        logger.error(f"Error adding memory: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/memories/{user_id}")
async def get_memories(user_id: str, limit: Optional[int] = 10):
    """Get all memories for a user"""
    try:
        memory = get_memory(user_id)
        memories = memory.search_all(limit=limit)
        
        return {
            "success": True,
            "memories": memories,
            "user_id": user_id
        }
    except Exception as e:
        logger.error(f"Error getting memories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/memories/search")
async def search_memories(request: SearchMemoryRequest):
    """Search memories for a user"""
    try:
        memory = get_memory(request.user_id)
        results = memory.search(request.query, limit=request.limit)
        
        return {
            "success": True,
            "results": results,
            "user_id": request.user_id,
            "query": request.query
        }
    except Exception as e:
        logger.error(f"Error searching memories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/memories")
async def delete_memory(request: DeleteMemoryRequest):
    """Delete memories for a user"""
    try:
        memory = get_memory(request.user_id)
        
        if request.memory_id:
            # Delete specific memory
            result = memory.delete(ids=[request.memory_id])
        else:
            # Delete all memories
            result = memory.delete_all()
        
        return {
            "success": True,
            "deleted": result,
            "user_id": request.user_id
        }
    except Exception as e:
        logger.error(f"Error deleting memory: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8001"))
    uvicorn.run(app, host="0.0.0.0", port=port)


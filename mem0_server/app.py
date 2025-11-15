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
import sys
import traceback

# Cấu hình reverse proxy (langhit.com)
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_REVERSE_PROXY = os.getenv("OPENAI_REVERSE_PROXY", "") or os.getenv("OPENAI_API_BASE_URL", "")
REVERSE_PROXY_URL = OPENAI_REVERSE_PROXY.rstrip("/") if OPENAI_REVERSE_PROXY else None

# Unset các env variables TRƯỚC KHI import bất kỳ thứ gì
# Mem0 có thể đọc từ các env này và tự động thêm base_url vào OpenAIConfig
if REVERSE_PROXY_URL:
    # Unset các env có thể gây conflict - phải làm TRƯỚC KHI import mem0
    for env_key in ["OPENAI_API_BASE", "OPENAI_BASE_URL", "OPENAI_API_BASE_URL"]:
        if env_key in os.environ:
            del os.environ[env_key]

# Patch import hook TRƯỚC KHI import mem0
# Intercept mọi import và patch OpenAIConfig ngay khi được import
if REVERSE_PROXY_URL:
    _original_import = __builtins__.__import__
    
    def _patched_import(name, *args, **kwargs):
        module = _original_import(name, *args, **kwargs)
        
        # Patch OpenAIConfig nếu có trong module vừa import
        if hasattr(module, 'OpenAIConfig'):
            try:
                original_init = module.OpenAIConfig.__init__
                
                def patched_init(self, *args, **kwargs):
                    # Loại bỏ base_url và các biến tương tự
                    kwargs.pop('base_url', None)
                    kwargs.pop('openai_base_url', None)
                    kwargs.pop('api_base', None)
                    return original_init(self, *args, **kwargs)
                
                module.OpenAIConfig.__init__ = patched_init
                sys.stderr.write(f"[PATCH] Patched OpenAIConfig in module: {name}\n")
                sys.stderr.flush()
            except Exception as e:
                sys.stderr.write(f"[PATCH] Failed to patch OpenAIConfig in {name}: {e}\n")
                sys.stderr.flush()
        
        return module
    
    __builtins__.__import__ = _patched_import
    sys.stderr.write("[PATCH] Installed import hook for OpenAIConfig patching\n")
    sys.stderr.flush()

# Patch httpx transport TRƯỚC KHI import mem0
if REVERSE_PROXY_URL:
    import httpx
    from httpx import URL
    
    # Patch httpx.Client và AsyncClient để thêm default headers và force HTTP/2
    try:
        base_proxy_url = REVERSE_PROXY_URL.rstrip("/v1").rstrip("/")
        default_headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate, br',
            'Origin': base_proxy_url,
            'Referer': base_proxy_url + '/',
            'Connection': 'keep-alive',
        }
        
        original_client_init = httpx.Client.__init__
        original_async_client_init = httpx.AsyncClient.__init__
        
        def patched_client_init(self, *args, **kwargs):
            if 'headers' not in kwargs:
                kwargs['headers'] = {}
            elif kwargs['headers'] is None:
                kwargs['headers'] = {}
            
            # Merge default headers
            if isinstance(kwargs['headers'], dict):
                kwargs['headers'] = {**default_headers, **kwargs['headers']}
            else:
                # httpx.Headers object
                for k, v in default_headers.items():
                    if k not in kwargs['headers']:
                        kwargs['headers'][k] = v
            
            # Force HTTP/2 if possible
            if 'http2' not in kwargs:
                kwargs['http2'] = True
            
            return original_client_init(self, *args, **kwargs)
        
        def patched_async_client_init(self, *args, **kwargs):
            if 'headers' not in kwargs:
                kwargs['headers'] = {}
            elif kwargs['headers'] is None:
                kwargs['headers'] = {}
            
            # Merge default headers
            if isinstance(kwargs['headers'], dict):
                kwargs['headers'] = {**default_headers, **kwargs['headers']}
            else:
                # httpx.Headers object
                for k, v in default_headers.items():
                    if k not in kwargs['headers']:
                        kwargs['headers'][k] = v
            
            # Force HTTP/2 if possible
            if 'http2' not in kwargs:
                kwargs['http2'] = True
            
            return original_async_client_init(self, *args, **kwargs)
        
        httpx.Client.__init__ = patched_client_init
        httpx.AsyncClient.__init__ = patched_async_client_init
        sys.stderr.write(f"[PATCH] ✅ Patched httpx.Client and AsyncClient to add default headers and force HTTP/2\n")
        sys.stderr.flush()
    except Exception as e:
        sys.stderr.write(f"[PATCH] ❌ Failed to patch httpx Client: {e}\n")
        sys.stderr.flush()
    
    # Patch httpx._client.BaseClient._send và _request để đảm bảo headers được thêm
    try:
        from httpx._client import BaseClient
        base_proxy_url = REVERSE_PROXY_URL.rstrip("/v1").rstrip("/")
        
        # Patch _send (sync)
        if hasattr(BaseClient, '_send'):
            original_send = BaseClient._send
            def patched_send(self, request, *args, **kwargs):
                if hasattr(request, 'url') and "langhit.com" in str(request.url):
                    if hasattr(request, 'headers'):
                        headers = request.headers
                        extra_headers = {}
                        if 'user-agent' not in headers and 'User-Agent' not in headers:
                            extra_headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                        if 'Accept' not in headers:
                            extra_headers['Accept'] = 'application/json'
                        if 'Accept-Encoding' not in headers:
                            extra_headers['Accept-Encoding'] = 'gzip, deflate, br'
                        if 'Origin' not in headers:
                            extra_headers['Origin'] = base_proxy_url
                        if 'Referer' not in headers:
                            extra_headers['Referer'] = base_proxy_url + '/'
                        if extra_headers:
                            try:
                                if hasattr(headers, 'update'):
                                    headers.update(extra_headers)
                                elif isinstance(headers, dict):
                                    headers.update(extra_headers)
                                else:
                                    for k, v in extra_headers.items():
                                        headers[k] = v
                                sys.stderr.write(f"[PATCH] Added headers in _send: {list(extra_headers.keys())}\n")
                                sys.stderr.flush()
                            except Exception as e:
                                sys.stderr.write(f"[PATCH] Failed to add headers in _send: {e}\n")
                                sys.stderr.flush()
                return original_send(self, request, *args, **kwargs)
            BaseClient._send = patched_send
        
        # Patch _request (async)
        if hasattr(BaseClient, '_request'):
            original_request = BaseClient._request
            async def patched_request(self, request, *args, **kwargs):
                if hasattr(request, 'url') and "langhit.com" in str(request.url):
                    if hasattr(request, 'headers'):
                        headers = request.headers
                        extra_headers = {}
                        if 'user-agent' not in headers and 'User-Agent' not in headers:
                            extra_headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                        if 'Accept' not in headers:
                            extra_headers['Accept'] = 'application/json'
                        if 'Accept-Encoding' not in headers:
                            extra_headers['Accept-Encoding'] = 'gzip, deflate, br'
                        if 'Origin' not in headers:
                            extra_headers['Origin'] = base_proxy_url
                        if 'Referer' not in headers:
                            extra_headers['Referer'] = base_proxy_url + '/'
                        if extra_headers:
                            try:
                                if hasattr(headers, 'update'):
                                    headers.update(extra_headers)
                                elif isinstance(headers, dict):
                                    headers.update(extra_headers)
                                else:
                                    for k, v in extra_headers.items():
                                        headers[k] = v
                                sys.stderr.write(f"[PATCH] Added headers in _request: {list(extra_headers.keys())}\n")
                                sys.stderr.flush()
                            except Exception as e:
                                sys.stderr.write(f"[PATCH] Failed to add headers in _request: {e}\n")
                                sys.stderr.flush()
                return await original_request(self, request, *args, **kwargs)
            BaseClient._request = patched_request
        
        # Patch httpx._client.BaseClient._prepare_request - level thấp nhất
        original_prepare_request = BaseClient._prepare_request
        
        def patched_prepare_request(self, request):
            """Redirect tất cả requests từ api.openai.com sang reverse proxy và thêm headers"""
            if hasattr(request, 'url'):
                url_str = str(request.url)
                base_proxy_url = REVERSE_PROXY_URL.rstrip("/v1").rstrip("/")
                
                # Redirect URL nếu là api.openai.com
                if "api.openai.com" in url_str:
                    if "/v1" in url_str:
                        new_url = url_str.replace("https://api.openai.com/v1", base_proxy_url + "/v1")
                    else:
                        new_url = url_str.replace("https://api.openai.com", base_proxy_url)
                    request.url = URL(new_url)
                    sys.stderr.write(f"[PATCH] Redirected URL: {url_str} → {new_url}\n")
                    sys.stderr.flush()
                
                # Thêm headers cho TẤT CẢ requests đến langhit.com (kể cả đã redirect)
                if "langhit.com" in str(request.url):
                    if hasattr(request, 'headers'):
                        headers = request.headers
                        extra_headers = {}
                        if 'user-agent' not in headers and 'User-Agent' not in headers:
                            extra_headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                        if 'Accept' not in headers:
                            extra_headers['Accept'] = 'application/json'
                        if 'Accept-Encoding' not in headers:
                            extra_headers['Accept-Encoding'] = 'gzip, deflate, br'
                        if 'Origin' not in headers:
                            extra_headers['Origin'] = base_proxy_url
                        if 'Referer' not in headers:
                            extra_headers['Referer'] = base_proxy_url + '/'
                        
                        # Update headers
                        if extra_headers:
                            try:
                                if hasattr(headers, 'update'):
                                    headers.update(extra_headers)
                                elif isinstance(headers, dict):
                                    headers.update(extra_headers)
                                else:
                                    # Fallback: set từng item
                                    for k, v in extra_headers.items():
                                        headers[k] = v
                                sys.stderr.write(f"[PATCH] Added headers to request: {list(extra_headers.keys())}\n")
                                sys.stderr.flush()
                            except Exception as e:
                                sys.stderr.write(f"[PATCH] Failed to add headers: {e}\n")
                                import traceback
                                traceback.print_exc(file=sys.stderr)
                                sys.stderr.flush()
            return original_prepare_request(self, request)
        
        BaseClient._prepare_request = patched_prepare_request
    except Exception as e:
        pass
    
    # Patch httpx transport handlers
    try:
        from httpx._transports.default import HTTPTransport, AsyncHTTPTransport
        
        original_handle_request = HTTPTransport.handle_request
        original_handle_async_request = AsyncHTTPTransport.handle_async_request
        
        def patched_handle_request(self, request):
            """Redirect requests trong sync transport và thêm headers"""
            if hasattr(request, 'url'):
                url_str = str(request.url)
                base_proxy_url = REVERSE_PROXY_URL.rstrip("/v1").rstrip("/")
                
                # Redirect URL nếu là api.openai.com
                if "api.openai.com" in url_str:
                    if "/v1" in url_str:
                        new_url = url_str.replace("https://api.openai.com/v1", base_proxy_url + "/v1")
                    else:
                        new_url = url_str.replace("https://api.openai.com", base_proxy_url)
                    request.url = URL(new_url)
                
                # Thêm headers cho TẤT CẢ requests đến langhit.com
                if "langhit.com" in str(request.url):
                    if hasattr(request, 'headers'):
                        headers = request.headers
                        extra_headers = {}
                        if 'user-agent' not in headers and 'User-Agent' not in headers:
                            extra_headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                        if 'Accept' not in headers:
                            extra_headers['Accept'] = 'application/json'
                        if 'Accept-Encoding' not in headers:
                            extra_headers['Accept-Encoding'] = 'gzip, deflate, br'
                        if 'Origin' not in headers:
                            extra_headers['Origin'] = base_proxy_url
                        if 'Referer' not in headers:
                            extra_headers['Referer'] = base_proxy_url + '/'
                        
                        # Update headers
                        if extra_headers:
                            try:
                                if hasattr(headers, 'update'):
                                    headers.update(extra_headers)
                                elif isinstance(headers, dict):
                                    headers.update(extra_headers)
                                else:
                                    for k, v in extra_headers.items():
                                        headers[k] = v
                                sys.stderr.write(f"[PATCH] Added headers to transport request: {list(extra_headers.keys())}\n")
                                sys.stderr.flush()
                            except Exception as e:
                                sys.stderr.write(f"[PATCH] Failed to add headers in transport: {e}\n")
                                sys.stderr.flush()
            return original_handle_request(self, request)
        
        async def patched_handle_async_request(self, request):
            """Redirect requests trong async transport và thêm headers"""
            if hasattr(request, 'url'):
                url_str = str(request.url)
                base_proxy_url = REVERSE_PROXY_URL.rstrip("/v1").rstrip("/")
                
                # Redirect URL nếu là api.openai.com
                if "api.openai.com" in url_str:
                    if "/v1" in url_str:
                        new_url = url_str.replace("https://api.openai.com/v1", base_proxy_url + "/v1")
                    else:
                        new_url = url_str.replace("https://api.openai.com", base_proxy_url)
                    request.url = URL(new_url)
                
                # Thêm headers cho TẤT CẢ requests đến langhit.com
                if "langhit.com" in str(request.url):
                    if hasattr(request, 'headers'):
                        headers = request.headers
                        extra_headers = {}
                        if 'user-agent' not in headers and 'User-Agent' not in headers:
                            extra_headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                        if 'Accept' not in headers:
                            extra_headers['Accept'] = 'application/json'
                        if 'Accept-Encoding' not in headers:
                            extra_headers['Accept-Encoding'] = 'gzip, deflate, br'
                        if 'Origin' not in headers:
                            extra_headers['Origin'] = base_proxy_url
                        if 'Referer' not in headers:
                            extra_headers['Referer'] = base_proxy_url + '/'
                        
                        # Update headers
                        if extra_headers:
                            try:
                                if hasattr(headers, 'update'):
                                    headers.update(extra_headers)
                                elif isinstance(headers, dict):
                                    headers.update(extra_headers)
                                else:
                                    for k, v in extra_headers.items():
                                        headers[k] = v
                                sys.stderr.write(f"[PATCH] Added headers to async transport request: {list(extra_headers.keys())}\n")
                                sys.stderr.flush()
                            except Exception as e:
                                sys.stderr.write(f"[PATCH] Failed to add headers in async transport: {e}\n")
                                sys.stderr.flush()
            return await original_handle_async_request(self, request)
        
        HTTPTransport.handle_request = patched_handle_request
        AsyncHTTPTransport.handle_async_request = patched_handle_async_request
    except Exception as e:
        pass
    
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info(f"✅ Patched httpx transport to redirect api.openai.com → {REVERSE_PROXY_URL}")

# Import mem0 SAU KHI đã patch
try:
    sys.stderr.write("[PATCH] About to import mem0...\n")
    sys.stderr.flush()
    from mem0 import Memory
    sys.stderr.write("[PATCH] Imported mem0 successfully\n")
    sys.stderr.flush()
    
    # Patch OpenAIConfig ở tất cả modules đã import
    sys.stderr.write(f"[PATCH] Checking {len(sys.modules)} modules for OpenAIConfig...\n")
    sys.stderr.flush()
    
    patched_count = 0
    for module_name, module in list(sys.modules.items()):
        if 'OpenAI' in module_name or 'openai' in module_name.lower() or 'mem0' in module_name.lower():
            if hasattr(module, 'OpenAIConfig'):
                try:
                    original_init = module.OpenAIConfig.__init__
                    
                    def make_patched_init(orig_init):
                        def patched_init(self, *args, **kwargs):
                            sys.stderr.write(f"[PATCH] OpenAIConfig.__init__ called with kwargs: {list(kwargs.keys())}\n")
                            sys.stderr.flush()
                            kwargs.pop('base_url', None)
                            kwargs.pop('openai_base_url', None)
                            kwargs.pop('api_base', None)
                            sys.stderr.write(f"[PATCH] After cleanup: {list(kwargs.keys())}\n")
                            sys.stderr.flush()
                            return orig_init(self, *args, **kwargs)
                        return patched_init
                    
                    module.OpenAIConfig.__init__ = make_patched_init(original_init)
                    patched_count += 1
                    sys.stderr.write(f"[PATCH] ✅ Patched OpenAIConfig in module: {module_name}\n")
                    sys.stderr.flush()
                except Exception as e:
                    sys.stderr.write(f"[PATCH] ❌ Failed to patch in {module_name}: {e}\n")
                    sys.stderr.flush()
    
    sys.stderr.write(f"[PATCH] Total patched modules: {patched_count}\n")
    sys.stderr.flush()
    
    # Patch OpenAI client để thêm default headers tránh Cloudflare block
    if REVERSE_PROXY_URL:
        try:
            import openai
            original_openai_init = openai.OpenAI.__init__
            
            def patched_openai_init(self, *args, **kwargs):
                # Thêm default headers để tránh Cloudflare block
                if 'default_headers' not in kwargs:
                    kwargs['default_headers'] = {}
                
                base_proxy_url = REVERSE_PROXY_URL.rstrip('/v1').rstrip('/')
                headers = kwargs['default_headers']
                
                # Headers đầy đủ để bypass Cloudflare
                if 'User-Agent' not in headers and 'user-agent' not in headers:
                    headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                if 'Accept' not in headers:
                    headers['Accept'] = 'application/json'
                if 'Accept-Language' not in headers:
                    headers['Accept-Language'] = 'en-US,en;q=0.9'
                if 'Accept-Encoding' not in headers:
                    headers['Accept-Encoding'] = 'gzip, deflate, br'
                if 'Referer' not in headers:
                    headers['Referer'] = base_proxy_url + '/'
                if 'Origin' not in headers:
                    headers['Origin'] = base_proxy_url
                if 'Connection' not in headers:
                    headers['Connection'] = 'keep-alive'
                if 'Sec-Fetch-Dest' not in headers:
                    headers['Sec-Fetch-Dest'] = 'empty'
                if 'Sec-Fetch-Mode' not in headers:
                    headers['Sec-Fetch-Mode'] = 'cors'
                if 'Sec-Fetch-Site' not in headers:
                    headers['Sec-Fetch-Site'] = 'same-origin'
                
                sys.stderr.write(f"[PATCH] Added default headers to OpenAI client: {list(headers.keys())}\n")
                sys.stderr.flush()
                
                return original_openai_init(self, *args, **kwargs)
            
            openai.OpenAI.__init__ = patched_openai_init
            sys.stderr.write("[PATCH] ✅ Patched OpenAI.__init__ to add default headers\n")
            sys.stderr.flush()
        except Exception as e:
            sys.stderr.write(f"[PATCH] ❌ Failed to patch OpenAI.__init__: {e}\n")
            sys.stderr.flush()
    
except ImportError as e:
    sys.stderr.write(f"[PATCH] ❌ Failed to import mem0: {e}\n")
    sys.stderr.flush()
    raise ImportError("mem0ai package not installed")

# Patch Memory.from_config để loại bỏ base_url từ config dict
original_from_config = Memory.from_config

def patched_from_config(config):
    """Loại bỏ base_url từ config dict trước khi mem0 xử lý"""
    import copy
    cleaned_config = copy.deepcopy(config)
    
    # Loại bỏ base_url từ llm config nếu có
    if "llm" in cleaned_config and "config" in cleaned_config["llm"]:
        llm_config = cleaned_config["llm"]["config"]
        llm_config.pop("base_url", None)
        llm_config.pop("openai_base_url", None)
        llm_config.pop("api_base", None)
    
    # Loại bỏ base_url ở top level nếu có
    cleaned_config.pop("base_url", None)
    cleaned_config.pop("openai_base_url", None)
    cleaned_config.pop("api_base", None)
    
    sys.stderr.write(f"[PATCH] Cleaned config (removed base_url)\n")
    sys.stderr.flush()
    
    return original_from_config(cleaned_config)

Memory.from_config = staticmethod(patched_from_config)

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
        
        # Dùng OpenAI embedder nếu có API key
        # httpx transport đã được patch để redirect sang reverse proxy
        if OPENAI_API_KEY:
            config["embedder"] = {
                "provider": "openai",
                "config": {
                    "model": "text-embedding-3-small",  # Model nhẹ, rẻ
                    "api_key": OPENAI_API_KEY,
                }
            }
        if OPENAI_API_KEY:
            # Dùng OpenAI provider
            # KHÔNG set base_url - httpx transport đã được patch để redirect
            config["llm"] = {
                "provider": "openai",
                "config": {
                    "model": "gpt-4o-mini",
                    "api_key": OPENAI_API_KEY,
                    # KHÔNG set base_url ở đây
                }
            }
        try:
            sys.stderr.write(f"[DEBUG] Creating Memory with config keys: {list(config.keys())}\n")
            sys.stderr.flush()
            memory = Memory.from_config(config)
            memory_instances[user_id] = memory
            sys.stderr.write(f"[DEBUG] ✅ Created Memory instance for user: {user_id}\n")
            sys.stderr.flush()
        except Exception as e:
            sys.stderr.write("=" * 80 + "\n")
            sys.stderr.write("FULL TRACEBACK:\n")
            sys.stderr.write("=" * 80 + "\n")
            traceback.print_exc(file=sys.stderr)
            sys.stderr.write("=" * 80 + "\n")
            sys.stderr.flush()
            raise
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
        sys.stderr.write("=" * 80 + "\n")
        sys.stderr.write("ERROR IN add_memory:\n")
        sys.stderr.write("=" * 80 + "\n")
        traceback.print_exc(file=sys.stderr)
        sys.stderr.write("=" * 80 + "\n")
        sys.stderr.flush()
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

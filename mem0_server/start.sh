#!/bin/bash
# Script để start Cloudflare Proxy và mem0-server

set -e

echo "=== Starting Cloudflare Bypass Proxy ==="

# Build và chạy Cloudflare Proxy
docker build -f Dockerfile.proxy -t cloudflare-proxy:latest . || {
    echo "Failed to build cloudflare-proxy"
    exit 1
}

docker rm -f cloudflare-proxy 2>/dev/null || true

docker run -d \
  --name cloudflare-proxy \
  --restart always \
  -p 3001:3000 \
  -e PROXY_PORT=3000 \
  -e TARGET_URL=https://langhit.com \
  cloudflare-proxy:latest

echo "Waiting for cloudflare-proxy to start (30 seconds)..."
sleep 30

# Kiểm tra proxy có chạy không
if ! docker ps | grep -q cloudflare-proxy; then
    echo "ERROR: cloudflare-proxy failed to start"
    docker logs cloudflare-proxy
    exit 1
fi

echo "=== Starting mem0-server ==="

# Build và chạy mem0-server
docker build --no-cache -t mem0-server:latest . || {
    echo "Failed to build mem0-server"
    exit 1
}

docker rm -f mem0-server 2>/dev/null || true

docker run -d \
  --name mem0-server \
  --restart always \
  -p 8001:8001 \
  -e OPENAI_API_KEY=${OPENAI_API_KEY:-sk-SL4FdpsAirJCaVYeapOOFvi6Xy99Iwz7IjmvK2mGVT1oZWPU} \
  -e CLOUDFLARE_PROXY_URL=http://host.docker.internal:3001 \
  -v $(pwd)/mem0_data:/app/data \
  --network host \
  mem0-server:latest

echo "Waiting for mem0-server to start (20 seconds)..."
sleep 20

# Kiểm tra mem0-server có chạy không
if ! docker ps | grep -q mem0-server; then
    echo "ERROR: mem0-server failed to start"
    docker logs mem0-server
    exit 1
fi

echo "=== Services started successfully ==="
echo "Cloudflare Proxy: http://localhost:3001"
echo "Mem0 Server: http://localhost:8001"
echo ""
echo "To view logs:"
echo "  docker logs cloudflare-proxy"
echo "  docker logs mem0-server"


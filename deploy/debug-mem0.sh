#!/bin/bash

# Script debug mem0 server - xem tất cả logs từ đầu
set -e

echo "========================================="
echo "Debug Mem0 Server - Full Logs"
echo "========================================="

cd /opt/librechat

# Xem logs từ đầu (không chỉ tail)
echo "📋 Full logs from container start:"
docker logs mem0-server 2>&1 | tail -300

echo ""
echo "🔍 Searching for PATCH messages:"
docker logs mem0-server 2>&1 | grep -i "PATCH\|DEBUG\|traceback\|OpenAIConfig" | tail -50

echo ""
echo "🔍 Searching for errors:"
docker logs mem0-server 2>&1 | grep -i "error\|exception\|traceback" | tail -50

echo ""
echo "✅ Debug completed!"


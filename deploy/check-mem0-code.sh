#!/bin/bash

# Script kiểm tra code trong container
set -e

echo "========================================="
echo "Check Mem0 Code in Container"
echo "========================================="

# Kiểm tra xem container có đang chạy không
if ! docker ps | grep -q mem0-server; then
    echo "❌ Container mem0-server is not running"
    exit 1
fi

echo "📋 Checking app.py in container..."
echo ""

# Xem 60 dòng đầu của app.py trong container
echo "First 60 lines of app.py:"
docker exec mem0-server head -60 /app/app.py

echo ""
echo "========================================="
echo "Searching for [PATCH] in app.py:"
docker exec mem0-server grep -n "\[PATCH\]" /app/app.py | head -10

echo ""
echo "========================================="
echo "Checking if sys.stderr.write exists:"
docker exec mem0-server grep -n "sys.stderr.write" /app/app.py | head -5

echo ""
echo "✅ Check completed!"


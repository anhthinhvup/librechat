#!/bin/bash
# Script test OpenAI API key

API_KEY="${1:-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}"

echo "🔍 Testing OpenAI API Key..."
echo ""

# Test 1: Chat Completions
echo "1️⃣ Testing Chat Completions API..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 10
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Chat Completions: OK"
  echo "$BODY" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$BODY"
else
  echo "❌ Chat Completions: Failed (HTTP $HTTP_CODE)"
  echo "$BODY" | jq -r '.error.message' 2>/dev/null || echo "$BODY"
fi
echo ""

# Test 2: Embeddings
echo "2️⃣ Testing Embeddings API..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST https://api.openai.com/v1/embeddings \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "text-embedding-3-small",
    "input": "test"
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Embeddings: OK"
  echo "$BODY" | jq -r '.data[0].embedding | length' 2>/dev/null && echo " dimensions" || echo "$BODY"
else
  echo "❌ Embeddings: Failed (HTTP $HTTP_CODE)"
  ERROR_MSG=$(echo "$BODY" | jq -r '.error.message' 2>/dev/null || echo "$BODY")
  echo "$ERROR_MSG"
  
  if echo "$ERROR_MSG" | grep -qi "quota\|insufficient"; then
    echo "⚠️  QUOTA HẾT - Cần nạp thêm quota"
  elif echo "$ERROR_MSG" | grep -qi "invalid.*key"; then
    echo "⚠️  API KEY KHÔNG HỢP LỆ"
  fi
fi
echo ""

# Test 3: Models List (check account status)
echo "3️⃣ Testing Models List API..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X GET https://api.openai.com/v1/models \
  -H "Authorization: Bearer $API_KEY")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Models List: OK"
  MODEL_COUNT=$(echo "$BODY" | jq '.data | length' 2>/dev/null || echo "0")
  echo "   Available models: $MODEL_COUNT"
else
  echo "❌ Models List: Failed (HTTP $HTTP_CODE)"
  echo "$BODY" | jq -r '.error.message' 2>/dev/null || echo "$BODY"
fi
echo ""

# Summary
echo "📊 Summary:"
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "429" ]; then
  echo "   ✅ API Key hợp lệ"
  if echo "$BODY" | grep -qi "quota\|insufficient"; then
    echo "   ⚠️  Quota đã hết - Cần nạp thêm"
  else
    echo "   ✅ Quota còn (hoặc lỗi khác)"
  fi
else
  echo "   ❌ API Key không hợp lệ hoặc có lỗi"
fi


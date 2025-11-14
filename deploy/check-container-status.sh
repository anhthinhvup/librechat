#!/bin/bash
# Script để kiểm tra trạng thái container sau khi build
# Chạy: bash deploy/check-container-status.sh

cd /opt/librechat || exit 1

echo "=== Kiểm tra Container Status ==="
echo ""

# 1. Kiểm tra containers
echo "1. Trạng thái containers:"
docker-compose ps
echo ""

# 2. Kiểm tra API container logs
echo "2. API Container logs (50 dòng cuối):"
docker-compose logs --tail=50 api
echo ""

# 3. Kiểm tra port 3080
echo "3. Kiểm tra port 3080:"
if netstat -tlnp 2>/dev/null | grep -q ":3080" || ss -tlnp 2>/dev/null | grep -q ":3080"; then
    echo "✓ Port 3080 đang được sử dụng"
    netstat -tlnp 2>/dev/null | grep ":3080" || ss -tlnp 2>/dev/null | grep ":3080"
else
    echo "✗ Port 3080 KHÔNG được sử dụng - API chưa start"
fi
echo ""

# 4. Test API health
echo "4. Test API health:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3080/api/health | grep -q "200"; then
    echo "✓ API health check: OK"
    curl -s http://localhost:3080/api/health | head -3
else
    echo "✗ API health check: FAILED"
    echo "API có thể đang khởi động hoặc có lỗi"
fi
echo ""

# 5. Kiểm tra lỗi trong logs
echo "5. Tìm lỗi trong logs:"
docker-compose logs api 2>&1 | grep -iE "error|failed|exception|syntax" | tail -10 || echo "Không tìm thấy lỗi rõ ràng"
echo ""

# 6. Đề xuất
echo "=== ĐỀ XUẤT ==="
echo ""
echo "Nếu container đang 'Restarting':"
echo "  docker-compose logs -f api"
echo ""
echo "Nếu container không start:"
echo "  docker-compose restart api"
echo ""
echo "Xem logs real-time:"
echo "  docker-compose logs -f api"
echo ""


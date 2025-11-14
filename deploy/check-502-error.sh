#!/bin/bash
# Script để kiểm tra và sửa lỗi 502 Bad Gateway
# Chạy: bash deploy/check-502-error.sh

cd /opt/librechat || exit 1

echo "=== Kiểm tra lỗi 502 Bad Gateway ==="
echo ""

# 1. Kiểm tra containers đang chạy
echo "1. Kiểm tra containers:"
docker-compose ps
echo ""

# 2. Kiểm tra API container có chạy không
echo "2. Kiểm tra API container:"
if docker ps | grep -q LibreChat-API; then
    echo "✓ API container đang chạy"
else
    echo "✗ API container KHÔNG chạy!"
    echo "Đang khởi động lại..."
    docker-compose up -d api
    sleep 5
fi
echo ""

# 3. Kiểm tra API có listen trên port 3080 không
echo "3. Kiểm tra port 3080:"
if netstat -tlnp 2>/dev/null | grep -q ":3080" || ss -tlnp 2>/dev/null | grep -q ":3080"; then
    echo "✓ Port 3080 đang được sử dụng"
    netstat -tlnp 2>/dev/null | grep ":3080" || ss -tlnp 2>/dev/null | grep ":3080"
else
    echo "✗ Port 3080 KHÔNG được sử dụng!"
    echo "API có thể chưa start hoặc đang lỗi"
fi
echo ""

# 4. Test API từ localhost
echo "4. Test API health endpoint:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3080/api/health | grep -q "200"; then
    echo "✓ API health check: OK"
    curl -s http://localhost:3080/api/health | head -5
else
    echo "✗ API health check: FAILED"
    echo "Đang xem logs API..."
    docker-compose logs --tail=50 api | tail -20
fi
echo ""

# 5. Kiểm tra Nginx logs
echo "5. Kiểm tra Nginx error logs:"
if [ -f /var/log/nginx/error.log ]; then
    echo "Lỗi gần đây:"
    tail -10 /var/log/nginx/error.log | grep -E "502|upstream|connect" || echo "Không có lỗi 502 trong logs"
else
    echo "Không tìm thấy /var/log/nginx/error.log"
fi
echo ""

# 6. Kiểm tra Nginx config
echo "6. Kiểm tra Nginx config:"
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx config: OK"
else
    echo "✗ Nginx config: CÓ LỖI!"
    nginx -t
fi
echo ""

# 7. Kiểm tra upstream trong Nginx
echo "7. Kiểm tra upstream librechat trong Nginx:"
if grep -q "upstream librechat" /etc/nginx/sites-enabled/* 2>/dev/null; then
    echo "✓ Upstream librechat đã được cấu hình"
    grep -A 3 "upstream librechat" /etc/nginx/sites-enabled/* | head -5
else
    echo "✗ Upstream librechat CHƯA được cấu hình!"
fi
echo ""

# 8. Kiểm tra API logs chi tiết
echo "8. API logs (50 dòng cuối):"
docker-compose logs --tail=50 api | tail -20
echo ""

# 9. Đề xuất sửa lỗi
echo "=== ĐỀ XUẤT SỬA LỖI ==="
echo ""
echo "Nếu API container không chạy:"
echo "  docker-compose up -d"
echo ""
echo "Nếu API lỗi, xem logs chi tiết:"
echo "  docker-compose logs -f api"
echo ""
echo "Nếu Nginx không proxy được, reload Nginx:"
echo "  systemctl reload nginx"
echo ""
echo "Nếu vẫn lỗi, restart tất cả:"
echo "  docker-compose restart"
echo "  systemctl reload nginx"
echo ""


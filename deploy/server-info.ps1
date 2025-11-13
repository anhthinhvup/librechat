# Script để lấy thông tin server và hiển thị đẹp
# Usage: .\server-info.ps1

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"

Write-Host "=== Thông tin Server ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. Trạng thái Containers:" -ForegroundColor Yellow
ssh $SERVER "cd $SERVER_PATH && docker-compose ps"
Write-Host ""

Write-Host "2. Git Status:" -ForegroundColor Yellow
ssh $SERVER "cd $SERVER_PATH && git status --short"
Write-Host ""

Write-Host "3. Branch hiện tại:" -ForegroundColor Yellow
ssh $SERVER "cd $SERVER_PATH && git rev-parse --abbrev-ref HEAD"
Write-Host ""

Write-Host "4. Commit cuối cùng:" -ForegroundColor Yellow
ssh $SERVER "cd $SERVER_PATH && git log -1 --oneline"
Write-Host ""

Write-Host "5. Disk Usage:" -ForegroundColor Yellow
ssh $SERVER "df -h /opt/librechat"
Write-Host ""

Write-Host "6. Docker Images:" -ForegroundColor Yellow
ssh $SERVER "docker images | grep -E 'librechat|meilisearch|mongo|pgvector'"
Write-Host ""


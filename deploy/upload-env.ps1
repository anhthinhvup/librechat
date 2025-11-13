# Script để upload file .env lên server
# Usage: .\upload-env.ps1

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"
$LOCAL_ENV = "E:\LibreChat-main\LibreChat-main\.env"

Write-Host "=== Upload .env lên server ===" -ForegroundColor Green
Write-Host ""

# Kiểm tra file .env local có tồn tại không
if (-not (Test-Path $LOCAL_ENV)) {
    Write-Host "✗ File .env không tồn tại ở local!" -ForegroundColor Red
    Write-Host "   Đường dẫn: $LOCAL_ENV" -ForegroundColor Yellow
    exit 1
}

# Backup file .env trên server (nếu có)
Write-Host "Đang backup .env trên server..." -ForegroundColor Cyan
ssh $SERVER "cd $SERVER_PATH && if [ -f .env ]; then cp .env .env.backup.$(date +%Y%m%d-%H%M%S); fi"

# Upload file .env lên server
Write-Host "Đang upload .env lên server..." -ForegroundColor Cyan
scp $LOCAL_ENV "$SERVER`:$SERVER_PATH/.env"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Đã upload .env thành công!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Lưu ý:" -ForegroundColor Yellow
    Write-Host "   - Cần restart containers để áp dụng thay đổi:" -ForegroundColor Gray
    Write-Host "     .\manage-server.ps1 restart" -ForegroundColor Cyan
} else {
    Write-Host "✗ Lỗi khi upload file .env!" -ForegroundColor Red
    exit 1
}


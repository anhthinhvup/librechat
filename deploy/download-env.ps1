# Script để download file .env từ server
# Usage: .\download-env.ps1

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"
$LOCAL_ENV = "E:\LibreChat-main\LibreChat-main\.env"

Write-Host "=== Download .env từ server ===" -ForegroundColor Green
Write-Host ""

# Kiểm tra file .env có tồn tại trên server không
Write-Host "Đang kiểm tra file .env trên server..." -ForegroundColor Cyan
$envExists = ssh $SERVER "test -f $SERVER_PATH/.env && echo 'exists' || echo 'not found'"

if ($envExists -eq "not found") {
    Write-Host "✗ File .env không tồn tại trên server!" -ForegroundColor Red
    Write-Host "   Hãy tạo file .env trên server trước." -ForegroundColor Yellow
    exit 1
}

# Backup file .env cũ (nếu có)
if (Test-Path $LOCAL_ENV) {
    $backupPath = "$LOCAL_ENV.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Đang backup file .env cũ..." -ForegroundColor Cyan
    Copy-Item $LOCAL_ENV $backupPath
    Write-Host "✓ Đã backup: $backupPath" -ForegroundColor Green
}

# Download file .env từ server
Write-Host "Đang download .env từ server..." -ForegroundColor Cyan
scp "$SERVER`:$SERVER_PATH/.env" $LOCAL_ENV

if (Test-Path $LOCAL_ENV) {
    Write-Host "✓ Đã download .env thành công!" -ForegroundColor Green
    Write-Host "   File: $LOCAL_ENV" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Lưu ý:" -ForegroundColor Yellow
    Write-Host "   - File .env đã được thêm vào .gitignore" -ForegroundColor Gray
    Write-Host "   - KHÔNG commit file .env lên GitHub!" -ForegroundColor Red
} else {
    Write-Host "✗ Lỗi khi download file .env!" -ForegroundColor Red
    exit 1
}


# Script de commit va push code len GitHub
# Chay script nay tu thu muc LibreChat-main

Write-Host "=== Cap nhat code len server ===" -ForegroundColor Green

# Kiem tra xem co thay doi khong
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Khong co thay doi nao de commit!" -ForegroundColor Yellow
    exit
}

Write-Host "`nCac file da thay doi:" -ForegroundColor Cyan
git status --short

Write-Host "`nDang them cac file vao staging..." -ForegroundColor Cyan
git add .

Write-Host "`nNhap message cho commit (hoac Enter de dung message mac dinh):" -ForegroundColor Yellow
$message = Read-Host
if ([string]::IsNullOrWhiteSpace($message)) {
    $message = "Add phone verification feature"
}

Write-Host "`nDang commit..." -ForegroundColor Cyan
git commit -m $message

Write-Host "`nDang push len GitHub..." -ForegroundColor Cyan
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[OK] Da push code len GitHub thanh cong!" -ForegroundColor Green
    Write-Host "`nBuoc tiep theo:" -ForegroundColor Yellow
    Write-Host "1. SSH vao server: ssh root@88.99.26.236" -ForegroundColor White
    Write-Host "2. Chay lenh: cd /opt/librechat; git pull origin main" -ForegroundColor White
    Write-Host "3. Restart containers: docker-compose down; docker-compose up -d" -ForegroundColor White
} else {
    Write-Host "`n[ERROR] Co loi khi push code!" -ForegroundColor Red
    exit 1
}


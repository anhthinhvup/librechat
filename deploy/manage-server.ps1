# Script để quản lý server từ Windows
# Usage: .\manage-server.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"

function Show-Help {
    Write-Host "=== LibreChat Server Manager ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Các lệnh có sẵn:" -ForegroundColor Yellow
    Write-Host "  update       - Pull code và restart containers"
    Write-Host "  status       - Xem trạng thái containers"
    Write-Host "  logs         - Xem logs API"
    Write-Host "  restart      - Restart tất cả containers"
    Write-Host "  stop         - Stop tất cả containers"
    Write-Host "  start        - Start tất cả containers"
    Write-Host "  shell        - SSH vào server"
    Write-Host "  exec <cmd>   - Chạy lệnh trên server"
    Write-Host "  download-env - Download .env từ server"
    Write-Host "  upload-env   - Upload .env lên server"
    Write-Host ""
    Write-Host "Ví dụ:" -ForegroundColor Cyan
    Write-Host "  .\manage-server.ps1 update"
    Write-Host "  .\manage-server.ps1 logs"
    Write-Host "  .\manage-server.ps1 exec 'docker-compose ps'"
    Write-Host "  .\manage-server.ps1 download-env"
}

function Invoke-ServerCommand {
    param([string]$Cmd)
    ssh $SERVER "cd $SERVER_PATH && $Cmd"
}

function Update-Server {
    Write-Host "Đang cập nhật server..." -ForegroundColor Cyan
    Invoke-ServerCommand "librechat-update"
}

function Get-Status {
    Write-Host "Trạng thái containers:" -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose ps"
}

function Get-Logs {
    Write-Host "Logs API (Ctrl+C để thoát):" -ForegroundColor Cyan
    ssh $SERVER "cd $SERVER_PATH && docker-compose logs -f api"
}

function Restart-Containers {
    Write-Host "Đang restart containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose restart"
}

function Stop-Containers {
    Write-Host "Đang stop containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose down"
}

function Start-Containers {
    Write-Host "Đang start containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose up -d"
}

function Enter-Shell {
    Write-Host "Đang kết nối SSH..." -ForegroundColor Cyan
    ssh $SERVER
}

function Execute-Command {
    param([string]$Cmd)
    Write-Host "Đang chạy: $Cmd" -ForegroundColor Cyan
    Invoke-ServerCommand $Cmd
}

function Download-Env {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.PSCommandPath
    & "$SCRIPT_DIR\download-env.ps1"
}

function Upload-Env {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.PSCommandPath
    & "$SCRIPT_DIR\upload-env.ps1"
}

# Main
switch ($Command.ToLower()) {
    "update" { Update-Server }
    "status" { Get-Status }
    "logs" { Get-Logs }
    "restart" { Restart-Containers }
    "stop" { Stop-Containers }
    "start" { Start-Containers }
    "shell" { Enter-Shell }
    "download-env" { Download-Env }
    "upload-env" { Upload-Env }
    "exec" { 
        if ($args.Count -gt 0) {
            Execute-Command ($args -join " ")
        } else {
            Write-Host "Lỗi: Cần cung cấp lệnh để chạy" -ForegroundColor Red
            Write-Host "Ví dụ: .\manage-server.ps1 exec 'git status'" -ForegroundColor Yellow
        }
    }
    default { Show-Help }
}



param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"

function Show-Help {
    Write-Host "=== LibreChat Server Manager ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Các lệnh có sẵn:" -ForegroundColor Yellow
    Write-Host "  update       - Pull code và restart containers"
    Write-Host "  status       - Xem trạng thái containers"
    Write-Host "  logs         - Xem logs API"
    Write-Host "  restart      - Restart tất cả containers"
    Write-Host "  stop         - Stop tất cả containers"
    Write-Host "  start        - Start tất cả containers"
    Write-Host "  shell        - SSH vào server"
    Write-Host "  exec <cmd>   - Chạy lệnh trên server"
    Write-Host "  download-env - Download .env từ server"
    Write-Host "  upload-env   - Upload .env lên server"
    Write-Host ""
    Write-Host "Ví dụ:" -ForegroundColor Cyan
    Write-Host "  .\manage-server.ps1 update"
    Write-Host "  .\manage-server.ps1 logs"
    Write-Host "  .\manage-server.ps1 exec 'docker-compose ps'"
    Write-Host "  .\manage-server.ps1 download-env"
}

function Invoke-ServerCommand {
    param([string]$Cmd)
    ssh $SERVER "cd $SERVER_PATH && $Cmd"
}

function Update-Server {
    Write-Host "Đang cập nhật server..." -ForegroundColor Cyan
    Invoke-ServerCommand "librechat-update"
}

function Get-Status {
    Write-Host "Trạng thái containers:" -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose ps"
}

function Get-Logs {
    Write-Host "Logs API (Ctrl+C để thoát):" -ForegroundColor Cyan
    ssh $SERVER "cd $SERVER_PATH && docker-compose logs -f api"
}

function Restart-Containers {
    Write-Host "Đang restart containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose restart"
}

function Stop-Containers {
    Write-Host "Đang stop containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose down"
}

function Start-Containers {
    Write-Host "Đang start containers..." -ForegroundColor Cyan
    Invoke-ServerCommand "docker-compose up -d"
}

function Enter-Shell {
    Write-Host "Đang kết nối SSH..." -ForegroundColor Cyan
    ssh $SERVER
}

function Execute-Command {
    param([string]$Cmd)
    Write-Host "Đang chạy: $Cmd" -ForegroundColor Cyan
    Invoke-ServerCommand $Cmd
}

function Download-Env {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.PSCommandPath
    & "$SCRIPT_DIR\download-env.ps1"
}

function Upload-Env {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.PSCommandPath
    & "$SCRIPT_DIR\upload-env.ps1"
}

# Main
switch ($Command.ToLower()) {
    "update" { Update-Server }
    "status" { Get-Status }
    "logs" { Get-Logs }
    "restart" { Restart-Containers }
    "stop" { Stop-Containers }
    "start" { Start-Containers }
    "shell" { Enter-Shell }
    "download-env" { Download-Env }
    "upload-env" { Upload-Env }
    "exec" { 
        if ($args.Count -gt 0) {
            Execute-Command ($args -join " ")
        } else {
            Write-Host "Lỗi: Cần cung cấp lệnh để chạy" -ForegroundColor Red
            Write-Host "Ví dụ: .\manage-server.ps1 exec 'git status'" -ForegroundColor Yellow
        }
    }
    default { Show-Help }
}



# Script để chạy lệnh trên server và trả về output
# Usage: .\server-command.ps1 "command"

param(
    [Parameter(Mandatory=$true)]
    [string]$Command
)

$SERVER = "root@88.99.26.236"
$SERVER_PATH = "/opt/librechat"

# Chạy lệnh trên server
$fullCommand = "cd $SERVER_PATH && $Command"
ssh $SERVER $fullCommand


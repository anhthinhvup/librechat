#!/bin/bash
# Script để setup Git aliases và tools tiện lợi cho quản lý code

echo "=== Setup Git Aliases và Tools ==="

# Git aliases cho các lệnh thường dùng
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.pl pull
git config --global alias.ps push
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.visual "!gitk"

# Aliases cho LibreChat workflow
git config --global alias.update "!git pull origin \$(git rev-parse --abbrev-ref HEAD)"
git config --global alias.pushup "!git push origin \$(git rev-parse --abbrev-ref HEAD)"
git config --global alias.status-short "status --short"
git config --global alias.diff-staged "diff --cached"

echo "✓ Đã setup Git aliases"

# Tạo script pull và deploy tự động
cat > /usr/local/bin/librechat-update << 'EOF'
#!/bin/bash
# Script để pull code và restart containers
cd /opt/librechat || exit 1

echo "=== Cập nhật LibreChat ==="
echo "Branch hiện tại: $(git rev-parse --abbrev-ref HEAD)"

# Pull code
echo "Đang pull code..."
git pull origin $(git rev-parse --abbrev-ref HEAD)

if [ $? -ne 0 ]; then
    echo "✗ Lỗi khi pull code!"
    exit 1
fi

# Restart containers
echo "Đang restart containers..."
docker-compose down
docker-compose up -d

echo "✓ Hoàn thành!"
echo "Kiểm tra logs: docker-compose logs -f api"
EOF

chmod +x /usr/local/bin/librechat-update

echo "✓ Đã tạo script librechat-update"
echo ""
echo "Cách sử dụng:"
echo "  librechat-update    - Pull code và restart containers"
echo ""
echo "Git aliases đã setup:"
echo "  git st              - git status"
echo "  git co <branch>     - git checkout"
echo "  git cm 'message'    - git commit"
echo "  git pl              - git pull"
echo "  git ps              - git push"
echo "  git update          - git pull origin <current-branch>"
echo "  git pushup          - git push origin <current-branch>"
echo "  git lg              - git log với graph đẹp"


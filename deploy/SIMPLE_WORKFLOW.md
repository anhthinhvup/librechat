# Workflow Đơn Giản: Commit → Pull

## Setup ban đầu (chỉ 1 lần)

### Trên Server:

```bash
# Clone từ GitHub
cd /opt
rm -rf librechat  # Nếu đã có
git clone https://github.com/anhthinhvup/librechat.git librechat
cd librechat

# Setup tự động
bash deploy/FRESH_INSTALL.sh

# Hoặc setup thủ công
bash deploy/git-setup.sh
cp deploy/env.production .env
# Generate secrets và cập nhật Google OAuth trong .env
cp deploy/docker-compose.production.yml docker-compose.yml
docker-compose up -d
```

## Workflow hàng ngày

### 1. Sửa code trên Windows

```powershell
cd E:\LibreChat-main\LibreChat-main

# Sửa code...

# Commit và push
git add .
git cm "Mô tả thay đổi"
git ps
```

### 2. Cập nhật trên Server

```bash
# SSH vào server
ssh root@88.99.26.236

# Cập nhật (1 lệnh duy nhất!)
librechat-update
```

**Xong!** Code đã được cập nhật và containers đã restart.

## Các lệnh tiện lợi

### Trên Windows:

```powershell
git st          # Xem status
git cm "msg"    # Commit
git ps          # Push
git pl          # Pull
```

### Trên Server:

```bash
librechat-update              # Pull và restart (khuyến nghị)
git update                    # Chỉ pull code
docker-compose logs -f api    # Xem logs
docker-compose ps             # Xem containers
```

## Lưu ý quan trọng

1. **File .env** không được commit (đã có trong .gitignore)
2. **File docker-compose.yml** nên tạo từ template, không commit
3. **File librechat.yaml** có thể commit nếu không chứa secrets
4. Luôn test trên local trước khi push lên GitHub

## Troubleshooting

### Lỗi khi pull (untracked files)

```bash
cd /opt/librechat
git clean -fd
git pull origin master
```

### Lỗi khi pull (conflict)

```bash
cd /opt/librechat
git st                    # Xem conflict
# Resolve conflict thủ công
git add .
git cm "Resolve conflict"
git ps
```

### Reset về code mới nhất

```bash
cd /opt/librechat
git reset --hard origin/master
docker-compose down
docker-compose up -d
```


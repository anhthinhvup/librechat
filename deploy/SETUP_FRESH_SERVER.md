# Hướng dẫn Setup Server từ đầu (Fresh Install)

## Bước 1: Clone code từ GitHub

```bash
# Xóa thư mục cũ (nếu có)
rm -rf /opt/librechat

# Clone từ GitHub
cd /opt
git clone https://github.com/anhthinhvup/librechat.git librechat
cd librechat
```

## Bước 2: Setup Git workflow

```bash
# Setup Git aliases và tools
bash deploy/git-setup.sh
```

## Bước 3: Tạo file .env

```bash
# Copy từ template
cp deploy/env.production .env

# Generate secrets
MEILI_KEY=$(openssl rand -base64 32 | tr -d '\n')
sed -i "s/MEILI_MASTER_KEY=CHANGE_THIS_TO_SECURE_RANDOM_STRING/MEILI_MASTER_KEY=$MEILI_KEY/" .env

JWT_SEC=$(openssl rand -base64 32 | tr -d '\n')
sed -i "s/JWT_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_SECRET=$JWT_SEC/" .env

JWT_REFRESH=$(openssl rand -base64 32 | tr -d '\n')
sed -i "s/JWT_REFRESH_SECRET=CHANGE_THIS_TO_SECURE_RANDOM_STRING/JWT_REFRESH_SECRET=$JWT_REFRESH/" .env

# Cập nhật Google OAuth (nếu cần)
# nano .env
# Tìm và sửa:
# GOOGLE_CLIENT_ID=...
# GOOGLE_CLIENT_SECRET=...
```

## Bước 4: Copy docker-compose.yml

```bash
cp deploy/docker-compose.production.yml docker-compose.yml
```

## Bước 5: Tạo librechat.yaml (nếu chưa có)

```bash
# Tạo file librechat.yaml từ template hoặc copy từ deploy
# Nếu có script:
bash deploy/create-librechat-yaml.sh
```

## Bước 6: Start containers

```bash
docker-compose up -d
```

## Bước 7: Kiểm tra

```bash
# Xem logs
docker-compose logs -f api

# Kiểm tra containers
docker-compose ps
```

## Workflow sau khi setup

### Khi có code mới từ GitHub:

```bash
# Cách 1: Dùng script tự động (khuyến nghị)
librechat-update

# Cách 2: Thủ công
cd /opt/librechat
git pull origin master
docker-compose down
docker-compose up -d
```

### Khi sửa code trên server (hiếm khi):

```bash
cd /opt/librechat
# Sửa code...
git add .
git cm "Mô tả thay đổi"
git ps
```

## Lưu ý

1. **File .env** không được commit lên GitHub (đã có trong .gitignore)
2. **File docker-compose.yml** nên được tạo từ template mỗi lần
3. **File librechat.yaml** có thể commit nếu không chứa secrets


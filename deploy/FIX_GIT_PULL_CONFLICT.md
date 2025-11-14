# Sửa lỗi Git Pull Conflict

## Vấn đề

Có thay đổi local trên server đang conflict với code mới từ GitHub.

## Giải pháp

### Cách 1: Stash thay đổi local (Khuyến nghị)

```bash
cd /opt/librechat

# Lưu thay đổi local vào stash
git stash

# Pull code mới
git pull origin master

# Xem thay đổi đã stash (nếu cần)
git stash list

# Áp dụng lại thay đổi local (nếu cần)
# git stash pop
```

### Cách 2: Commit thay đổi local trước

```bash
cd /opt/librechat

# Xem thay đổi
git status

# Add và commit thay đổi local
git add deploy/check-sms-logs.sh deploy/setup-twilio-on-server.sh
git commit -m "Local changes on server"

# Pull code mới
git pull origin master

# Nếu có conflict, giải quyết conflict
# git mergetool
# git add <resolved-files>
# git commit
```

### Cách 3: Discard thay đổi local (Nếu không cần)

```bash
cd /opt/librechat

# Xem thay đổi
git status

# Discard thay đổi local
git checkout -- deploy/check-sms-logs.sh deploy/setup-twilio-on-server.sh

# Pull code mới
git pull origin master
```

## Sau khi pull thành công

```bash
# Restart containers
docker-compose restart api

# Kiểm tra logs
docker-compose logs -f api | grep -E "registerUser|Phone verification"
```


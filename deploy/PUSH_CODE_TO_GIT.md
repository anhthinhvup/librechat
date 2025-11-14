# Hướng dẫn Push Code lên Git

## Lưu ý

- **Push code từ máy LOCAL (Windows)**, không phải từ server
- Server chỉ cần pull code về

## Cách 1: Push từ máy local (Windows)

### Bước 1: Mở terminal/PowerShell trên máy Windows

```powershell
# Vào thư mục dự án
cd E:\LibreChat-main\LibreChat-main

# Kiểm tra branch hiện tại
git branch

# Push lên remote
git push origin master
```

### Nếu chưa có remote:

```powershell
# Xem remote hiện tại
git remote -v

# Nếu chưa có, thêm remote
git remote add origin https://github.com/your-username/LibreChat.git

# Push lên
git push -u origin master
```

## Cách 2: Pull code trên server

Sau khi push từ máy local, trên server:

```bash
cd /opt/librechat

# Pull code mới
git pull origin master

# Hoặc nếu đang ở branch khác
git pull origin <branch-name>

# Restart containers
docker-compose restart api
```

## Lưu ý về Authentication

Nếu hỏi username/password:
- Username: GitHub username của bạn
- Password: GitHub Personal Access Token (không dùng password thường)

Tạo Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Chọn quyền: `repo`
4. Copy token và dùng làm password

## Hoặc dùng SSH (khuyến nghị)

```bash
# Trên máy local
git remote set-url origin git@github.com:your-username/LibreChat.git
git push origin master
```


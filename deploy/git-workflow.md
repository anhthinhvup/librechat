# Git Workflow cho LibreChat

## Setup ban đầu (chỉ chạy 1 lần)

```bash
# Trên server
cd /opt/librechat
bash deploy/git-setup.sh
```

## Các lệnh Git tiện lợi

### Trên máy Windows (local)

```powershell
# Xem status
git st

# Commit và push
git add .
git cm "Add phone verification feature"
git ps

# Pull code mới
git pl
```

### Trên server

```bash
# Cập nhật code và restart containers (1 lệnh duy nhất!)
librechat-update

# Hoặc thủ công
cd /opt/librechat
git update          # Pull code từ branch hiện tại
docker-compose down
docker-compose up -d
```

## Workflow đề xuất

### 1. Làm việc trên Windows

```powershell
# 1. Tạo branch mới (nếu cần)
git co -b feature/new-feature

# 2. Sửa code
# ... làm việc ...

# 3. Commit
git add .
git cm "Mô tả thay đổi"

# 4. Push lên GitHub
git ps
```

### 2. Deploy lên server

```bash
# SSH vào server
ssh root@88.99.26.236

# Cập nhật (1 lệnh duy nhất!)
librechat-update
```

## Git Aliases đã setup

| Alias | Lệnh gốc | Mô tả |
|-------|----------|-------|
| `git st` | `git status` | Xem trạng thái |
| `git co` | `git checkout` | Chuyển branch |
| `git br` | `git branch` | Quản lý branch |
| `git cm` | `git commit` | Commit |
| `git pl` | `git pull` | Pull code |
| `git ps` | `git push` | Push code |
| `git lg` | `git log --oneline --graph --decorate --all` | Xem log đẹp |
| `git update` | `git pull origin <current-branch>` | Pull từ branch hiện tại |
| `git pushup` | `git push origin <current-branch>` | Push lên branch hiện tại |

## Tips

### 1. Xem log đẹp
```bash
git lg
```

### 2. Xem thay đổi chưa commit
```bash
git st
git diff
```

### 3. Xem thay đổi đã staged
```bash
git diff-staged
```

### 4. Undo file đã add
```bash
git unstage <file>
```

### 5. Xem commit cuối cùng
```bash
git last
```

## Troubleshooting

### Lỗi khi pull (có conflict)
```bash
# Xem conflict
git st

# Resolve conflict thủ công, sau đó
git add .
git cm "Resolve conflict"
git ps
```

### Lỗi khi pull (untracked files)
```bash
# Backup và xóa untracked files
git clean -fd
git pull origin master
```

### Reset về trạng thái sạch
```bash
# Cẩn thận - sẽ mất thay đổi local!
git reset --hard origin/master
```


# Setup SSH Keys để quản lý server dễ dàng

## Bước 1: Tạo SSH Key trên Windows (nếu chưa có)

```powershell
# Kiểm tra xem đã có SSH key chưa
ls ~/.ssh/id_rsa.pub

# Nếu chưa có, tạo mới
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Nhấn Enter để dùng đường dẫn mặc định
# Nhập passphrase (hoặc Enter để bỏ qua)
```

## Bước 2: Copy SSH Key lên server

```powershell
# Cách 1: Tự động (khuyến nghị)
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@88.99.26.236 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Cách 2: Thủ công
# 1. Xem public key
type $env:USERPROFILE\.ssh\id_rsa.pub

# 2. Copy toàn bộ output
# 3. SSH vào server và chạy:
# ssh root@88.99.26.236
# mkdir -p ~/.ssh
# nano ~/.ssh/authorized_keys
# Paste key vào cuối file
# Ctrl+X, Y, Enter để lưu
# chmod 600 ~/.ssh/authorized_keys
# chmod 700 ~/.ssh
```

## Bước 3: Test kết nối

```powershell
# Test SSH (không cần nhập password)
ssh root@88.99.26.236 "echo 'SSH key đã hoạt động!'"
```

Nếu không cần nhập password, đã thành công!

## Bước 4: Sử dụng script quản lý

```powershell
# Cập nhật server
.\deploy\manage-server.ps1 update

# Xem status
.\deploy\manage-server.ps1 status

# Xem logs
.\deploy\manage-server.ps1 logs

# SSH vào server
.\deploy\manage-server.ps1 shell
```

## Lưu ý bảo mật

1. **Không commit SSH private key** vào Git
2. **Bảo vệ private key** bằng passphrase
3. **Chỉ share public key** (file `.pub`)
4. **Disable password login** trên server (sau khi setup SSH key)

### Disable password login (tùy chọn, nâng cao)

```bash
# Trên server
sudo nano /etc/ssh/sshd_config

# Tìm và sửa:
# PasswordAuthentication no
# PubkeyAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

⚠️ **Cảnh báo**: Chỉ làm bước này sau khi đã test SSH key hoạt động tốt!


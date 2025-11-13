# Cách làm việc với Server qua AI Assistant

## Cách 1: Bạn chạy script, tôi đọc output (Khuyến nghị)

### Bước 1: Setup SSH Keys (chỉ 1 lần)

```powershell
# Xem hướng dẫn chi tiết
cat deploy\setup-ssh-keys.md

# Hoặc chạy nhanh:
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@88.99.26.236 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Bước 2: Khi cần tôi quản lý server

**Bạn chạy script và paste output cho tôi:**

```powershell
# Lấy thông tin server
.\deploy\server-info.ps1

# Hoặc chạy lệnh cụ thể
.\deploy\server-command.ps1 "docker-compose logs --tail=50 api"
.\deploy\server-command.ps1 "git status"
.\deploy\server-command.ps1 "cat .env | grep GOOGLE"
```

**Sau đó paste output vào chat, tôi sẽ phân tích và hướng dẫn tiếp.**

### Bước 3: Tôi sẽ hướng dẫn bạn chạy lệnh

Khi tôi cần chạy lệnh trên server, tôi sẽ nói:
- "Chạy lệnh này: `.\deploy\server-command.ps1 'docker-compose restart api'`"
- Bạn chạy và paste output cho tôi

## Cách 2: Bạn copy terminal output cho tôi

1. Bạn SSH vào server: `ssh root@88.99.26.236`
2. Chạy lệnh tôi yêu cầu
3. Copy toàn bộ output và paste vào chat
4. Tôi sẽ phân tích và hướng dẫn tiếp

## Workflow đề xuất

### Khi bạn muốn tôi giúp quản lý server:

1. **Bạn chạy:**
   ```powershell
   .\deploy\server-info.ps1
   ```

2. **Paste output vào chat**

3. **Tôi sẽ:**
   - Phân tích tình trạng server
   - Đưa ra giải pháp
   - Hướng dẫn bạn chạy lệnh tiếp theo

### Khi tôi cần chạy lệnh:

1. **Tôi sẽ nói:** "Chạy lệnh này: `.\deploy\server-command.ps1 'lệnh'`"

2. **Bạn chạy và paste output**

3. **Tôi tiếp tục phân tích và hướng dẫn**

## Các script có sẵn

| Script | Mô tả |
|--------|-------|
| `server-info.ps1` | Lấy toàn bộ thông tin server |
| `server-command.ps1 "cmd"` | Chạy lệnh bất kỳ trên server |
| `manage-server.ps1 update` | Cập nhật code và restart |
| `manage-server.ps1 status` | Xem trạng thái containers |
| `manage-server.ps1 logs` | Xem logs API |

## Ví dụ

### Tình huống: Server bị lỗi

**Bạn:**
```powershell
.\deploy\server-info.ps1
```

**Output:**
```
=== Thông tin Server ===
1. Trạng thái Containers:
   Name                Status
   LibreChat-API       Up 2 hours
   ...
```

**Bạn paste output vào chat**

**Tôi:** "Tôi thấy container đang chạy. Hãy chạy: `.\deploy\server-command.ps1 'docker-compose logs --tail=100 api'`"

**Bạn chạy và paste output**

**Tôi:** "Tôi thấy lỗi X. Hãy chạy: `.\deploy\server-command.ps1 'docker-compose restart api'`"

Và cứ thế tiếp tục...


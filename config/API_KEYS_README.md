# Hướng dẫn quản lý API Keys

Script này giúp bạn dễ dàng thêm và quản lý API keys cho LibreChat.

## Các lệnh có sẵn

### 1. Thêm API Key

#### Chế độ tương tác (Interactive):
```bash
# Từ host
npm run add-api-key

# Từ Docker container
docker-compose exec api npm run add-api-key
```

Script sẽ hiển thị danh sách providers và yêu cầu bạn chọn provider và nhập API key.

#### Chế độ không tương tác (Non-interactive):
```bash
# Từ host
npm run add-api-key <provider> <api_key>

# Từ Docker container
docker-compose exec api npm run add-api-key <provider> <api_key>
```

Ví dụ:
```bash
npm run add-api-key openai sk-1234567890abcdef
docker-compose exec api npm run add-api-key anthropic sk-ant-...
```

### 2. Xem danh sách API Keys đã cấu hình

```bash
# Từ host
npm run list-api-keys

# Từ Docker container
docker-compose exec api npm run list-api-keys
```

Script sẽ hiển thị các API keys đã được cấu hình (được ẩn một phần để bảo mật) và danh sách các providers chưa được cấu hình.

## Các Providers được hỗ trợ

1. **openai** - OpenAI API Key (GPT-4, GPT-3.5, etc.)
2. **anthropic** - Anthropic API Key (Claude)
3. **google** - Google API Key (Gemini)
4. **azure_openai** - Azure OpenAI API Key
5. **groq** - Groq API Key
6. **mistral** - Mistral API Key
7. **openrouter** - OpenRouter API Key

## Ví dụ sử dụng

### Thêm OpenAI API Key:
```bash
docker-compose exec api npm run add-api-key openai sk-proj-...
```

### Thêm Anthropic API Key:
```bash
docker-compose exec api npm run add-api-key anthropic sk-ant-...
```

### Thêm Google API Key:
```bash
docker-compose exec api npm run add-api-key google AIza...
```

## Sau khi thêm API Key

Sau khi thêm API key, bạn cần khởi động lại container để áp dụng thay đổi:

```bash
# Khởi động lại chỉ container API
docker-compose restart api

# Hoặc khởi động lại toàn bộ
docker-compose restart
```

## Lưu ý

- API keys được lưu trong file `.env` ở thư mục gốc của dự án
- File `.env` được mount vào container, nên thay đổi từ container sẽ cập nhật file trên host
- Khi xem danh sách API keys, chỉ một phần của key được hiển thị để bảo mật
- Script tự động phát hiện xem đang chạy từ container hay từ host

## Troubleshooting

### Lỗi: File .env not found
- Đảm bảo bạn đang chạy script từ thư mục gốc của dự án
- Kiểm tra xem file `.env` có tồn tại không

### Lỗi: Provider không hợp lệ
- Kiểm tra lại tên provider (phải là: openai, anthropic, google, azure_openai, groq, mistral, openrouter)
- Có thể sử dụng số thứ tự thay vì tên provider (1-7)

### API Key không hoạt động sau khi thêm
- Đảm bảo đã khởi động lại container: `docker-compose restart api`
- Kiểm tra lại API key có đúng không
- Xem logs của container: `docker-compose logs api`


# Hướng dẫn thêm Custom Endpoint (Langhit, OpenRouter, v.v.)

Script này giúp bạn dễ dàng thêm custom endpoints (như Langhit, OpenRouter) vào LibreChat.

## Các lệnh có sẵn

### 1. Thêm Custom Endpoint

#### Chế độ tương tác (Interactive - Khuyên dùng):
```bash
# Từ host
npm run add-custom-endpoint

# Từ Docker container
docker-compose exec api node config/add-custom-endpoint.js
```

Script sẽ hướng dẫn bạn:
1. Chọn endpoint phổ biến (Langhit, OpenRouter, Groq, Mistral) hoặc tùy chỉnh
2. Nhập tên endpoint
3. Nhập Base URL
4. Nhập API Key (hoặc sử dụng biến môi trường, hoặc để người dùng nhập)

#### Chế độ không tương tác (Non-interactive):
```bash
# Từ host
npm run add-custom-endpoint <name> <apiKey> <baseURL>

# Từ Docker container
docker-compose exec api node config/add-custom-endpoint.js <name> <apiKey> <baseURL>
```

Ví dụ với Langhit:
```bash
docker-compose exec api node config/add-custom-endpoint.js langhit sk-xxx https://api.langhit.com/v1
```

## Ví dụ: Thêm Langhit

### Bước 1: Thêm endpoint

```bash
docker-compose exec api node config/add-custom-endpoint.js
```

Khi được hỏi:
1. Chọn `1` cho Langhit (hoặc nhập "langhit")
2. Nhập API key của bạn (hoặc chọn option 2 để dùng biến môi trường)
3. Xác nhận

### Bước 2: Nếu sử dụng biến môi trường

Nếu bạn chọn sử dụng biến môi trường (ví dụ: `${LANGHIT_API_KEY}`), thêm vào file `.env`:

```bash
docker-compose exec api node config/add-api-key.js langhit sk-your-api-key-here
```

Hoặc thêm thủ công vào file `.env`:
```
LANGHIT_API_KEY=sk-your-api-key-here
```

### Bước 3: Mount file librechat.yaml vào container

Để file `librechat.yaml` được container sử dụng, bạn cần mount nó vào container. Tạo file `docker-compose.override.yml`:

```yaml
services:
  api:
    volumes:
      - type: bind
        source: ./librechat.yaml
        target: /app/librechat.yaml
```

Sau đó khởi động lại:
```bash
docker-compose down
docker-compose up -d
```

### Bước 4: Khởi động lại container

```bash
docker-compose restart api
```

## Các Custom Endpoints phổ biến

### 1. Langhit
- **Base URL**: `https://api.langhit.com/v1`
- **API Key**: Lấy từ trang Token Management của Langhit
- **Models**: Tự động fetch từ API

### 2. OpenRouter
- **Base URL**: `https://openrouter.ai/api/v1`
- **API Key**: Lấy từ OpenRouter
- **Models**: Tự động fetch từ API

### 3. Groq
- **Base URL**: `https://api.groq.com/openai/v1/`
- **API Key**: Lấy từ Groq
- **Models**: llama3-70b-8192, mixtral-8x7b-32768, etc.

### 4. Mistral
- **Base URL**: `https://api.mistral.ai/v1`
- **API Key**: Lấy từ Mistral AI
- **Models**: mistral-tiny, mistral-small, mistral-medium

## Cấu hình nâng cao

Sau khi thêm endpoint, bạn có thể chỉnh sửa file `librechat.yaml` để:
- Thay đổi danh sách models
- Thêm headers tùy chỉnh
- Cấu hình title conversation
- Thêm các tham số tùy chỉnh

Ví dụ cấu hình Langhit đầy đủ:
```yaml
custom:
  - name: Langhit
    apiKey: ${LANGHIT_API_KEY}
    baseURL: https://api.langhit.com/v1
    models:
      default:
        - gpt-4o
        - gpt-4o-mini
        - gpt-3.5-turbo
      fetch: true
    titleConvo: true
    titleModel: gpt-3.5-turbo
    modelDisplayLabel: Langhit
```

## Troubleshooting

### Lỗi: File librechat.yaml not found
- Đảm bảo file `librechat.yaml` tồn tại ở thư mục gốc dự án
- Hoặc file đã được mount vào container tại `/app/librechat.yaml`

### Endpoint không xuất hiện trong giao diện
- Kiểm tra file `librechat.yaml` có đúng format không
- Đảm bảo đã khởi động lại container: `docker-compose restart api`
- Kiểm tra logs: `docker-compose logs api`

### API Key không hoạt động
- Kiểm tra API key có đúng không
- Nếu dùng biến môi trường, đảm bảo đã thêm vào file `.env`
- Kiểm tra Base URL có đúng không

### Models không load được
- Kiểm tra `fetch: true` trong cấu hình
- Kiểm tra API key có quyền fetch models không
- Xem logs: `docker-compose logs api | grep -i model`

## Lưu ý

- File `librechat.yaml` cần được mount vào container để có hiệu lực
- Sau khi thay đổi `librechat.yaml`, cần khởi động lại container
- API keys được lưu trong file `.env` hoặc trong `librechat.yaml`
- Có thể sử dụng `user_provided` để người dùng nhập API key khi sử dụng






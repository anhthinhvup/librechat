# Hướng dẫn cài đặt Mem0 cho LibreChat

Mem0 là một memory layer cho AI applications, giúp AI nhớ thông tin về người dùng qua các cuộc trò chuyện.

## Tổng quan

Mem0 sẽ chạy như một service riêng trên server, và LibreChat sẽ giao tiếp với nó qua API để lưu trữ và truy xuất thông tin về người dùng.

## Cài đặt Mem0 Server

### Cách 1: Chạy Mem0 trong Docker (Khuyến nghị)

1. **Thêm mem0 service vào docker-compose.yml:**

```yaml
  mem0:
    container_name: mem0-server
    image: python:3.11-slim
    restart: always
    working_dir: /app
    command: >
      sh -c "
        pip install --no-cache-dir mem0ai &&
        python -m mem0.server --host 0.0.0.0 --port 8001
      "
    ports:
      - "8001:8001"
    environment:
      - MEM0_API_KEY=${MEM0_API_KEY:-your-secret-api-key}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./mem0_data:/app/data
    networks:
      - default
    depends_on:
      - mongodb
```

2. **Hoặc tạo file docker-compose.override.yaml:**

```yaml
services:
  mem0:
    container_name: mem0-server
    image: python:3.11-slim
    restart: always
    working_dir: /app
    command: >
      sh -c "
        pip install --no-cache-dir mem0ai &&
        python -m mem0.server --host 0.0.0.0 --port 8001
      "
    ports:
      - "8001:8001"
    environment:
      - MEM0_API_KEY=${MEM0_API_KEY:-your-secret-api-key}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./mem0_data:/app/data
    networks:
      - default
```

### Cách 2: Cài đặt trực tiếp trên server (không dùng Docker)

1. **Cài đặt Python và pip:**
```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip
```

2. **Cài đặt mem0:**
```bash
pip3 install mem0ai
```

3. **Tạo thư mục cho mem0:**
```bash
mkdir -p /opt/mem0/data
cd /opt/mem0
```

4. **Tạo file khởi động mem0 (mem0.service):**
```bash
sudo nano /etc/systemd/system/mem0.service
```

Nội dung file:
```ini
[Unit]
Description=Mem0 Memory Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mem0
Environment="OPENAI_API_KEY=your-openai-api-key"
Environment="MEM0_API_KEY=your-secret-api-key"
ExecStart=/usr/local/bin/python3 -m mem0.server --host 0.0.0.0 --port 8001
Restart=always

[Install]
WantedBy=multi-user.target
```

5. **Khởi động service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable mem0
sudo systemctl start mem0
sudo systemctl status mem0
```

## Cấu hình biến môi trường

Thêm vào file `.env`:

```bash
# Mem0 Configuration
MEM0_API_URL=http://mem0-server:8001
# Hoặc nếu cài trên host: http://localhost:8001
MEM0_API_KEY=your-secret-api-key
ENABLE_MEM0=true
```

## Tích hợp vào LibreChat

Mem0 cần được tích hợp vào code của LibreChat. Bạn có thể:

1. **Sử dụng mem0 trong memory service của LibreChat**
2. **Tạo một service wrapper để gọi mem0 API**

### Ví dụ tích hợp (cần code thêm):

Tạo file `api/server/services/Mem0Service.js`:

```javascript
const axios = require('axios');
const logger = require('~/config/winston');

class Mem0Service {
  constructor() {
    this.apiUrl = process.env.MEM0_API_URL || 'http://mem0-server:8001';
    this.apiKey = process.env.MEM0_API_KEY;
  }

  async addMemory(userId, messages) {
    try {
      const response = await axios.post(
        `${this.apiUrl}/memories`,
        {
          user_id: userId,
          messages: messages,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error) {
      logger.error('[Mem0Service] Error adding memory:', error);
      throw error;
    }
  }

  async getMemories(userId) {
    try {
      const response = await axios.get(
        `${this.apiUrl}/memories/${userId}`,
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
          },
        }
      );
      return response.data;
    } catch (error) {
      logger.error('[Mem0Service] Error getting memories:', error);
      throw error;
    }
  }

  async searchMemories(userId, query) {
    try {
      const response = await axios.post(
        `${this.apiUrl}/memories/${userId}/search`,
        { query },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error) {
      logger.error('[Mem0Service] Error searching memories:', error);
      throw error;
    }
  }
}

module.exports = new Mem0Service();
```

## Khởi động

1. **Nếu dùng Docker:**
```bash
cd /opt/librechat
docker-compose up -d mem0
docker-compose logs -f mem0
```

2. **Nếu cài trực tiếp:**
```bash
sudo systemctl start mem0
sudo systemctl status mem0
```

## Kiểm tra

1. **Kiểm tra mem0 đang chạy:**
```bash
curl http://localhost:8001/health
```

2. **Xem logs:**
```bash
# Docker
docker-compose logs -f mem0

# Systemd
sudo journalctl -u mem0 -f
```

## Lưu ý

- Mem0 cần OpenAI API key để hoạt động (hoặc LLM provider khác)
- Đảm bảo mem0 có thể truy cập được từ container LibreChat
- Nếu chạy trong Docker, đảm bảo mem0 và LibreChat cùng network
- Mem0 sẽ tự động lưu trữ và truy xuất thông tin về người dùng từ các cuộc trò chuyện

## Tài liệu tham khảo

- Mem0 GitHub: https://github.com/mem0ai/mem0
- Mem0 Documentation: https://docs.mem0.ai/


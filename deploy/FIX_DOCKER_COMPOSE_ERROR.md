# Sửa lỗi Docker Compose 'ContainerConfig'

## Vấn đề

Lỗi `KeyError: 'ContainerConfig'` xảy ra khi docker-compose cố recreate containers.

## Giải pháp

### Cách 1: Down và up lại

```bash
cd /opt/librechat

# Stop và xóa tất cả containers
docker-compose down

# Start lại
docker-compose up -d
```

### Cách 2: Xóa containers cũ và tạo lại

```bash
cd /opt/librechat

# Xóa containers cũ
docker-compose rm -f

# Start lại
docker-compose up -d
```

### Cách 3: Restart từng container

```bash
# Restart từng container một
docker restart LibreChat-API
docker restart chat-mongodb
docker restart chat-meilisearch
docker restart vectordb
docker restart rag_api
```


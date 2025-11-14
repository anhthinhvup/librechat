# Ẩn Phone Field tạm thời

## Đã làm

Đã comment out phone field trong form registration để tạm thời ẩn tính năng phone verification.

## File đã sửa

- `client/src/components/Auth/Registration.tsx` - Đã comment out phone input field

## Để bật lại phone field

1. Mở file `client/src/components/Auth/Registration.tsx`
2. Tìm dòng có comment `{/* Phone field temporarily disabled */}`
3. Uncomment phần code phone field

## Rebuild frontend

Sau khi sửa code, cần rebuild frontend:

```bash
cd /opt/librechat

# Nếu dùng Docker với code được mount
docker-compose restart api

# Hoặc nếu cần build lại frontend
cd client
npm run build
cd ..
docker-compose restart api
```

## Lưu ý

- Code đã được sửa trong workspace local
- Cần commit và push lên git để deploy lên server
- Hoặc copy file đã sửa lên server và rebuild


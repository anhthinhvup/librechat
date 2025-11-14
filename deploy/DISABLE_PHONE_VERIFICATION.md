# Tắt tính năng xác minh SMS tạm thời

Hướng dẫn tắt tính năng gửi SMS xác minh số điện thoại tạm thời.

## Cách tắt

### Thêm vào file `.env`

```bash
# Tắt phone verification SMS
ENABLE_PHONE_VERIFICATION=false
```

### Restart server

```bash
# Nếu dùng Docker
docker-compose restart api

# Nếu chạy local
npm run backend:dev
```

## Lưu ý

### Khi tắt phone verification:

✅ **Vẫn hoạt động:**
- User vẫn có thể nhập số điện thoại khi đăng ký
- Số điện thoại vẫn được lưu vào database
- User có thể verify sau trong Settings

❌ **Không hoạt động:**
- Không gửi SMS OTP tự động khi đăng ký
- Không gửi SMS OTP khi user request verify

### Khi bật lại:

```bash
# Bật lại phone verification
ENABLE_PHONE_VERIFICATION=true

# Hoặc xóa dòng này (mặc định là true)
# ENABLE_PHONE_VERIFICATION=false
```

Sau đó restart server.

## Kiểm tra

Sau khi restart, kiểm tra logs:

```bash
docker-compose logs -f api | grep registerUser
```

Bạn sẽ thấy:
```
[registerUser] Phone verification is disabled. Phone number saved but OTP not sent.
```

## Tại sao tắt tạm thời?

- Chưa có SMS provider (Twilio/AWS/HTTP API)
- Đang test registration flow
- Muốn tiết kiệm chi phí SMS
- Chỉ cần lưu số điện thoại, verify sau

## Bật lại khi nào?

- Đã cấu hình SMS provider
- Cần verify số điện thoại ngay khi đăng ký
- Muốn tăng bảo mật cho user


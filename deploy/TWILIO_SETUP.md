# Hướng dẫn cấu hình Twilio SMS

Hướng dẫn nhanh để cấu hình SMS qua Twilio (dễ nhất, đáng tin cậy nhất).

## Tại sao chọn Twilio?

✅ **Ưu điểm:**
- Setup đơn giản, chỉ cần 3 biến môi trường
- Độ tin cậy cao (99.95% uptime SLA)
- Documentation tuyệt vời
- Support tốt
- Trial account miễn phí để test
- Dashboard quản lý tích hợp

❌ **Nhược điểm:**
- Giá cao hơn một số provider khác (~$0.0075/SMS)
- Bị lock-in với Twilio
- Trial account chỉ gửi được đến số đã verify

## Cấu hình nhanh

### Bước 1: Tạo tài khoản Twilio

1. Đăng ký tại: https://www.twilio.com/try-twilio
2. Xác minh số điện thoại và email
3. Vào Console: https://www.twilio.com/console
4. Lấy thông tin:
   - **Account SID** (bắt đầu bằng `AC...`)
   - **Auth Token** (click để hiện)
   - **Phone Number** (số điện thoại Twilio của bạn, format: +1234567890)

### Bước 2: Thêm vào file `.env`

```bash
# Chọn Twilio provider
SMS_PROVIDER=twilio

# Twilio credentials
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890
```

### Bước 3: Restart server

```bash
# Nếu dùng Docker
docker-compose restart api

# Nếu chạy local
npm run backend:dev
```

### Bước 4: Kiểm tra

```bash
# Xem logs
docker-compose logs -f api | grep SMSService

# Bạn sẽ thấy:
# [SMSService] Twilio client initialized
```

## Lưu ý quan trọng

### Trial Account
- ✅ Miễn phí để test
- ✅ Có số điện thoại Twilio miễn phí
- ❌ Chỉ gửi được SMS đến số đã verify trong Twilio Console
- ❌ Có giới hạn số lượng SMS

### Upgrade Account
- Để gửi SMS đến bất kỳ số nào
- Cần thêm thẻ tín dụng
- Giá: ~$0.0075/SMS (tùy quốc gia)
- Xem giá: https://www.twilio.com/sms/pricing

### Verify số điện thoại (Trial)
1. Vào Twilio Console → Phone Numbers → Verified Caller IDs
2. Click "Add a new Caller ID"
3. Nhập số điện thoại muốn nhận SMS
4. Nhập mã xác minh

## Troubleshooting

### Lỗi: "Twilio not configured"
- Kiểm tra `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` đã set trong `.env`
- Đảm bảo không có khoảng trắng thừa

### Lỗi: "TWILIO_PHONE_NUMBER not configured"
- Kiểm tra `TWILIO_PHONE_NUMBER` đã set
- Format phải là E.164: `+1234567890` (có dấu +)

### SMS không gửi được (Trial)
- Kiểm tra số nhận đã được verify trong Twilio Console chưa
- Trial account chỉ gửi được đến số đã verify
- Upgrade account để gửi đến bất kỳ số nào

### SMS không gửi được (Paid)
- Kiểm tra balance trong Twilio Console
- Kiểm tra số điện thoại đúng format E.164
- Xem logs chi tiết trong Twilio Console → Monitor → Logs

## Format số điện thoại

Phải dùng format **E.164**:
- ✅ `+84123456789` (Việt Nam)
- ✅ `+1234567890` (US)
- ❌ `0123456789` (thiếu country code)
- ❌ `84123456789` (thiếu dấu +)

## Chi phí

- **Trial**: Miễn phí (chỉ gửi đến số đã verify)
- **Paid**: ~$0.0075/SMS (tùy quốc gia)
  - US: $0.0075/SMS
  - Việt Nam: ~$0.05/SMS
  - Xem giá đầy đủ: https://www.twilio.com/sms/pricing

## Best Practices

1. **Dùng Trial để test trước** khi upgrade
2. **Verify số điện thoại** trong Twilio Console (trial)
3. **Monitor usage** trong Twilio Console → Monitor
4. **Set up alerts** cho balance thấp
5. **Không commit `.env`** vào git

## So sánh với HTTP API

| Tiêu chí | Twilio | HTTP API |
|----------|--------|----------|
| Độ dễ setup | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Độ tin cậy | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Chi phí | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Support | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Linh hoạt | ⭐⭐ | ⭐⭐⭐⭐⭐ |

## Kết luận

**Chọn Twilio nếu:**
- Cần setup nhanh, đơn giản
- Cần độ tin cậy cao
- Cần support tốt
- Không ngại giá cao hơn một chút

**Chọn HTTP API nếu:**
- Cần giá rẻ
- Cần linh hoạt cao
- Đã có SMS gateway sẵn
- Có kinh nghiệm config API


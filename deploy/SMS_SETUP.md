# SMS Configuration Guide

Hướng dẫn cấu hình SMS để gửi mã xác minh OTP qua số điện thoại.

## Tổng quan

LibreChat hỗ trợ 2 nhà cung cấp SMS:
- **Twilio** (khuyến nghị cho dễ sử dụng)
- **AWS SNS** (cho người dùng đã có AWS account)

## Cấu hình Twilio

### Bước 1: Tạo tài khoản Twilio
1. Đăng ký tại: https://www.twilio.com/try-twilio
2. Xác minh số điện thoại và email
3. Lấy số điện thoại Twilio (trial account có số miễn phí)

### Bước 2: Lấy Credentials
1. Vào Console: https://www.twilio.com/console
2. Copy **Account SID** và **Auth Token**
3. Copy số điện thoại Twilio của bạn (format: +1234567890)

### Bước 3: Cấu hình trong `.env`
```bash
# Chọn provider
SMS_PROVIDER=twilio

# Twilio credentials
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890
```

### Lưu ý:
- Trial account chỉ gửi được SMS đến số đã verify
- Để gửi SMS đến bất kỳ số nào, cần upgrade account
- Giá: ~$0.0075/SMS (tùy quốc gia)

## Cấu hình AWS SNS

### Bước 1: Tạo IAM User
1. Vào AWS Console → IAM → Users
2. Tạo user mới với quyền `AmazonSNSFullAccess`
3. Tạo Access Key và Secret Key

### Bước 2: Cấu hình trong `.env`
```bash
# Chọn provider
SMS_PROVIDER=aws

# AWS credentials
AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_SNS_REGION=us-east-1
```

### Lưu ý:
- Cần có AWS account
- Giá: ~$0.00645/SMS (tùy quốc gia)
- Có thể dùng AWS Free Tier (giới hạn)

## Auto-detect Provider

Nếu không set `SMS_PROVIDER`, hệ thống sẽ tự động:
1. Thử Twilio trước (nếu có credentials)
2. Nếu Twilio không có, thử AWS SNS
3. Nếu cả hai đều không có, log OTP (development mode)

```bash
# Không cần set SMS_PROVIDER
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
```

## Development Mode

Nếu không cấu hình SMS provider, trong development mode:
- OTP sẽ được log ra console
- OTP sẽ được trả về trong API response (chỉ development)
- UI sẽ hiển thị OTP trong toast message

## Kiểm tra cấu hình

Sau khi cấu hình, restart server và kiểm tra logs:
```bash
docker-compose logs -f api | grep SMSService
```

Bạn sẽ thấy:
- `[SMSService] Twilio client initialized` (nếu dùng Twilio)
- `[SMSService] AWS SNS client initialized` (nếu dùng AWS SNS)

## Troubleshooting

### Lỗi: "Twilio not configured"
- Kiểm tra `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` đã set chưa
- Kiểm tra format số điện thoại (phải có + và country code)

### Lỗi: "AWS SNS not configured"
- Kiểm tra `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` đã set chưa
- Kiểm tra IAM user có quyền `AmazonSNSFullAccess`

### SMS không gửi được
- Kiểm tra số điện thoại đúng format E.164 (+country code + number)
- Với Twilio trial: chỉ gửi được đến số đã verify
- Với AWS SNS: kiểm tra region và quyền IAM

### Test trong Development
- Trong development mode, OTP vẫn hiển thị trong UI để test
- Không cần SMS provider để test UI flow

## Chi phí

### Twilio
- Trial: Miễn phí (chỉ gửi đến số đã verify)
- Paid: ~$0.0075/SMS (tùy quốc gia)
- Xem giá: https://www.twilio.com/sms/pricing

### AWS SNS
- Free Tier: 100 SMS/tháng (chỉ US)
- Paid: ~$0.00645/SMS (tùy quốc gia)
- Xem giá: https://aws.amazon.com/sns/pricing/

## Best Practices

1. **Sử dụng Twilio cho production** (dễ setup, reliable)
2. **Sử dụng AWS SNS** nếu đã có AWS infrastructure
3. **Rate limiting**: OTP chỉ có hiệu lực 10 phút
4. **Security**: Không log OTP trong production logs
5. **Testing**: Dùng development mode để test UI flow


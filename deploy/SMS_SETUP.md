# SMS Configuration Guide

Hướng dẫn cấu hình SMS để gửi mã xác minh OTP qua số điện thoại.

## Tổng quan

LibreChat hỗ trợ nhiều nhà cung cấp SMS:
- **HTTP API** (Generic - hỗ trợ bất kỳ SMS gateway nào có HTTP API) ⭐ **Khuyến nghị**
- **Twilio** (dễ sử dụng, phổ biến)
- **AWS SNS** (cho người dùng đã có AWS account)

## Cấu hình HTTP API (Generic Provider) ⭐

Phương pháp linh hoạt nhất, hỗ trợ bất kỳ SMS gateway nào có HTTP API như:
- **Vonage/Nexmo**
- **MessageBird**
- **Plivo**
- **Bandwidth**
- **Infobip**
- **SMS Gateway địa phương** (Việt Nam, v.v.)

### Bước 1: Lấy thông tin API từ nhà cung cấp SMS

Bạn cần có:
- API URL endpoint
- API Key (hoặc username)
- API Secret (hoặc password) - tùy chọn
- Số điện thoại gửi (nếu cần)

### Bước 2: Cấu hình trong `.env`

#### Cấu hình cơ bản (JSON format):
```bash
# Chọn provider
SMS_PROVIDER=http

# Thông tin API
SMS_HTTP_API_URL=https://api.example.com/sms/send
SMS_HTTP_API_KEY=your_api_key_here
SMS_HTTP_API_SECRET=your_api_secret_here  # Tùy chọn
SMS_HTTP_FROM_NUMBER=+1234567890  # Số điện thoại gửi (nếu cần)
```

#### Cấu hình nâng cao (tùy chỉnh theo API của bạn):

```bash
# Provider
SMS_PROVIDER=http

# API Endpoint
SMS_HTTP_API_URL=https://api.example.com/sms/send

# Authentication
SMS_HTTP_API_KEY=your_api_key
SMS_HTTP_API_SECRET=your_api_secret

# HTTP Method và Format
SMS_HTTP_METHOD=POST  # GET hoặc POST
SMS_HTTP_FORMAT=json  # json, form, hoặc query

# Authentication Type
SMS_HTTP_AUTH_TYPE=header  # header hoặc body
SMS_HTTP_AUTH_HEADER=Authorization  # Tên header (mặc định: Authorization)
SMS_HTTP_AUTH_FORMAT=Bearer  # Bearer, Basic, hoặc ApiKey

# Field Mapping (tùy chỉnh tên field trong request)
SMS_HTTP_TO_FIELD=to  # Field name cho số điện thoại nhận
SMS_HTTP_MESSAGE_FIELD=message  # Field name cho nội dung SMS
SMS_HTTP_FROM_FIELD=from  # Field name cho số điện thoại gửi
SMS_HTTP_API_KEY_FIELD=api_key  # Field name cho API key (nếu dùng body auth)
SMS_HTTP_API_SECRET_FIELD=api_secret  # Field name cho API secret

# Response Mapping
SMS_HTTP_MESSAGE_ID_FIELD=message_id  # Field name cho message ID trong response
SMS_HTTP_SUCCESS_FIELD=status  # Field name cho status trong response
SMS_HTTP_SUCCESS_VALUE=success  # Giá trị được coi là thành công

# Timeout
SMS_HTTP_TIMEOUT=10000  # Timeout (ms), mặc định 10 giây
```

### Ví dụ cấu hình cho các provider phổ biến:

#### Vonage/Nexmo:
```bash
SMS_PROVIDER=http
SMS_HTTP_API_URL=https://rest.nexmo.com/sms/json
SMS_HTTP_METHOD=POST
SMS_HTTP_FORMAT=form
SMS_HTTP_API_KEY_FIELD=api_key
SMS_HTTP_API_SECRET_FIELD=api_secret
SMS_HTTP_TO_FIELD=to
SMS_HTTP_MESSAGE_FIELD=text
SMS_HTTP_FROM_FIELD=from
SMS_HTTP_MESSAGE_ID_FIELD=messages[0].message-id
SMS_HTTP_SUCCESS_FIELD=messages[0].status
SMS_HTTP_SUCCESS_VALUE=0
```

#### MessageBird:
```bash
SMS_PROVIDER=http
SMS_HTTP_API_URL=https://rest.messagebird.com/messages
SMS_HTTP_METHOD=POST
SMS_HTTP_FORMAT=json
SMS_HTTP_AUTH_TYPE=header
SMS_HTTP_AUTH_HEADER=Authorization
SMS_HTTP_AUTH_FORMAT=ApiKey
SMS_HTTP_TO_FIELD=recipients
SMS_HTTP_MESSAGE_FIELD=body
SMS_HTTP_FROM_FIELD=originator
```

#### SMS Gateway địa phương (ví dụ Việt Nam):
```bash
SMS_PROVIDER=http
SMS_HTTP_API_URL=https://api.smsgateway.vn/send
SMS_HTTP_METHOD=POST
SMS_HTTP_FORMAT=json
SMS_HTTP_API_KEY_FIELD=username
SMS_HTTP_API_SECRET_FIELD=password
SMS_HTTP_TO_FIELD=phone
SMS_HTTP_MESSAGE_FIELD=content
SMS_HTTP_FROM_FIELD=sender
```

### Lưu ý:
- Kiểm tra tài liệu API của nhà cung cấp để biết format chính xác
- Test với development mode trước khi deploy production
- Đảm bảo API hỗ trợ gửi SMS quốc tế (nếu cần)

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
1. Thử HTTP API trước (nếu có `SMS_HTTP_API_URL`)
2. Thử Twilio (nếu có credentials)
3. Thử AWS SNS (nếu có credentials)
4. Nếu không có provider nào, log OTP (development mode)

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
- `[SMSService] SMS sent via HTTP API to ...` (nếu dùng HTTP API)
- `[SMSService] Twilio client initialized` (nếu dùng Twilio)
- `[SMSService] AWS SNS client initialized` (nếu dùng AWS SNS)

## Troubleshooting

### Lỗi: "Twilio not configured"
- Kiểm tra `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` đã set chưa
- Kiểm tra format số điện thoại (phải có + và country code)

### Lỗi: "SMS_HTTP_API_URL not configured"
- Kiểm tra `SMS_HTTP_API_URL` đã set chưa
- Kiểm tra format URL đúng (phải có http:// hoặc https://)
- Kiểm tra API key và secret đã đúng chưa

### Lỗi: "AWS SNS not configured"
- Kiểm tra `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` đã set chưa
- Kiểm tra IAM user có quyền `AmazonSNSFullAccess`

### SMS không gửi được
- Kiểm tra số điện thoại đúng format E.164 (+country code + number)
- Với HTTP API: kiểm tra field mapping có đúng với API của provider không
- Với HTTP API: kiểm tra authentication method (header vs body)
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

1. **Sử dụng HTTP API cho production** (linh hoạt, hỗ trợ nhiều provider)
2. **Sử dụng Twilio** nếu muốn giải pháp đơn giản, reliable
3. **Sử dụng AWS SNS** nếu đã có AWS infrastructure
4. **Rate limiting**: OTP chỉ có hiệu lực 10 phút
5. **Security**: Không log OTP trong production logs
6. **Testing**: Dùng development mode để test UI flow
7. **Provider địa phương**: Nếu ở Việt Nam/Châu Á, cân nhắc dùng SMS gateway địa phương (giá rẻ hơn, tốc độ nhanh hơn)


# Hướng dẫn cấu hình HTTP API SMS Provider

Hướng dẫn nhanh để cấu hình SMS qua HTTP API (không cần Twilio hay AWS).

## Ưu và Nhược điểm của HTTP API Provider

### ✅ Ưu điểm

1. **Linh hoạt cao**
   - Hỗ trợ bất kỳ SMS gateway nào có HTTP API
   - Không bị ràng buộc với một nhà cung cấp cụ thể
   - Có thể chuyển đổi provider dễ dàng chỉ bằng cách thay đổi URL và config

2. **Tùy chỉnh hoàn toàn**
   - Cấu hình field mapping theo API của từng provider
   - Hỗ trợ nhiều phương thức authentication (Bearer, Basic, ApiKey, v.v.)
   - Hỗ trợ nhiều format request (JSON, form-urlencoded, query params)

3. **Chi phí linh hoạt**
   - Có thể chọn provider giá rẻ nhất
   - Provider địa phương thường rẻ hơn (ví dụ: SMS gateway Việt Nam)
   - Không bị lock-in với một nhà cung cấp

4. **Không phụ thuộc cloud lớn**
   - Không cần AWS account
   - Không cần đăng ký Twilio
   - Có thể dùng provider nhỏ, địa phương

5. **Phù hợp với nhiều use case**
   - SMS marketing
   - OTP/Verification
   - Notification
   - Hỗ trợ cả transactional và promotional SMS

### ❌ Nhược điểm

1. **Cấu hình phức tạp hơn**
   - Cần hiểu API của provider để cấu hình đúng
   - Phải tự map fields, authentication, response format
   - Có thể mất thời gian để test và debug

2. **Không có SDK chính thức**
   - Phải tự xử lý HTTP requests
   - Không có type safety như Twilio SDK
   - Phải tự handle errors và edge cases

3. **Chất lượng phụ thuộc provider**
   - Mỗi provider có độ tin cậy khác nhau
   - Một số provider nhỏ có thể không ổn định
   - Phải tự đánh giá và chọn provider tốt

4. **Debugging khó hơn**
   - Lỗi có thể đến từ nhiều nguồn (network, API, config)
   - Phải kiểm tra logs và response từ API
   - Không có dashboard tích hợp như Twilio Console

5. **Bảo mật tự quản lý**
   - Phải tự bảo vệ API keys
   - Không có tính năng bảo mật tích hợp sẵn
   - Phải tự implement rate limiting nếu cần

6. **Documentation phụ thuộc provider**
   - Mỗi provider có documentation khác nhau
   - Một số provider có tài liệu không rõ ràng
   - Phải tự tìm hiểu và test

## So sánh với các phương pháp khác

| Tiêu chí | HTTP API | Twilio | AWS SNS |
|----------|----------|--------|---------|
| **Độ dễ setup** | ⭐⭐ Trung bình | ⭐⭐⭐⭐⭐ Rất dễ | ⭐⭐⭐ Dễ |
| **Linh hoạt** | ⭐⭐⭐⭐⭐ Rất cao | ⭐⭐ Thấp | ⭐⭐ Thấp |
| **Chi phí** | ⭐⭐⭐⭐ Tốt | ⭐⭐⭐ Trung bình | ⭐⭐⭐ Trung bình |
| **Độ tin cậy** | ⭐⭐⭐ Phụ thuộc provider | ⭐⭐⭐⭐⭐ Rất cao | ⭐⭐⭐⭐⭐ Rất cao |
| **Documentation** | ⭐⭐ Phụ thuộc provider | ⭐⭐⭐⭐⭐ Tuyệt vời | ⭐⭐⭐⭐ Tốt |
| **Hỗ trợ** | ⭐⭐ Phụ thuộc provider | ⭐⭐⭐⭐⭐ Tuyệt vời | ⭐⭐⭐⭐ Tốt |
| **Tùy chỉnh** | ⭐⭐⭐⭐⭐ Hoàn toàn | ⭐⭐ Hạn chế | ⭐⭐ Hạn chế |

## Khi nào nên dùng HTTP API?

### ✅ Nên dùng khi:
- Bạn đã có SMS gateway sẵn (công ty, đối tác)
- Cần giá rẻ (provider địa phương)
- Cần linh hoạt cao, không muốn bị lock-in
- Muốn tự kiểm soát hoàn toàn
- Có team có thể cấu hình và maintain

### ❌ Không nên dùng khi:
- Cần setup nhanh, đơn giản
- Team nhỏ, không có thời gian config
- Cần độ tin cậy cao nhất (critical system)
- Không có kinh nghiệm với HTTP APIs
- Cần support tốt từ provider

## Kết luận

HTTP API provider phù hợp cho:
- **Startup/Doanh nghiệp nhỏ**: Cần giá rẻ, linh hoạt
- **Doanh nghiệp địa phương**: Muốn dùng SMS gateway trong nước
- **Developer có kinh nghiệm**: Có thể tự config và debug
- **Multi-provider strategy**: Muốn có backup providers

Nếu bạn cần giải pháp đơn giản, reliable và có support tốt → chọn **Twilio**
Nếu bạn đã có AWS infrastructure → chọn **AWS SNS**
Nếu bạn cần linh hoạt và giá tốt → chọn **HTTP API**

## Cấu hình nhanh

### Bước 1: Thêm vào file `.env`

```bash
# Chọn HTTP API provider
SMS_PROVIDER=http

# API Endpoint của nhà cung cấp SMS
SMS_HTTP_API_URL=https://api.example.com/sms/send

# API Key (bắt buộc)
SMS_HTTP_API_KEY=your_api_key_here

# API Secret (tùy chọn, nếu API yêu cầu)
SMS_HTTP_API_SECRET=your_api_secret_here

# Số điện thoại gửi (nếu cần)
SMS_HTTP_FROM_NUMBER=+1234567890
```

### Bước 2: Restart server

```bash
docker-compose restart api
# hoặc
npm run backend:dev
```

## Ví dụ cấu hình cho các provider phổ biến

### 1. Vonage/Nexmo

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

### 2. MessageBird

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

### 3. Plivo

```bash
SMS_PROVIDER=http
SMS_HTTP_API_URL=https://api.plivo.com/v1/Account/{auth_id}/Message/
SMS_HTTP_METHOD=POST
SMS_HTTP_FORMAT=json
SMS_HTTP_AUTH_TYPE=header
SMS_HTTP_AUTH_HEADER=Authorization
SMS_HTTP_AUTH_FORMAT=Basic
SMS_HTTP_TO_FIELD=dst
SMS_HTTP_MESSAGE_FIELD=text
SMS_HTTP_FROM_FIELD=src
```

### 4. SMS Gateway địa phương (Ví dụ Việt Nam)

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

## Các biến môi trường có thể cấu hình

### Bắt buộc:
- `SMS_PROVIDER=http` - Chọn HTTP API provider
- `SMS_HTTP_API_URL` - URL endpoint của API

### Tùy chọn cơ bản:
- `SMS_HTTP_API_KEY` - API Key
- `SMS_HTTP_API_SECRET` - API Secret
- `SMS_HTTP_FROM_NUMBER` - Số điện thoại gửi

### Tùy chọn nâng cao:

#### HTTP Method & Format:
- `SMS_HTTP_METHOD=POST` - GET hoặc POST (mặc định: POST)
- `SMS_HTTP_FORMAT=json` - json, form, hoặc query (mặc định: json)

#### Authentication:
- `SMS_HTTP_AUTH_TYPE=header` - header hoặc body (mặc định: body)
- `SMS_HTTP_AUTH_HEADER=Authorization` - Tên header (mặc định: Authorization)
- `SMS_HTTP_AUTH_FORMAT=Bearer` - Bearer, Basic, hoặc ApiKey (mặc định: Bearer)

#### Field Mapping:
- `SMS_HTTP_TO_FIELD=to` - Field name cho số điện thoại nhận
- `SMS_HTTP_MESSAGE_FIELD=message` - Field name cho nội dung SMS
- `SMS_HTTP_FROM_FIELD=from` - Field name cho số điện thoại gửi
- `SMS_HTTP_API_KEY_FIELD=api_key` - Field name cho API key (nếu dùng body auth)
- `SMS_HTTP_API_SECRET_FIELD=api_secret` - Field name cho API secret

#### Response Mapping:
- `SMS_HTTP_MESSAGE_ID_FIELD=message_id` - Field name cho message ID trong response
- `SMS_HTTP_SUCCESS_FIELD=status` - Field name cho status trong response
- `SMS_HTTP_SUCCESS_VALUE=success` - Giá trị được coi là thành công

#### Timeout:
- `SMS_HTTP_TIMEOUT=10000` - Timeout (ms), mặc định 10 giây

## Kiểm tra cấu hình

Sau khi restart server, kiểm tra logs:

```bash
docker-compose logs -f api | grep SMSService
```

Bạn sẽ thấy:
```
[SMSService] SMS sent via HTTP API to +84123456789, MessageId: ...
```

## Troubleshooting

### Lỗi: "SMS_HTTP_API_URL not configured"
- Kiểm tra `SMS_HTTP_API_URL` đã set trong `.env`
- Đảm bảo URL có format đúng: `https://api.example.com/sms/send`

### SMS không gửi được
- Kiểm tra API key và secret đã đúng chưa
- Kiểm tra field mapping có khớp với API của provider không
- Kiểm tra authentication method (header vs body)
- Xem logs để biết lỗi chi tiết

### Test trong Development
- Trong development mode, OTP vẫn hiển thị trong UI để test
- Không cần SMS provider để test UI flow

## Lưu ý

1. **Format số điện thoại**: Phải là E.164 format (+country code + number)
   - Ví dụ: `+84123456789` (Việt Nam), `+1234567890` (US)

2. **Kiểm tra tài liệu API**: Mỗi provider có format khác nhau, đọc tài liệu API của họ để cấu hình đúng

3. **Test trước**: Test với development mode trước khi deploy production

4. **Security**: Không commit file `.env` vào git


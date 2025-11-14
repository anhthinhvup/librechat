# Kiểm tra Phone Verification đã tắt

## Bước 1: Kiểm tra file .env

```bash
cd /opt/librechat

# Kiểm tra đã có ENABLE_PHONE_VERIFICATION=false chưa
grep ENABLE_PHONE_VERIFICATION .env
```

Kết quả mong đợi:
```
ENABLE_PHONE_VERIFICATION=false
```

## Bước 2: Kiểm tra container đã load .env chưa

```bash
# Xem environment variables trong container
docker exec LibreChat env | grep ENABLE_PHONE_VERIFICATION
```

## Bước 3: Test bằng cách đăng ký user mới

Log "Phone verification is disabled" chỉ xuất hiện khi:
- Có user mới đăng ký với số điện thoại
- Hoặc user request verify phone

### Cách test:

1. **Đăng ký user mới** qua UI với số điện thoại
2. **Xem logs real-time:**
   ```bash
   docker-compose logs -f api | grep -E "registerUser|Phone verification"
   ```

3. **Bạn sẽ thấy:**
   ```
   [registerUser] Phone verification is disabled. Phone number saved but OTP not sent.
   ```

## Bước 4: Kiểm tra logs cũ (nếu đã có user đăng ký trước đó)

```bash
# Xem tất cả logs về phone verification
docker-compose logs api | grep -i "phone\|verification\|otp" | tail -20
```

## Nếu chưa thấy log

Có thể:
1. Chưa có user nào đăng ký mới với số điện thoại
2. Cần restart container để load .env mới:
   ```bash
   docker-compose restart api
   ```

## Xác nhận cấu hình đúng

```bash
# 1. Kiểm tra .env
cat .env | grep ENABLE_PHONE_VERIFICATION

# 2. Restart để đảm bảo load .env mới
docker-compose restart api

# 3. Xem logs khi có user đăng ký
docker-compose logs -f api | grep registerUser
```


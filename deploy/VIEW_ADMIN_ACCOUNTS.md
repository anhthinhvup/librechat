# Xem và quản lý account admin

## Xem tất cả users và admin

### Cách 1: Dùng script

```bash
cd /opt/librechat

# Xem tất cả users và admin
chmod +x deploy/view-admin-accounts.sh
./deploy/view-admin-accounts.sh
```

### Cách 2: Vào MongoDB shell

```bash
cd /opt/librechat

# Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# Xem tất cả users
db.users.find({}, {email:1, name:1, role:1, provider:1}).pretty()

# Tìm admin users
db.users.find({role: "ADMIN"}, {email:1, name:1, role:1, provider:1}).pretty()

# Xem user cụ thể
db.users.findOne({email: "phamvanthinhcontact2004@gmail.com"}, {email:1, name:1, role:1, provider:1})

# Thoát
exit
```

## Set role admin cho user

### Cách 1: Dùng script

```bash
cd /opt/librechat

# Set role admin
chmod +x deploy/set-admin.sh
./deploy/set-admin.sh phamvanthinhcontact2004@gmail.com
```

### Cách 2: Vào MongoDB shell

```bash
cd /opt/librechat

# Vào MongoDB shell
docker exec -it chat-mongodb mongosh LibreChat

# Set role admin
db.users.updateOne(
  {email: "phamvanthinhcontact2004@gmail.com"},
  {$set: {role: "ADMIN"}}
)

# Kiểm tra
db.users.findOne({email: "phamvanthinhcontact2004@gmail.com"}, {email:1, role:1})

# Thoát
exit
```

## Xem nhanh

```bash
cd /opt/librechat

# Xem tất cả users
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.find({}, {email:1, role:1}).forEach(u => print(u.email + ' - ' + (u.role || 'USER')))"

# Xem admin users
docker exec chat-mongodb mongosh LibreChat --quiet --eval "db.users.find({role:'ADMIN'}, {email:1, name:1}).forEach(u => print(u.email + ' - ' + (u.name || 'N/A')))"
```

## Lưu ý

- Role mặc định là "USER"
- Role admin là "ADMIN"
- Admin có quyền truy cập vào admin panel và các tính năng quản trị


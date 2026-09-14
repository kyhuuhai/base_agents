---
name: vps-devops-master
description: Linux VPS administration, security hardening, firewalld/fail2ban, systemd services, automated backup scripts, swap configuration, and logrotate for CentOS 9, Amazon Linux (ec2-user), and Ubuntu.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# VPS DevOps Master

Chuyên gia quản trị, bảo mật và tự động hóa hệ thống máy chủ **Linux VPS (CentOS 9, Amazon Linux 2023 / `ec2-user`, RHEL, Ubuntu)**.

---

## 1. Security Hardening (Bảo Mật Máy Chủ Chuẩn Sản Xuất)

### 1.1. Cấu Hình SSH Key & Chặn Password Root Login
```bash
# /etc/ssh/sshd_config
Port 2222                    # Đổi port mặc định (nếu muốn giảm bot scan)
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3

# Áp dụng thay đổi:
systemctl restart sshd
```

### 1.2. Firewall Quản Lý (Firewalld trên CentOS 9 / RHEL)
```bash
# Bật và khởi động firewalld
systemctl enable --now firewalld

# Mở các port cần thiết:
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=2222/tcp

# Reload firewall:
firewall-cmd --reload
firewall-cmd --list-all
```

### 1.3. Cài Đặt & Cấu Hình `fail2ban` (Chống Brute-Force)
```bash
# Cài đặt EPEL & fail2ban trên CentOS 9:
dnf install -y epel-release
dnf install -y fail2ban

# Cấu hình jail cục bộ (/etc/fail2ban/jail.local):
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = 22,2222
EOF

systemctl enable --now fail2ban
fail2ban-client status sshd
```

---

## 2. Tạo Swap File (Tránh OOM Killer Trên VPS Ít RAM)

```bash
# Tạo Swap 4GB:
fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Ghi vào fstab để tự động nạp khi reboot:
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Tối ưu swappiness:
sysctl vm.swappiness=10
echo 'vm.swappiness=10' >> /etc/sysctl.conf
```

---

## 3. Tạo Systemd Service Quản Lý Tiến Trình Daemon

```ini
# /etc/systemd/system/node-app.service
[Unit]
Description=NestJS API Production Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/my-app/apps/api
ExecStart=/usr/bin/npm run start:prod
Restart=always
RestartSec=5s
EnvironmentFile=/var/www/my-app/.env

# Giới hạn tài nguyên
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
# Kích hoạt service:
systemctl daemon-reload
systemctl enable --now node-app
systemctl status node-app
```

---

## 4. Tự Động Hóa Backup Database & Code (Cronjob Shell Script)

```bash
#!/usr/bin/env bash
# /opt/scripts/backup.sh
set -e

BACKUP_DIR="/var/backups/daily"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$BACKUP_DIR"

# 1. Backup PostgreSQL
export PGPASSWORD="db_password"
pg_dump -U appuser -h localhost appdb | gzip > "${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"

# 2. Xóa các bản backup cũ quá 7 ngày:
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed successfully at ${TIMESTAMP}"
```

```bash
# Cấu hình Cronjob chạy 2:00 AM hàng ngày:
# (crontab -e)
0 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

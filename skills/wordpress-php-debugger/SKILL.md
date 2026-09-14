---
name: wordpress-php-debugger
description: Debug WordPress errors (WSOD, Fatal errors, slow queries), optimize PHP-FPM pool settings (max_children, slowlog), manage WP-CLI commands, and configure Redis Object Cache for maximum performance.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# WordPress & PHP-FPM Debugger

Chuyên gia xử lý sự cố, gỡ lỗi và tối ưu hóa hệ thống **WordPress & PHP-FPM** trên môi trường Linux VPS (CentOS 9, Amazon Linux, Ubuntu) và Docker.

---

## 1. Xử Lý Sự Cố WordPress Thường Gặp

### 1.1. Bật Chế Độ Debug Chi Tiết (`wp-config.php`)
```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);
define('SCRIPT_DEBUG', true);
define('SAVEQUERIES', true);
```
- File log lỗi sẽ xuất hiện tại: `wp-content/debug.log`.

### 1.2. White Screen of Death (WSOD) & Memory Limit
Khi gặp lỗi trắng trang hoặc `Fatal error: Allowed memory size of X bytes exhausted`:
```php
// Thêm vào wp-config.php trước dòng "That's all, stop editing!"
define('WP_MEMORY_LIMIT', '512M');
define('WP_MAX_MEMORY_LIMIT', '1024M');
```

---

## 2. Quản Trị Cấp Tốc Bằng `wp-cli` (Terminal Troubleshooting)

```bash
# 1. Kiểm tra trạng thái core WordPress và DB connection:
wp core is-installed --path=/var/www/html
wp db check --path=/var/www/html

# 2. Vô hiệu hóa plugin gây xung đột mà không cần vào Admin UI:
wp plugin list --status=active
wp plugin deactivate error-causing-plugin
# Hoặc tắt toàn bộ plugin khi website sập hoàn toàn:
wp plugin deactivate --all

# 3. Đổi lại mật khẩu Admin khẩn cấp:
wp user update admin --user_pass="StrongNewPassword123!"

# 4. Quét và dọn dẹp Transients / Rác trong Database:
wp transient delete --all
wp db optimize
```

---

## 3. Tối Ưu Hóa Cấu Hình PHP-FPM Pool (`www.conf`)

### 3.1. Công thức tính `pm.max_children` chuẩn xác theo RAM
```
Max Children = (Tổng RAM VPS khả dụng cho PHP-FPM) / (RAM trung bình 1 PHP process)
Ví dụ: VPS 4GB RAM (dành 2.5GB cho PHP, RAM mỗi process WP ~ 60MB):
pm.max_children = 2500MB / 60MB ≈ 40
```

### 3.2. Cấu hình mẫu tối ưu (`/etc/php-fpm.d/www.conf` hoặc `/etc/php/8.x/fpm/pool.d/www.conf`)
```ini
[www]
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660

pm = dynamic
pm.max_children = 40
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 15
pm.max_requests = 1000

; Bật Slow Log để bắt truy vấn / hàm PHP chạy chậm:
request_slowlog_timeout = 5s
slowlog = /var/log/php-fpm/www-slow.log
catch_workers_output = yes
```

### 3.3. Tối ưu OPcache (`php.ini` hoặc `10-opcache.ini`)
```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.revalidate_freq=60
opcache.validate_timestamps=1
opcache.fast_shutdown=1
```

---

## 4. Tích Hợp Redis Object Cache Cho WordPress
1. Cài đặt Redis server: `dnf install -y redis && systemctl enable --now redis`.
2. Cài đặt PHP Redis extension: `dnf install -y php-pecl-redis`.
3. Cài plugin `Redis Object Cache` qua CLI:
   ```bash
   wp plugin install redis-cache --activate
   wp redis enable
   ```
4. Kiểm tra Redis lưu cache: `redis-cli monitor`.

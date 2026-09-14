---
name: nginx-server-pro
description: Architect and optimize Nginx web servers for Node.js, NestJS, Next.js, and PHP-FPM/WordPress. Covers reverse proxy, FastCGI micro-caching, SSL/Certbot, rate limiting, WebSocket support, and security headers.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# Nginx Server Pro

Chuyên gia kiến trúc và tối ưu hóa **Nginx Web Server / Reverse Proxy** đạt chuẩn bảo mật cao (A+ SSL Labs), chịu tải lớn cho cả **Node.js / Next.js / NestJS** và **PHP-FPM / WordPress**.

---

## 1. Nginx Reverse Proxy Cho Node.js / NestJS / Next.js (Hỗ Trợ WebSocket)

```nginx
# /etc/nginx/conf.d/app.conf

upstream backend_app {
    server 127.0.0.1:4000;
    keepalive 64;
}

server {
    listen 80;
    server_name api.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
    include /etc/nginx/default.d/ssl-params.conf;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate Limiting
    limit_req zone=req_limit_per_ip burst=20 nodelay;

    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;

        # WebSocket Support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Proxy Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

---

## 2. Nginx Cho WordPress & PHP-FPM (FastCGI Cache Tối Ưu)

```nginx
# /etc/nginx/conf.d/wordpress.conf

fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m max_size=1g;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    root /var/www/html;
    index index.php index.html;

    # Cache Bypass Logic
    set $skip_cache 0;
    if ($request_method = POST) { set $skip_cache 1; }
    if ($query_string != "") { set $skip_cache 1; }
    if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") { set $skip_cache 1; }
    if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") { set $skip_cache 1; }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;

        # FastCGI Cache Rules
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 301 302 60m;
        add_header X-FastCGI-Cache $upstream_cache_status;
    }

    # Static Assets Caching & Gzip
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|webp|svg|woff2)$ {
        expires 365d;
        add_header Cache-Control "public, no-transform";
        access_log off;
    }

    # Chặn truy cập file nhạy cảm
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
    location ~ /\. { deny all; }
}
```

---

## 3. Cài Đặt SSL Tự Động Với Certbot (Let's Encrypt)

```bash
# Cài đặt Certbot trên CentOS 9 / RHEL:
sudo dnf install -y certbot python3-certbot-nginx

# Tự động lấy chứng chỉ và cấu hình Nginx:
sudo certbot --nginx -d example.com -d www.example.com

# Kiểm tra tự động gia hạn (Dry Run):
sudo certbot renew --dry-run
```

---

## 4. Lệnh Quản Trị & Kiểm Tra Cấu Hình An Toàn

```bash
# Luôn test cú pháp cấu hình trước khi reload:
nginx -t

# Reload không làm gián đoạn kết nối hiện tại (Zero-downtime):
systemctl reload nginx

# Xem log lỗi theo thời gian thực:
tail -f /var/log/nginx/error.log
```

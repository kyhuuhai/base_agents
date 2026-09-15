---
name: aws-core-services
description: Use when deploying, provisioning, configuring, or integrating AWS core infrastructure: EC2, S3, CloudFront, and RDS.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# AWS Core Services

Chuyên gia cấu hình, triển khai và tích hợp 4 dịch vụ hạ tầng đám mây cốt lõi của **Amazon Web Services (AWS)**: **EC2**, **S3**, **CloudFront**, và **RDS**. Tập trung vào tính bảo mật, tối ưu chi phí, hiệu năng cao và tự động hóa cho lập trình viên.

---

## 1. Sơ Đồ Kiến Trúc Chuẩn (AWS Core Architecture)

Mô hình bảo mật nhiều lớp chuẩn production:

```mermaid
graph TD
    User([Khách hàng / Internet]) -->|HTTPS:443| CF[AWS CloudFront CDN]
    
    subgraph "Public Zone"
        CF -->|Static Assets / Media| S3[AWS S3 Bucket (Private)]
        CF -->|API / Dynamic Requests| EC2[AWS EC2 Instance (App / Nginx)]
    end

    subgraph "Private Subnet / Isolated VPC"
        EC2 -->|Internal DB Connection: 5432/3306| RDS[(AWS RDS - Postgres/MySQL)]
    end
```

---

## 2. AWS EC2 (Elastic Compute Cloud): Cấu Hình & Triển Khai

### 2.1. Security Group Chuẩn cho EC2
Tuyệt đối không mở toàn bộ port ra internet:
- **Port 22 (SSH)**: Giới hạn IP cụ thể (`your_office_ip/32`), không để `0.0.0.0/0`.
- **Port 80 (HTTP)** & **Port 443 (HTTPS)**: Mở cho toàn bộ internet (`0.0.0.0/0`) hoặc chỉ cho dải IP của CloudFront.
- **Port Database (5432, 3306, 6379)**: **CẤM** mở inbound từ internet.

### 2.2. User Data Script: Tự động khởi tạo Server khi Launch Instance
Script chạy một lần duy nhất khi máy ảo khởi động lần đầu (Ubuntu 22.04 / 24.04 LTS):

```bash
#!/bin/bash
set -e

# Cập nhật OS và cài đặt công cụ thiết yếu
apt-get update -y
apt-get upgrade -y
apt-get install -y git curl ufw fail2ban htop unzip

# Cài đặt Docker & Docker Compose Plugin
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Cài đặt AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Bật tường lửa UFW cơ bản
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

---

## 3. AWS S3 (Simple Storage Service): Lưu Trữ & Presigned URL

### 3.1. Quy chuẩn Bảo mật Bucket S3
- **Block Public Access = ON**: Toàn bộ Bucket phải chặn truy cập công khai trực tiếp.
- Phân phối file tĩnh ra bên ngoài **BẮT BUỘC** qua CloudFront thông qua **Origin Access Control (OAC)**.

### 3.2. Code SDK v3: Upload & Tạo Presigned URL (Node.js/TypeScript)
Tuyệt đối không cho client upload trực tiếp thông qua backend gây nghẽn băng thông server. Sử dụng **Presigned URL**:

```typescript
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

/**
 * Khởi tạo AWS S3 Client với AWS SDK v3
 */
export const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'ap-southeast-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});

/**
 * Tạo URL ký trước (Presigned URL) cho phép Client upload file trực tiếp lên S3
 * @param bucketName Tên bucket S3
 * @param key Đường dẫn file trên S3 (ví dụ: 'avatars/usr-123.jpg')
 * @param contentType Định dạng MIME của file (ví dụ: 'image/jpeg')
 * @param expiresInSeconds Thời gian hiệu lực của link (mặc định 300s = 5 phút)
 * @returns Đường dẫn presigned URL dùng method PUT
 */
export async function getUploadPresignedUrl(
  bucketName: string,
  key: string,
  contentType: string,
  expiresInSeconds = 300,
): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: bucketName,
    Key: key,
    ContentType: contentType,
  });

  return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
}
```

---

## 4. AWS CloudFront: CDN Phân Phối Tốc Độ Cao & Bảo Mật

### 4.1. Cấu hình Caching & Behavior
- **Static Assets (JS, CSS, Images)**: `Cache-Control: max-age=31536000, immutable` (Cache tại Edge Server 1 năm).
- **API Dynamic Calls**: `Cache Policy = CachingDisabled`, chuyển tiếp toàn bộ Query Strings, Headers (Authorization), và Cookies về EC2 origin.
- **SSL Certificate**: Bắt buộc tạo tại region **`us-east-1` (N. Virginia)** trong AWS Certificate Manager (ACM) để gắn vào CloudFront Distribution.

### 4.2. Lệnh CLI Invalidate Cache sau khi Deploy
Mỗi lần deploy code frontend mới lên S3, bắt buộc xóa cache CloudFront:

```bash
# Xóa toàn bộ cache CloudFront
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

## 5. AWS RDS: Cơ Sở Dữ Liệu Quản Trị (Postgres / MySQL)

### 5.1. Quy tắc Vàng về Mạng & Bảo Mật RDS
1. **Publicly Accessible = NO**: Không bao giờ đặt RDS ở chế độ Public.
2. **Security Group Isolation**:
   - Tạo riêng một Security Group cho RDS (ví dụ: `sg-rds`).
   - Inbound Rule: Chỉ cho phép traffic cổng 5432 (Postgres) hoặc 3306 (MySQL) từ nguồn là **Security Group của EC2** (`sg-ec2-backend`).
3. **Multi-AZ Deployment**:
   - Môi trường Staging/Dev: Tắt Multi-AZ để tiết kiệm 50% chi phí.
   - Môi trường Production: Bật Multi-AZ để dự phòng nóng (Failover tự động khi datacenter gặp sự cố).

### 5.2. Chuỗi Kết Nối Database An Toàn (Environment Variable)
```env
# Kết nối an toàn qua Private IP / Internal DNS của RDS
DATABASE_URL=postgresql://dbadmin:ComplexPassword123@prod-db.c7x8y.ap-southeast-1.rds.amazonaws.com:5432/app_production?sslmode=require
```

---

## 6. Red Flags AWS - Cần Ngăn Chặn Ngay Lập Tức

| Lỗi phổ biến | Rủi ro | Giải pháp chuẩn |
| :--- | :--- | :--- |
| Hardcode AWS Key trong source code | Bị quét bot trên GitHub, lộ hóa đơn nghìn USD | Dùng **IAM Role** gắn thẳng vào EC2 instance |
| Mở RDS Public (`0.0.0.0/0`) | Bị tấn công Brute-force, ransomware mã hóa DB | Đặt RDS trong Private Subnet, chỉ EC2 mới vào được |
| Cho client upload file qua Backend server | Nghẽn CPU, tốn băng thông EC2 | Dùng **S3 Presigned URL** upload trực tiếp |
| Không đặt Alert Billing | Hóa đơn tăng vọt bất ngờ do DDOS hoặc leak key | Luôn thiết lập **AWS CloudWatch Billing Alarm** ở mức $50, $100 |

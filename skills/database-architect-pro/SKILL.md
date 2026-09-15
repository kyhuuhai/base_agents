---
name: database-architect-pro
description: Use when designing schemas, optimizing queries, managing migrations, configuring connection pools, or implementing caching for PostgreSQL, MySQL, MongoDB, and Redis.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# Database Architect Pro

Quy chuẩn xử lý cơ sở dữ liệu cho các **tác vụ hằng ngày** của lập trình viên. Mặc định ưu tiên bộ đôi cốt lõi: **PostgreSQL + Redis** (nhẹ, nhanh, chuẩn thực chiến). Chỉ mở rộng sang MySQL hoặc MongoDB khi có yêu cầu đặc thù.

---

## 1. Bản Đồ Lựa Chọn Công Nghệ (Decision Matrix)

| Cơ sở dữ liệu | Điểm mạnh nhất | Use Case thực tế | ORM / Driver chuẩn |
| :--- | :--- | :--- | :--- |
| **PostgreSQL** | Quan hệ phức tạp, JSONB, ACID tuyệt đối | Core business, thanh toán, tài khoản, quan hệ N-N | Prisma, Drizzle, TypeORM, pg |
| **MySQL** | Read-heavy, phổ biến, ổn định | E-commerce, CMS, blog, bảng dữ liệu phẳng | Prisma, Drizzle, TypeORM, mysql2 |
| **MongoDB** | Schema linh hoạt, nested documents | Catalog sản phẩm linh hoạt, logs, chat history | Mongoose, MongoDB Native Driver |
| **Redis** | In-memory cực nhanh, cấu trúc dữ liệu đa dạng | Caching, session, rate limit, queue (BullMQ), locks | ioredis |

---

## 2. PostgreSQL & MySQL: Chuẩn Quan Hệ & Tối Ưu Hóa

### 2.1. Quản lý Connection Pooling & Tránh cạn kiệt kết nối
Tuyệt đối không khởi tạo client mới cho mỗi query. Bắt buộc dùng Pool:

```typescript
import { Pool } from 'pg';

/**
 * Singleton PostgreSQL Pool instance
 * Tối ưu hóa số lượng kết nối đồng thời và timeout
 */
export const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                      // Tối đa 20 clients trong pool
  idleTimeoutMillis: 30000,     // Đóng client rảnh sau 30s
  connectionTimeoutMillis: 5000,// Báo lỗi nếu kết nối DB quá 5s
});
```

### 2.2. Chiến lược Indexing (B-Tree & Composite Index)
- **Luôn đánh Index cho Foreign Keys**: PostgreSQL và MySQL không tự đánh index trên foreign key cột con.
- **Composite Index (Quy tắc tiền tố bên trái)**: Nếu thường query `WHERE tenant_id = ? AND status = ?`, index phải là `(tenant_id, status)`.

```sql
-- PostgreSQL / MySQL: Index composite cho truy vấn đa điều kiện
CREATE INDEX idx_orders_tenant_status ON orders (tenant_id, status, created_at DESC);

-- PostgreSQL: Index chuyên biệt cho tìm kiếm trong JSONB
CREATE INDEX idx_users_metadata ON users USING gin (metadata);
```

### 2.3. Transaction ACID An Toàn (PostgreSQL / MySQL)
Bắt buộc sử dụng Transaction khi có từ 2 thao tác ghi dữ liệu liên quan trở lên:

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Chuyển tiền giữa hai tài khoản với Transaction an toàn
 * @param fromAccountId ID tài khoản nguồn
 * @param toAccountId ID tài khoản đích
 * @param amount Số tiền cần chuyển (phải > 0)
 * @returns Kết quả giao dịch
 */
export async function transferFunds(
  fromAccountId: string,
  toAccountId: string,
  amount: number,
) {
  return await prisma.$transaction(async (tx) => {
    // Bước 1: Trừ tiền tài khoản nguồn (kèm kiểm tra số dư)
    const sender = await tx.account.update({
      where: { id: fromAccountId },
      data: { balance: { decrement: amount } },
    });

    if (sender.balance < 0) {
      throw new Error('Số dư không đủ để thực hiện giao dịch.');
    }

    // Bước 2: Cộng tiền tài khoản đích
    const receiver = await tx.account.update({
      where: { id: toAccountId },
      data: { balance: { increment: amount } },
    });

    return { sender, receiver };
  });
}
```

---

## 3. MongoDB: Document Schema & Aggregation

### 3.1. Embedded vs Reference Pattern
- **Embed (< 100 items)**: Khi dữ liệu con luôn được đọc cùng dữ liệu cha và không tăng trưởng vô hạn (ví dụ: `addresses` trong `user`, `items` trong `order`).
- **Reference (> 1000 items)**: Khi dữ liệu con tăng liên tục theo thời gian (ví dụ: `comments` trong `post`, `logs` trong `device`).

### 3.2. Mongoose Schema Chuẩn kèm Indexing

```typescript
import mongoose, { Schema, Document } from 'mongoose';

export interface IUserLog extends Document {
  userId: mongoose.Types.ObjectId;
  action: string;
  ipAddress: string;
  createdAt: Date;
}

const UserLogSchema = new Schema<IUserLog>(
  {
    userId: { type: Schema.Types.ObjectId, required: true, ref: 'User', index: true },
    action: { type: String, required: true },
    ipAddress: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

// TTL Index: Tự động xóa log sau 30 ngày để tiết kiệm dung lượng
UserLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

export const UserLogModel = mongoose.model<IUserLog>('UserLog', UserLogSchema);
```

---

## 4. Redis: Caching, Key Design & Distributed Locks

### 4.1. Quy tắc đặt tên Redis Key (Namespacing)
- Cú pháp: `<service>:<entity>:<id>:<attribute>`
- Ví dụ: `auth:token:usr_12345`, `cache:product:prd_9981:detail`.
- **LUÔN ĐẶT TTL (Time-To-Live)**: Tuyệt đối không để key cache vĩnh viễn (gây tràn RAM).

### 4.2. Pattern: Cache-Aside với ioredis

```typescript
import Redis from 'ioredis';

export const redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

/**
 * Lấy dữ liệu với cơ chế Cache-Aside (đọc cache trước, nếu miss thì query DB và ghi cache)
 * @param key Khóa định danh trên Redis
 * @param ttlSeconds Thời gian sống của cache (giây)
 * @param fetchFn Hàm query dữ liệu gốc nếu cache miss
 */
export async function getOrSetCache<T>(
  key: string,
  ttlSeconds: number,
  fetchFn: () => Promise<T>,
): Promise<T> {
  // Bước 1: Kiểm tra cache trong Redis
  const cachedData = await redisClient.get(key);
  if (cachedData) {
    return JSON.parse(cachedData) as T;
  }

  // Bước 2: Cache miss -> Thực thi hàm lấy dữ liệu gốc
  const freshData = await fetchFn();

  // Bước 3: Lưu vào Redis kèm TTL để tự động giải phóng bộ nhớ
  if (freshData !== null && freshData !== undefined) {
    await redisClient.set(key, JSON.stringify(freshData), 'EX', ttlSeconds);
  }

  return freshData;
}
```

### 4.3. Distributed Lock (Khóa phân tán cơ bản)
Dùng để ngăn chặn 2 tác vụ/worker chạy trùng lặp cùng một thời điểm:

```typescript
/**
 * Thử giành khóa phân tán trong Redis
 * @param lockKey Tên khóa (ví dụ: lock:order:123)
 * @param ttlMs Thời gian giữ khóa tối đa (tránh deadlock)
 * @returns true nếu giành được khóa, false nếu đang có tiến trình khác giữ
 */
export async function acquireLock(lockKey: string, ttlMs: number): Promise<boolean> {
  const result = await redisClient.set(lockKey, 'locked', 'PX', ttlMs, 'NX');
  return result === 'OK';
}
```

---

## 5. Docker Compose Dev: Mặc Định Hằng Ngày (PostgreSQL + Redis)

Chuẩn tinh gọn cho dev local hằng ngày, nhẹ máy, khởi động tức thì:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: dev-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgrespassword
      POSTGRES_DB: app_db
    ports:
      - '5432:5432'
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    restart: unless-stopped
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data

volumes:
  pg_data:
  redis_data:
```

> **Lưu ý**: Chỉ thêm MySQL hoặc MongoDB khi dự án cụ thể có yêu cầu rõ ràng. Mặc định luôn ưu tiên cặp đôi **Postgres + Redis**.


---

## 6. Red Flags Database - Bắt Buộc Tuân Thủ

- **Tránh N+1 Query**: Không lặp vòng for để gọi query database. Dùng `IN (...)` hoặc `include/populate` của ORM.
- **Không bao giờ dùng `SELECT *`** trong production với các bảng nhiều cột lớn hoặc kiểu dữ liệu text/blob.
- **Không dùng Redis làm Database chính**: Redis chỉ dành cho Caching, Session, Locks, Queue. Dữ liệu vĩnh viễn phải nằm ở Postgres/MySQL/MongoDB.
- **Mọi Migration phải có rollback**: Viết migration bằng Prisma (`prisma migrate`) hoặc TypeORM phải luôn kiểm tra khả năng migrate down.

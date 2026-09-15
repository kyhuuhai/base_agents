---
name: nestjs-backend-pro
description: Use when building production-grade NestJS backend applications requiring modular architecture, BullMQ background jobs, Redis task queues, cron scheduling, resilient 3rd-party API integrations, or secure webhook handling.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# NestJS Backend Pro

Quy chuẩn thiết kế và lập trình Backend NestJS chuẩn Enterprise, tập trung giải quyết bài toán xử lý tác vụ nền (**Background Jobs / BullMQ**), lập lịch (**Cron Jobs**), và tích hợp dịch vụ bên thứ ba (**3rd-Party Integrations & Webhooks**) với độ tin cậy và hiệu năng cao.

---

## 1. Kiến Trúc Module Chuẩn (Clean Modular Structure)

Tuyệt đối không viết monolithic code hay gộp toàn bộ logic vào Controller. Cấu trúc thư mục chuẩn cho từng tính năng:

```
src/
├── common/                     # Tiện ích chung: decorators, filters, interceptors, guards
│   ├── filters/http-exception.filter.ts
│   └── guards/api-key.guard.ts
├── config/                     # Quản lý env & config validation (Joi / Zod)
│   ├── configuration.ts
│   └── validation.ts
├── database/                   # Prisma / TypeORM config & migrations
├── modules/
│   ├── auth/                   # JWT, RBAC, Guards
│   ├── integrations/           # Giao tiếp với dịch vụ thứ 3 (Stripe, OpenAI, Telegram...)
│   │   ├── providers/          # Adapter cho từng bên thứ 3
│   │   └── integrations.module.ts
│   ├── queues/                 # BullMQ queues & worker definitions
│   │   ├── email.queue.ts
│   │   ├── sync.queue.ts
│   │   └── queues.module.ts
│   └── tasks/                  # Cron jobs (@nestjs/schedule)
└── app.module.ts
```

---

## 2. Background Jobs & Worker (@nestjs/bullmq + Redis)

### 2.1. Cấu hình Queue Module (queues.module.ts)

```typescript
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (config: ConfigService) => ({
        connection: {
          host: config.get<string>('REDIS_HOST', 'localhost'),
          port: config.get<number>('REDIS_PORT', 6379),
          password: config.get<string>('REDIS_PASSWORD'),
        },
      }),
      inject: [ConfigService],
    }),
    BullModule.registerQueue({
      name: 'tasks',
      defaultJobOptions: {
        attempts: 3,                          // Thử lại tối đa 3 lần nếu lỗi
        backoff: {
          type: 'exponential',               // Thử lại tăng dần: 2s, 4s, 8s...
          delay: 2000,
        },
        removeOnComplete: { count: 1000 },    // Lưu 1000 job gần nhất
        removeOnFail: { count: 5000 },        // Lưu job fail để debug
      },
    }),
  ],
  exports: [BullModule],
})
export class QueuesModule {}
```

### 2.2. Producer: Đẩy Job từ Controller / Service

Controller **BẮT BUỘC** phản hồi `202 Accepted` ngay lập tức, không để client chờ tiến trình ngầm hoàn tất:

```typescript
import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';

@Controller('tasks')
export class TasksController {
  constructor(@InjectQueue('tasks') private readonly tasksQueue: Queue) {}

  @Post('sync')
  @HttpCode(HttpStatus.ACCEPTED)
  async enqueueSyncTask(@Body() payload: { userId: string; syncType: string }) {
    const job = await this.tasksQueue.add('execute-sync', payload, {
      jobId: `sync-${payload.userId}-${Date.now()}`, // Tránh trùng lặp
    });

    return {
      status: 'accepted',
      jobId: job.id,
      message: 'Task đã được đưa vào hàng đợi xử lý ngầm.',
    };
  }
}
```

### 2.3. Consumer / Worker: Xử lý Job ngầm (tasks.worker.ts)

```typescript
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';

@Processor('tasks', { concurrency: 5 }) // Chạy song song 5 job cùng lúc
export class TasksWorker extends WorkerHost {
  private readonly logger = new Logger(TasksWorker.name);

  async process(job: Job<any, any, string>): Promise<any> {
    this.logger.log(`[Job ${job.id}] Bắt đầu xử lý: ${job.name}`);

    switch (job.name) {
      case 'execute-sync':
        return await this.handleSync(job.data);
      default:
        throw new Error(`Không hỗ trợ job name: ${job.name}`);
    }
  }

  private async handleSync(data: { userId: string; syncType: string }) {
    // Logic gọi API bên thứ ba hoặc tính toán nặng
    return { success: true, processedAt: new Date() };
  }
}
```

---

## 3. Quản Lý Tác Vụ Định Kỳ (@nestjs/schedule)

Dùng cho việc quét đồng bộ dữ liệu, dọn dẹp log, hoặc kiểm tra health check định kỳ:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class CronTaskService {
  private readonly logger = new Logger(CronTaskService.name);
  private isRunning = false;

  @Cron(CronExpression.EVERY_5_MINUTES)
  async handlePeriodicSync() {
    // Lock cơ bản tránh overlapping nếu lần chạy trước chưa xong
    if (this.isRunning) {
      this.logger.warn('Lần chạy trước chưa hoàn tất, bỏ qua lần này.');
      return;
    }

    this.isRunning = true;
    try {
      this.logger.log('Bắt đầu đồng bộ định kỳ 5 phút...');
      // Thực thi tác vụ...
    } catch (error) {
      this.logger.error('Lỗi khi đồng bộ định kỳ:', error);
    } finally {
      this.isRunning = false;
    }
  }
}
```

---

## 4. Tích Hợp 3rd-Party Services An Toàn (Resilience Patterns)

### 4.1. Timeout & Retry Cơ Chế Exponential Backoff (Axios / HttpModule)

Tuyệt đối không gọi 3rd party mà không có `timeout`. Sử dụng `HttpService` kèm retry:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { AxiosError } from 'axios';

@Injectable()
export class ThirdPartyClient {
  private readonly logger = new Logger(ThirdPartyClient.name);

  constructor(private readonly httpService: HttpService) {}

  async callApiWithRetry<T>(url: string, data: any, maxRetries = 3): Promise<T> {
    let attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        const response = await firstValueFrom(
          this.httpService.post<T>(url, data, {
            timeout: 10000, // Timeout cứng 10s
            headers: { 'Content-Type': 'application/json' },
          }),
        );
        return response.data;
      } catch (err) {
        const error = err as AxiosError;
        this.logger.warn(`Lần gọi ${attempt}/${maxRetries} thất bại: ${error.message}`);

        if (attempt >= maxRetries) {
          this.logger.error(`Đã vượt quá số lần thử lại cho URL: ${url}`);
          throw error;
        }

        // Chờ exponential backoff trước khi thử lại
        const delayMs = Math.pow(2, attempt) * 1000;
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }

    throw new Error('Unexpected retry loop exit');
  }
}
```

### 4.2. Xử Lý Webhook An Toàn (Signature + Idempotency)

Quy chuẩn tiếp nhận Webhook từ bên ngoài (Stripe, cổng thanh toán, CRM):

1. **Kiểm tra Raw Body & Chữ ký HMAC**:
```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';

@Injectable()
export class WebhookSecurityService {
  verifySignature(rawBody: string, signature: string, secret: string): boolean {
    const expected = crypto
      .createHmac('sha256', secret)
      .update(rawBody, 'utf8')
      .digest('hex');

    const isValid = crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expected),
    );

    if (!isValid) {
      throw new UnauthorizedException('Chữ ký Webhook không hợp lệ.');
    }
    return true;
  }
}
```

2. **Cơ chế Idempotency**: Đẩy ngay Webhook payload vào BullMQ với `jobId` là `event_id` của 3rd-party. BullMQ sẽ tự động từ chối nếu nhận lại cùng 1 event ID trong thời gian lưu trữ.

---

## 5. Docker Compose Chuẩn Triển Khai (NestJS + Redis + PostgreSQL)

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: nestjs-api
    restart: unless-stopped
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - DATABASE_URL=postgresql://user:secret@postgres:5432/app_db?schema=public
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    container_name: nestjs-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass redis_password
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 3s
      retries: 5

  postgres:
    image: postgres:16-alpine
    container_name: nestjs-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: app_db
    ports:
      - '5432:5432'
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U user -d app_db']
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  redis_data:
  pg_data:
```

---

## 6. Red Flags - Cần Tránh Tuyệt Đối

| Vi phạm | Hậu quả | Chuẩn sửa chữa |
| :--- | :--- | :--- |
| Dùng `setTimeout` / `setInterval` cho background task | Memory leak, mất task khi restart service | Dùng **BullMQ** lưu trạng thái trên Redis |
| Gọi 3rd party API không có `timeout` | Worker bị lock vô thời hạn khi 3rd party sập | Bắt buộc `timeout: 5000` đến `10000ms` |
| Xử lý trực tiếp webhook nặng trong Controller | Client ngoài timeout (gây retry liên tục) | Return `200 OK` ngay, đẩy payload vào Queue |
| Không bắt exception trong CronJob | Cron crash làm sập toàn bộ tiến trình | Luôn bọc thân hàm `@Cron` trong `try/catch` |

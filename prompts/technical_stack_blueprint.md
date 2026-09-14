# Technical Stack Blueprint & Architecture Standard

Tài liệu đặc tả kỹ thuật và Prompt mẫu chuẩn hóa công nghệ dành cho toàn bộ các dự án mới trong hệ sinh thái.

---

## 1. Công Nghệ Chuẩn Hóa (Standard Tech Stack)

| Lớp (Layer) | Công nghệ | Phiên bản khuyến nghị | Vai trò & Quy chuẩn |
|---|---|---|---|
| **Backend API** | **NestJS** | v10.x+ | Modular Architecture, Controller-Service-Repository Pattern, Dependency Injection, DTOs với `class-validator` |
| **Frontend Web** | **Next.js** | v14.x+ / App Router | React Server Components (RSC), Server Actions, Tailwind CSS, Shadcn UI, Zod schema validation |
| **ORM / Database** | **Prisma + PostgreSQL** | Prisma v5.x+, PostgreSQL 16-alpine | Schema migrations an toàn, Indexing tối ưu, Connection Pooling |
| **Cache & Session** | **Redis** | Redis 7-alpine | In-memory caching, Token blocklist, Rate limiting, Distributed Locks |
| **Shared Libs** | **TypeScript Monorepo** | TS 5.x+ | Chia sẻ types, DTOs, interfaces chung qua `packages/shared` hoặc `src/shared` |
| **Infrastructure** | **Docker Compose** | Compose v3.14+ | Multi-stage build (`development`, `production`), Healthcheck đầy đủ cho mọi service, Network bridge isolation |

---

## 2. Cấu Trúc Monorepo Chuẩn (Standard Directory Layout)

```
├── .agents/
│   └── skills/                # Skills chuyên biệt cho dự án
├── apps/
│   ├── api/                   # NestJS Backend Application
│   │   ├── src/
│   │   │   ├── modules/       # Feature Modules (auth, users, items...)
│   │   │   ├── common/        # Filters, Interceptors, Guards, Decorators
│   │   │   ├── prisma/        # Prisma Service & Client Module
│   │   │   └── main.ts
│   │   ├── prisma/
│   │   │   ├── schema.prisma  # Database schema
│   │   │   └── migrations/
│   │   ├── test/              # E2E test suites
│   │   ├── Dockerfile
│   │   └── package.json
│   └── web/                   # Next.js Frontend Application
│       ├── src/
│       │   ├── app/           # App Router (layout, page, api routes)
│       │   ├── components/    # UI Components (Shadcn UI, Custom)
│       │   ├── hooks/         # Custom React Hooks
│       │   ├── lib/           # Utils, API client fetcher
│       │   └── types/         # Frontend Types
│       ├── Dockerfile
│       └── package.json
├── packages/
│   └── shared/                # Shared Types, DTOs, Constants
├── docker-compose.yml         # Dev/Local orchestration
├── docker-compose.prod.yml    # Production override
├── .env.example               # Mẫu biến môi trường
├── .gitignore                 # Chặn file nhạy cảm
├── GEMINI.md                  # Quy tắc AI Agent cốt lõi
├── readme.md                  # Tổng quan dự án (File 1/2)
└── guide.md                   # Hướng dẫn commands, deploy, debug (File 2/2)
```

---

## 3. Best Practices & Coding Standards

### 3.1. NestJS Backend Best Practices
- **DTO Validation**: Mọi Request body/query phải có DTO class với decorator validation (`@IsString()`, `@IsNotEmpty()`, `@IsEmail()`, etc.).
- **Response Standard**: Thống nhất cấu trúc trả về: `{ success: true, data: ..., message?: string }`.
- **Exception Filters**: Bắt toàn bộ lỗi qua Global `HttpExceptionFilter`, không để lộ stack trace ra client.
- **Prisma Transactions**: Sử dụng `$transaction` cho các thao tác ghi dữ liệu đa bảng để đảm bảo ACID.
- **Cache Strategy**: Sử dụng Redis cache cho các endpoint đọc dữ liệu thường xuyên, invalidate cache khi có sự kiện ghi/cập nhật.

### 3.2. Next.js Frontend Best Practices
- **App Router**: Tận dụng tối đa Server Components để render tĩnh/SSR trước khi gửi về client; chỉ dùng `'use client'` khi cần state, effects hoặc event handlers.
- **Form Handling**: Kết hợp `react-hook-form` + `@hookform/resolvers/zod` + `zod` để validate form 2 phía (Client & Server).
- **UI Components**: Chuẩn hóa styling bằng Tailwind CSS và các primitive components của Radix UI / Shadcn.
- **API Fetching**: Đóng gói trong lib `api-client` xử lý tự động đính kèm `Bearer token`, refresh token khi 401, và timeout an toàn.

### 3.3. Docker Compose & Environment
- **Healthcheck**: Mọi service cơ sở dữ liệu và API bắt buộc phải có `healthcheck` để đảm bảo thứ tự khởi động phụ thuộc (`condition: service_healthy`).
- **Data Persistence**: Toàn bộ dữ liệu PostgreSQL và Redis phải gắn vào Named Volumes.
- **Secrets Management**: Tuyệt đối không hardcode passwords/tokens trong code; sử dụng cú pháp `${VAR_NAME:?Required}` trong compose file.

---

## 4. Prompt Mẫu Khởi Chạy Dự Án Mới Theo Plan (Project Execution Prompt)

```markdown
### 📋 PROMPT KHỞI CHẠY DỰ ÁN MỚI TỪ PLAN:

Bạn là Senior Fullstack & DevOps Engineer. Hãy đọc kỹ file `plan.md` của dự án và triển khai toàn bộ hệ thống theo đúng **Technical Stack Blueprint**:
- **Backend**: NestJS v10+ (Modular architecture, DTO validation, Prisma ORM, Redis caching, Global Exception Filter).
- **Frontend**: Next.js v14+ (App Router, Server Components, Tailwind CSS, Shadcn UI, Zod validation).
- **Database & Infra**: PostgreSQL 16, Redis 7, Docker Compose (v3.14 với đầy đủ Healthchecks & Named Volumes).
- **Quy trình triển khai**:
  1. Khởi tạo cấu trúc Monorepo (`apps/api`, `apps/web`, `packages/shared`).
  2. Thiết kế `schema.prisma` và khởi tạo migration.
  3. Xây dựng toàn bộ Backend APIs, DTOs, Services, Guards, Tests.
  4. Xây dựng giao diện Frontend Next.js kết nối trực tiếp với Backend APIs.
  5. Cấu hình `docker-compose.yml` để khởi chạy toàn bộ stack bằng 1 lệnh `docker compose up -d`.
  6. Viết đầy đủ `readme.md` (tổng quan dự án) và `guide.md` (hướng dẫn chạy lệnh, deploy, debug).
```

# Base Agents - Central AI Rules, Skills & Architecture Standard

Kho lưu trữ và phân phối tập trung toàn bộ **Global Rules**, **Skills**, **MCP Integrations (CodeGraph & Obsidian)** và **Technical Stack Blueprint** (NestJS + Next.js + Prisma + PostgreSQL + Redis + Docker Compose) cho toàn bộ các dự án trong hệ thống.

---

## 1. Mục Tiêu & Triết Lý Vận Hành
- **1-Command Setup**: Chỉ cần 1 lệnh script (`./install.sh`) để trang bị đầy đủ bộ não AI, MCP Tools và quy chuẩn dự án.
- **Quy Chuẩn Kỹ Sư 10 Năm Kinh Nghiệm**: Giao tiếp Tiếng Việt súc tích, logic & evidence-based, tuyệt đối an toàn dữ liệu.
- **Workflow Thực Thi Theo Plan**: Kéo repo về ➔ Thả file `plan.md` ➔ AI Agent tự động triển khai từ A - Z theo đúng kiến trúc chuẩn.

---

## 2. Cấu Trúc Repository

```
├── GEMINI.md                          # 6 Quy tắc cốt lõi & Persona Senior Fullstack/DevOps
├── install.sh                         # Script cài đặt 1 chạm (Global / Project)
├── .gitignore                         # Chặn rò rỉ .env, credentials, secrets
├── readme.md                          # Tổng quan dự án & Cấu trúc (File 1/2)
├── guide.md                           # Hướng dẫn chạy lệnh, deploy, workflow (File 2/2)
├── prompts/
│   └── technical_stack_blueprint.md   # Prompt mẫu & Đặc tả Tech Stack chuẩn
├── skills/                            # Kho kỹ năng chuyên biệt
│   ├── multi-agent-orchestrator/      # Điều phối 5 Subagents (PO, Architect, Dev, Tester, DevOps)
│   ├── docker-compose-creator/        # Thiết kế và vận hành Docker Compose
│   ├── ui-ux-pro-max/                 # Thiết kế UI/UX & Responsive layout
│   ├── design-system/                 # Xây dựng Design Tokens & Component Library
│   ├── ui-styling/                    # Styling nâng cao với Tailwind CSS
│   ├── brand/                         # Định hướng nhận diện thương hiệu
│   ├── slides/                        # Trình bày slide báo cáo kỹ thuật
│   └── banner-design/                 # Thiết kế banner đồ họa
└── templates/
    └── monorepo-starter/              # Khung sườn mẫu NestJS + Next.js + Prisma + Docker Compose
```

---

## 3. Danh Mục Kỹ Năng Tích Hợp (Skills Ecosystem)

1. **`multi-agent-orchestrator`**: Vận hành 5 Subagents với 2 Human-in-the-loop Gates và cơ chế tự sửa lỗi tối đa 3 vòng lặp.
2. **`docker-compose-creator`**: Chuẩn hóa orchestration đa container, volume persistence, isolated network và healthchecks.
3. **`ui-ux-pro-max` & `design-system`**: Bộ kỹ năng thiết kế giao diện, trải nghiệm người dùng, component library hiện đại.
4. **`ui-styling` & `brand`**: Quy chuẩn màu sắc, font, khoảng cách và phong cách thương hiệu.

---

## 4. Stack Công Nghệ Chuẩn Cho Mọi Dự Án
- **Backend API**: NestJS v10+ (Clean Architecture, DTO Validation, Global Exception Filters).
- **Frontend Web**: Next.js v14+ (App Router, Server Components, Tailwind CSS, Shadcn UI, Zod).
- **Database & Cache**: PostgreSQL 16-alpine + Prisma ORM + Redis 7-alpine.
- **Orchestration**: Docker Compose v3.14+ (100% Docker-first workflow).

# Base Agents - Central AI Rules, Skills & Architecture Standard

Kho lưu trữ và phân phối tập trung toàn bộ **Global Rules**, **Skills**, **MCP Integrations (CodeGraph & Obsidian)** và **Technical Stack Blueprint** (NestJS + Next.js + Prisma + PostgreSQL + Redis + Docker Compose) cho toàn bộ các dự án trong hệ thống.

---

## 1. Mục Tiêu & Triết Lý Vận Hành
- **1-Command Setup**: Chỉ cần 1 lệnh script (`./install.sh`) để trang bị đầy đủ bộ não AI, MCP Tools và quy chuẩn dự án.
- **Hỗ Trợ Đa Nền Tảng**: Vận hành trơn tru trên **macOS** lẫn **Linux VPS (CentOS 9, Amazon Linux ec2-user, Ubuntu)**.
- **Quy Chuẩn Kỹ Sư 10 Năm Kinh Nghiệm**: Giao tiếp Tiếng Việt súc tích, logic & evidence-based, an toàn dữ liệu tuyệt đối.
- **Workflow Thực Thi Theo Plan**: Kéo repo về ➔ Thả file `plan.md` ➔ AI Agent tự động triển khai từ A - Z theo đúng kiến trúc chuẩn.

---

## 2. Cấu Trúc Repository

```
├── GEMINI.md                          # 6 Quy tắc cốt lõi & Persona Senior Fullstack/DevOps
├── install.sh                         # Universal 1-Click Installer (macOS & CentOS 9/ec2-user)
├── .gitignore                         # Chặn rò rỉ .env, credentials, secrets
├── readme.md                          # Tổng quan dự án & Cấu trúc (File 1/2)
├── guide.md                           # Hướng dẫn chạy lệnh, deploy, workflow (File 2/2)
├── prompts/
│   └── technical_stack_blueprint.md   # Prompt mẫu & Đặc tả Tech Stack chuẩn
├── skills/                            # Kho 14 Kỹ năng chuyên biệt
│   ├── multi-agent-orchestrator/      # Điều phối 5 Subagents (PO, Architect, Dev, Tester, DevOps)
│   ├── google-apps-script-expert/     # Tự động hóa Google Sheets, Forms, Gmail, Clasp & Webhook
│   ├── wordpress-php-debugger/        # Debug lỗi WSOD, tối ưu PHP-FPM pool, WP-CLI, Redis cache
│   ├── nginx-server-pro/              # Reverse proxy, FastCGI cache, SSL/Certbot, WebSocket, Rate limit
│   ├── vps-devops-master/             # Quản trị VPS, Security hardening, Firewalld, Fail2ban, Systemd
│   ├── website-builder-pro/           # Tối ưu Core Web Vitals (100/100), SEO on-page, Sitemap, Schema
│   ├── docker-compose-creator/        # Thiết kế và vận hành Docker Compose đa container
│   ├── ui-ux-pro-max/                 # Thiết kế UI/UX & Responsive layout
│   ├── design-system/                 # Xây dựng Design Tokens & Component Library
│   ├── ui-styling/                    # Styling nâng cao với Tailwind CSS & Shadcn UI
│   ├── brand/                         # Định hướng nhận diện thương hiệu
│   ├── slides/                        # Trình bày slide báo cáo kỹ thuật
│   ├── design/                        # Thiết kế tổng thể & Branding assets
│   └── banner-design/                 # Thiết kế banner đồ họa
└── templates/
    └── monorepo-starter/              # Khung sườn mẫu NestJS + Next.js + Prisma + Postgres 16 + Redis 7
```

---

## 3. Danh Mục Kỹ Năng Tích Hợp (Skills Ecosystem)

1. **`multi-agent-orchestrator`**: Vận hành 5 Subagents với 2 Human-in-the-loop Gates và cơ chế tự sửa lỗi tối đa 3 vòng lặp.
2. **`google-apps-script-expert`**: Tối ưu batch operations trên Google Sheets, deploy bằng clasp, webhook endpoint an toàn.
3. **`wordpress-php-debugger`**: Xử lý lỗi trắng trang (WSOD), tính toán `pm.max_children` chuẩn theo RAM VPS, điều khiển qua `wp-cli`.
4. **`nginx-server-pro`**: Cấu hình reverse proxy cho Node.js/Next.js, FastCGI micro-caching cho PHP-FPM, SSL Certbot và WebSocket.
5. **`vps-devops-master`**: Security hardening SSH/Firewalld/Fail2ban, Systemd services, swap file, script backup tự động.
6. **`website-builder-pro`**: Tối ưu điểm Google PageSpeed (LCP, CLS, INP), cấu trúc JSON-LD SEO, sitemap.
7. **`docker-compose-creator`**: Chuẩn hóa orchestration đa container, volume persistence, isolated network và healthchecks.
8. **Bộ kỹ năng UI/UX & Design**: `ui-ux-pro-max`, `design-system`, `ui-styling`, `brand`, `slides`, `design`, `banner-design`.

---

## 4. Stack Công Nghệ Chuẩn Cho Mọi Dự Án
- **Backend API**: NestJS v10+ (Clean Architecture, DTO Validation, Global Exception Filters).
- **Frontend Web**: Next.js v14+ (App Router, Server Components, Tailwind CSS, Shadcn UI, Zod).
- **Database & Cache**: PostgreSQL 16-alpine + Prisma ORM + Redis 7-alpine.
- **Orchestration**: Docker Compose v3.14+ (100% Docker-first workflow).

# Base Agents - Central AI Rules, Skills & Architecture Standard

Kho lưu trữ và phân phối tập trung toàn bộ **Global Rules**, **Skills**, **MCP Integrations (CodeGraph & Obsidian)** và **Technical Stack Blueprint** (NestJS + Next.js + Prisma + PostgreSQL + Redis + Docker Compose) cho toàn bộ các dự án trong hệ thống.

---

> [!IMPORTANT]
> ### ⚡ Hướng Dẫn Sử Dụng Nhanh (Quick Setup Cheatsheet)
>
> #### 1. Cài Đặt Toàn Cục (Global - Máy cá nhân macOS / Linux)
> Áp dụng bộ não AI, Rules, MCP (CodeGraph, Obsidian) và 15 Skills cho toàn bộ các dự án trên máy:
> ```bash
> git clone git@github-kyhuuhai:kyhuuhai/base_agents.git ~/base_agents && cd ~/base_agents
> chmod +x install.sh && ./install.sh --global
> ```
>
> #### 2. Cài Đặt Cục Bộ Cho 1 Dự Án Cụ Thể (Project-Level)
> Bơm trực tiếp `GEMINI.md`, thư mục `.agents/skills` và `specs/` vào thư mục dự án mục tiêu:
> ```bash
> /path/to/base_agents/install.sh --project /path/to/my-project
> ```
>
> #### 3. Triển Khai Trên VPS Mới (Clean Server: CentOS 9, ec2-user, Ubuntu)
> Script tự nhận diện OS, tự cài Node.js 20 LTS, CodeGraph CLI, tạo Obsidian Headless Vault và nạp cấu hình:
> ```bash
> git clone git@github-kyhuuhai:kyhuuhai/base_agents.git ~/base_agents && cd ~/base_agents
> chmod +x install.sh && ./install.sh --global
> ```
>
> #### 4. Cập Nhật Trên VPS Cũ (Đã có sẵn môi trường và dự án đang chạy)
> Cập nhật rules/skills mới nhất mà không làm ảnh hưởng đến dữ liệu hay database:
> ```bash
> cd ~/base_agents && git pull origin main
> ./install.sh --global
> # (Tùy chọn) Đồng bộ lại vào thư mục dự án đang chạy trên VPS:
> ./install.sh --project /path/to/running-project
> ```
>
> #### 5. Kích Hoạt Nhanh Trong Chat Với AI
> - Gõ **`!team <yêu cầu>`** (ví dụ: `!team phát triển tính năng Auth SSO`) để tự động kích hoạt chuỗi 5 Subagents.
> - Hoặc tạo file `plan.md` ở root dự án và nhắn: *"Thực thi theo plan.md"*.

---

## 1. Mục Tiêu & Triết Lý Vận Hành
- **1-Command Setup**: Chỉ cần 1 lệnh script (`./install.sh`) để trang bị đầy đủ bộ não AI, MCP Tools và quy chuẩn dự án.
- **Hỗ Trợ Đa Nền Tảng**: Vận hành trơn tru trên **macOS** lẫn **Linux VPS (CentOS 9, Amazon Linux ec2-user, Ubuntu)**.
- **Quy Chuẩn Kỹ Sư 10 Năm Kinh Nghiệm**: Giao tiếp Tiếng Việt súc tích, logic & evidence-based, an toàn dữ liệu tuyệt đối.
- **Workflow Thực Thi Theo Plan**: Kéo repo về ➔ Thả file `plan.md` ➔ AI Agent tự động triển khai từ A - Z theo đúng kiến trúc chuẩn.

---

## 2. Cấu Trúc Repository

```
├── GEMINI.md                          # 7 Quy tắc cốt lõi, Persona & Quy chuẩn Skills
├── install.sh                         # Universal 1-Click Installer (macOS & CentOS 9/ec2-user)
├── .gitignore                         # Chặn rò rỉ .env, credentials, secrets
├── readme.md                          # Tổng quan dự án & Cấu trúc (File 1/2)
├── guide.md                           # Hướng dẫn chạy lệnh, deploy, workflow (File 2/2)

├── prompts/
│   └── technical_stack_blueprint.md   # Prompt mẫu & Đặc tả Tech Stack chuẩn
├── skills/                            # Kho 15 Kỹ năng chuyên biệt
│   ├── multi-agent-orchestrator/      # Điều phối 5 Subagents (PO, Architect, Dev, Tester, DevOps)
│   ├── fullstack-smoke-verifier/      # Kiểm thử E2E Playwright, Auth Route Guard, Zero-Hardcode, Responsive
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

1. **`multi-agent-orchestrator`**: Vận hành 5 Subagents với 2 Human-in-the-loop Gates, CodeGraph, Obsidian Vault và cơ chế tự sửa lỗi tối đa 3 vòng lặp.
2. **`fullstack-smoke-verifier`**: Kiểm thử tích hợp thực chiến Playwright (Route Guard Auth redirect, Zero-Hardcode `localhost:4000`, 3-Viewport Mobile/Tablet/Desktop).
3. **`google-apps-script-expert`**: Tối ưu batch operations trên Google Sheets, deploy bằng clasp, webhook endpoint an toàn.
4. **`wordpress-php-debugger`**: Xử lý lỗi trắng trang (WSOD), tính toán `pm.max_children` chuẩn theo RAM VPS, điều khiển qua `wp-cli`.
5. **`nginx-server-pro`**: Cấu hình reverse proxy cho Node.js/Next.js, FastCGI micro-caching cho PHP-FPM, SSL Certbot và WebSocket.
6. **`vps-devops-master`**: Security hardening SSH/Firewalld/Fail2ban, Systemd services, swap file, script backup tự động.
7. **`website-builder-pro`**: Tối ưu điểm Google PageSpeed (LCP, CLS, INP), cấu trúc JSON-LD SEO, sitemap.
8. **`docker-compose-creator`**: Chuẩn hóa orchestration đa container, volume persistence, isolated network và healthchecks.
9. **Bộ kỹ năng UI/UX & Design**: `ui-ux-pro-max`, `design-system`, `ui-styling`, `brand`, `slides`, `design`, `banner-design`.


---

## 4. Stack Công Nghệ Chuẩn Cho Mọi Dự Án
- **Backend API**: NestJS v10+ (Clean Architecture, DTO Validation, Global Exception Filters).
- **Frontend Web**: Next.js v14+ (App Router, Server Components, Tailwind CSS, Shadcn UI, Zod).
- **Database & Cache**: PostgreSQL 16-alpine + Prisma ORM + Redis 7-alpine.
- **Orchestration**: Docker Compose v3.14+ (100% Docker-first workflow).

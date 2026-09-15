# Guide: Cài Đặt, Vận Hành & Khởi Tạo Dự Án Mới Từ Plan

Hướng dẫn chi tiết quy trình cài đặt 1 chạm (`install.sh`), triển khai trên **macOS** và **VPS Linux (CentOS 9, Amazon Linux ec2-user, Ubuntu)**, tích hợp MCP Tools (CodeGraph, Obsidian), và quy trình khởi tạo dự án mới từ `plan.md`.

---

## 1. Cài Đặt 1 Chạm Với `install.sh`

Script `install.sh` hỗ trợ tự động nhận diện OS, tự cài đặt/cấu hình **Node.js**, **CodeGraph CLI**, **Obsidian MCP Server** và **Global Rules/Skills**.

### 1.1. Cài đặt trên macOS (Local Machine)
```bash
# Cài đặt toàn cục (Global)
./install.sh --global

# Hoặc cài đặt cục bộ cho 1 dự án
./install.sh --project /path/to/my-project
```

### 1.2. Cài đặt trên VPS Linux (CentOS 9, Amazon Linux / `ec2-user`, Ubuntu)
Trên VPS không có giao diện đồ họa (headless server):
```bash
# 1. Clone repository về VPS:
git clone git@github-kyhuuhai:kyhuuhai/base_agents.git base_agents
cd base_agents

# 2. Cấp quyền thực thi và chạy cài đặt toàn cục:
chmod +x ./install.sh
./install.sh --global
```

> [!NOTE]
> **Cơ chế hoạt động trên VPS Linux**:
> 1. **Node.js & npx**: Script tự động cài Node.js 20 LTS qua `dnf`/`yum` hoặc `nvm` nếu máy chưa có.
> 2. **CodeGraph CLI**: Tự động tải binary từ `https://codegraph.dev/install.sh` và gắn link vào `$HOME/.local/bin/codegraph` cùng `$PATH`.
> 3. **Obsidian trên VPS**: Bản chất Obsidian Vault là một thư mục Markdown (`$HOME/obsidian_vault`). MCP Server sử dụng `@modelcontextprotocol/server-filesystem` chạy qua `npx` dạng headless 100%, không cần cài app Obsidian Desktop GUI. Bạn có thể đồng bộ vault giữa máy cá nhân và VPS qua Git!

---

## 2. Quy Trình Khởi Tạo & Triển Khai Dự Án Mới Từ `plan.md`

### Bước 1: Khởi tạo thư mục dự án mới
```bash
mkdir -p /path/to/my-new-project
cd /path/to/my-new-project
git init
```

### Bước 2: Đồng bộ Base Agents & Template
```bash
# Cài đặt rules và skills từ base_agents vào dự án:
/path/to/base_agents/install.sh --project .

# (Tùy chọn) Copy khung Starter Monorepo nếu dựng dự án từ đầu:
cp -R /path/to/base_agents/templates/monorepo-starter/* .
cp /path/to/base_agents/templates/monorepo-starter/.env.example .env
```

### Bước 3: Đưa `plan.md` vào dự án và Kích hoạt AI Agent
Tạo file `plan.md` mô tả các yêu cầu nghiệp vụ của dự án tại root, sau đó gửi prompt cho Agent:
```markdown
Hãy đọc file plan.md và tiến hành phát triển toàn bộ dự án theo đúng Technical Stack Blueprint:
- Backend NestJS v10+ (Modular, Prisma ORM, Redis, DTO validation)
- Frontend Next.js v14+ (App Router, Tailwind CSS, Shadcn UI)
- PostgreSQL 16 + Redis 7 + Docker Compose
- Tuân thủ quy trình Multi-Agent Orchestration (PO -> Architect -> Dev -> QA -> Security).
```

---

## 3. Quản Lý MCP Tools (CodeGraph & Obsidian)

### 3.1. Index Codebase Với CodeGraph
Mỗi khi khởi tạo hoặc cập nhật lớn mã nguồn dự án:
```bash
cd /path/to/project
codegraph index
```
AI Agent sẽ tự động phát hiện thư mục `.codegraph/` và ưu tiên gọi MCP `codegraph_explore` để tra cứu call graph và symbols.

### 3.2. Quản Lý Tài Liệu Theo Mô Hình Local-First (Docs-as-Code)
- **Tài liệu từng dự án**: Được Agent lưu trữ trực tiếp trong thư mục `specs/` của repository (ví dụ: `specs/architecture.md`, `specs/SPEC-1-auth.md`).
- **Xem trên Obsidian Desktop**: Không cần cài đặt gì trên VPS, trên máy cá nhân chỉ cần mở Obsidian Desktop chọn **"Open folder as vault"** trỏ thẳng vào thư mục dự án để xem Knowledge Graph và Alert Callouts độc lập.
- **Global Vault (Tùy chọn)**: Dành cho ghi chú cá nhân toàn cục (`~/Documents/Obsidian Vault` hoặc `~/obsidian_vault` trên VPS) thông qua MCP Server lưu tại `~/.gemini/config/mcp_config.json`.


---

## 4. Quy Chuẩn Đồng Bộ Git Lên GitHub

```bash
cd /Users/krylot/Documents/Projects/agent
git add .
git commit -m "feat: upgrade universal installer for CentOS 9, ec2-user and macOS"
git push origin main
```

---

## 5. Xử Lý Sự Cố (Troubleshooting)

- **AI Agent không nhận Rules**:
  - Đảm bảo `~/.gemini/config/GEMINI.md` hoặc `GEMINI.md` ở root dự án tồn tại.
  - Khởi động lại IDE / Agent session để tải lại ngữ cảnh.
- **CodeGraph báo `command not found` sau khi cài đặt**:
  - Chạy `source ~/.bashrc` (hoặc `source ~/.zshrc`) để cập nhật `$PATH` chứa `~/.local/bin`.
- **Lỗi permission khi chạy `install.sh`**:
  ```bash
  chmod +x ./install.sh
  ```

# Guide: Cài Đặt, Vận Hành & Khởi Tạo Dự Án Mới Từ Plan

Hướng dẫn chi tiết quy trình cài đặt 1 chạm (`install.sh`), tích hợp MCP Tools, và quy trình khởi tạo dự án mới từ `plan.md`.

---

## 1. Cài Đặt 1 Chạm Với `install.sh`

### 1.1. Cài đặt Toàn Cục Cho Máy (Machine-level Global Setup)
Áp dụng Rules, Skills và cấu hình MCP tự động cho tất cả các dự án mở trên máy:
```bash
./install.sh --global
```
- Tự động copy `GEMINI.md` vào `~/.gemini/config/GEMINI.md`.
- Cài đặt toàn bộ 8 skills vào `~/.gemini/config/skills/`.
- Tự động quét và cấu hình MCP CodeGraph & Obsidian Vault vào `~/.gemini/config/mcp_config.json`.

### 1.2. Cài đặt Cục Bộ Cho 1 Dự Án Cụ Thể (Project-level Setup)
Đồng bộ rules và skills trực tiếp vào thư mục dự án mới:
```bash
./install.sh --project /path/to/your-new-project
```

---

## 2. Quy Trình Khởi Tạo & Triển Khai Dự Án Mới Từ `plan.md`

Khi bắt đầu một dự án mới:

### Bước 1: Chuẩn bị thư mục dự án
```bash
mkdir -p /path/to/my-new-project
cd /path/to/my-new-project
git init
```

### Bước 2: Đồng bộ Base Agents & Template
```bash
# Cài đặt rules và skills từ base_agents
/Users/krylot/Documents/Projects/agent/install.sh --project .

# (Tùy chọn) Khởi tạo khung Starter Monorepo nếu làm dự án mới từ đầu
cp -R /Users/krylot/Documents/Projects/agent/templates/monorepo-starter/* .
cp /Users/krylot/Documents/Projects/agent/templates/monorepo-starter/.env.example .env
```

### Bước 3: Đưa `plan.md` vào dự án và Kích hoạt AI Agent
Tạo file `plan.md` chứa đặc tả nghiệp vụ của dự án tại root, sau đó gửi prompt cho Agent:
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
AI Agent sẽ tự động ưu tiên gọi MCP `codegraph_explore` để hiểu kiến trúc và dynamic call paths.

### 3.2. Cấu hình Obsidian Vault
Đường dẫn Vault mặc định: `/Users/krylot/Documents/Obsidian Vault`.
Để thay đổi đường dẫn Vault, cập nhật trực tiếp tại `~/.gemini/config/mcp_config.json`:
```json
{
  "mcpServers": {
    "obsidian": {
      "command": "/usr/local/bin/npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/DUONG_DAN_MOI/Obsidian Vault"
      ]
    }
  }
}
```

---

## 4. Quy Chuẩn Đồng Bộ Git & Đẩy Lên GitHub

Đồng bộ các cập nhật của `base_agents` lên GitHub repository:
```bash
cd /Users/krylot/Documents/Projects/agent
git add .
git commit -m "feat: setup base_agents with rules, skills, MCP, and starter template"
git branch -M main
git push -u origin main
```

---

## 5. Xử Lý Sự Cố (Troubleshooting)

- **AI Agent không nhận Rules**:
  - Đảm bảo `~/.gemini/config/GEMINI.md` hoặc `GEMINI.md` ở root dự án tồn tại.
  - Mở lại IDE / Workspace để reload context.
- **Lỗi permission khi chạy `install.sh`**:
  ```bash
  chmod +x ./install.sh
  ```
- **Lỗi Docker port collision**:
  - Kiểm tra các container đang chạy: `docker ps`.
  - Thay đổi port mapping trong `.env` hoặc `docker-compose.yml`.

---
name: multi-agent-orchestrator
description: Coordinate and orchestrate 5 specialized subagents (Product Owner, System Architect, Fullstack Developer, QA Tester, Security & DevOps) with 2 human-in-the-loop approval gates, CodeGraph code intelligence, automated Obsidian documentation, and 3-retry loop control. Triggered with keyword '!team' or 'plan.md'.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Codegraph
  - Obsidian
metadata:
  version: 1.1.0
---

# Multi-Agent Orchestration System

Hệ thống phối hợp đa tác tử (Multi-Agent Orchestration) chuẩn hóa quy trình phát triển tính năng từ bài toán nghiệp vụ, thiết kế kiến trúc, triển khai code, kiểm thử tự động, cho đến audit bảo mật.

> [!IMPORTANT]
> **Trigger kích hoạt**: Lệnh bắt đầu bằng `!team` (ví dụ: `!team thêm tính năng SSO`) hoặc khi người dùng yêu cầu thực thi theo `plan.md`.

---

## 1. Cơ Cấu 5 Subagents & Bảng Phân Quyền

```
[User Request / Plan / !team]
      │
      ▼
┌──────────────┐
│  1. PO Agent │ ◄─── Khai thác nghiệp vụ, lập Acceptance Criteria (AC)
└──────┬───────┘
       │  [GATE 1: User Sign-off Spec]
       ▼
┌──────────────┐
│ 2. Architect │ ◄─── Thiết kế DB Schema (Prisma), API Contract, Data Flow
└──────┬───────┘
       ▼
┌──────────────┐
│ 3. Fullstack │ ◄─── Lập Plan ───► [GATE 2: User Sign-off Plan]
│     Dev      │ ◄─── Code tuần tự: apps/api (NestJS) ➔ apps/web (Next.js)
└──────┬───────┘
       ▼
┌──────────────┐
│ 4. QA/Tester │ ◄─── Chạy Fullstack Smoke Verifier (Auth, Network, Viewport - Max 3 retries)
└──────┬───────┘
       │ [All Smoke Tests Passed]
       ▼
┌──────────────┐
│ 5. Security  │ ◄─── Audit OWASP, Data Safety, Docker & Envs (Max 3 retries)
│   & DevOps   │
└──────┬───────┘
       │ [All Security Passed]
       ▼
[Cập nhật readme.md / guide.md & Xuất tài liệu specs/ & Bàn giao]
```

| Subagent | Tên định danh | Vai trò & Trọng tâm | Tools được phép | Môi trường |
|---|---|---|---|---|
| **PO Agent** | `po-agent` | Làm rõ yêu cầu, phân tích nghiệp vụ, viết User Stories & AC | Read, Grep, Codegraph, Ask Question | Session Chat / Specs Artifact |
| **Architect Agent** | `architect-agent` | Thiết kế Prisma Schema, API DTOs, luồng dữ liệu, Monorepo | Read, Write, Grep, Codegraph | Session Chat / `specs/` |
| **Fullstack Dev Agent** | `fullstack-dev-agent` | Lập Implementation Plan, viết code tuần tự API -> Web | Read, Write, Edit, Codegraph, Command | Monorepo Workspace |
| **QA / Tester Agent** | `tester-agent` | Kích hoạt skill `fullstack-smoke-verifier`: Chạy 3 Smoke Tests (Auth Guard, Zero-Hardcode, Viewport) | Read, Write, Edit, Command (Docker exec / Playwright) | Docker Compose / Headless Browser |
| **Security & DevOps Agent** | `security-devops-agent` | Audit bảo mật, an toàn dữ liệu, verify Docker & env | Read, Write, Grep, Command | Docker / Local Environment |

---

## 2. Bộ Quy Tắc Bắt Buộc Trong Multi-Agent Workflow

### 2.1. Luôn Sử Dụng CodeGraph (Deep Code Intelligence)
- Mọi Subagent (PO, Architect, Developer, Tester, Security) trước khi phân tích hoặc chỉnh sửa file BẮT BUỘC phải dùng CodeGraph (`codegraph_explore` MCP hoặc CLI `codegraph explore "<query>"`) nếu repo có `.codegraph/`.
- **Đồng bộ sau khi code**: Sau khi Fullstack Developer hoàn thành việc thêm/sửa file mã nguồn (Source Code), BẮT BUỘC chạy `codegraph sync` để cập nhật lại Graph cho Tester, Security và các phiên làm việc tiếp theo.

### 2.2. Tự Động Xuất Bản Tài Liệu Chuẩn Obsidian (Local-First Docs-as-Code)
- **Lưu trực tiếp trong dự án (`specs/`)**: Toàn bộ tài liệu kiến trúc, spec tính năng và runbook BẮT BUỘC được lưu trữ trực tiếp bên trong thư mục `specs/` của repository (ví dụ: `specs/architecture.md`, `specs/SPEC-{number}-{tên}.md`).
- **Tuân thủ chuẩn Obsidian Markdown**: File sử dụng cú pháp Markdown chuẩn kết hợp Mermaid diagrams và khối callouts. Người dùng có thể mở trực tiếp thư mục dự án bằng Obsidian Desktop ("Open folder as vault") để xem Knowledge Graph độc lập mà không bị lẫn lộn giữa các dự án trên VPS.
- **Nguyên tắc Docs-as-Code**: Tài liệu đi liền với mã nguồn qua từng Git commit/PR. Không phụ thuộc vào thư mục toàn cục hay server MCP bên ngoài.

### 2.3. Cưỡng Chế Cấu Trúc Alert Chuẩn (Alert Callout Validation)
- Tất cả các tài liệu Markdown được tạo ra (cả trong repo `specs/`, `readme.md`, `guide.md`) **BẮT BUỘC PHẢI CHỨA CÁC KHỐI ALERT CHUẨN**.
- Agent phải tự validate, nếu chưa có thì bắt buộc phải bổ sung:
  - `> [!NOTE]`: Bối cảnh nghiệp vụ, kiến trúc nền tảng.
  - `> [!IMPORTANT]`: Tiêu chí Acceptance Criteria (AC), biến môi trường bắt buộc (.env).
  - `> [!WARNING]` / `> [!CAUTION]`: Cảnh báo rủi ro bảo mật, breaking change, lưu ý khi chạy database migration.


### 2.4. Cưỡng Chế Fullstack Smoke Verification (Nghiêm Cấm Unit Test Đối Phó)
- QA Tester Agent **BẮT BUỘC** áp dụng skill `fullstack-smoke-verifier` thay vì chỉ viết unit test mock đơn thuần.
- Bắt buộc kiểm thử 3 kịch bản thực tế:
  1. **Auth Route Guard**: Dùng browser ẩn danh vào `/dashboard` ➔ Bắt buộc phải bị đẩy về `/login`.
  2. **Zero-Hardcode Localhost**: Quét và chặn toàn bộ request Client gọi trực tiếp `localhost:4000`, bắt sạch lỗi đỏ Console.
  3. **3-Viewport Responsive Audit**: Kiểm tra không tràn layout ngang trên Mobile (375px), Tablet (768px), Desktop (1440px).
- Nếu bất kỳ bài test nào trong 3 bài trên bị fail, Tester báo REJECT về cho Fullstack Dev sửa lại (tối đa 3 vòng lặp).


---

## 3. Quy Trình Phối Hợp & 2 Điểm Dừng Phê Duyệt (Human-in-the-Loop)

### 3.1. GATE 1: PO Spec Sign-Off
- Sau khi PO phân tích và đưa ra Spec (User Stories + Acceptance Criteria), hệ thống **BẮT BUỘC DỪNG LẠI** và hỏi người dùng.
- **Chỉ khi người dùng xác nhận đồng ý**, tự động lưu spec vào `specs/SPEC-{number}-{tên}.md` và kích hoạt Architect & Developer.

### 3.2. GATE 2: Developer Implementation Plan Sign-Off
- Sau khi Architect thiết kế và Developer quét codebase để lên danh sách file sửa đổi/tạo mới, hệ thống **BẮT BUỘC DỪNG LẠI** lần thứ 2.
- Developer hiển thị Implementation Plan và xin confirm: `Bạn có đồng ý tiến hành sửa/tạo các file này không? (y/n)`.
- **Chỉ khi người dùng xác nhận**, Developer mới bắt đầu sửa/ghi code vào repository.

### 3.3. Cơ Chế Vòng Lặp Tự Sửa Lỗi (Loop Control - Max 3 Retries)
- Khi **Tester báo fail** hoặc **Security báo CRITICAL/HIGH**:
  1. Developer tự động nhận log lỗi, phân tích nguyên nhân và sửa code.
  2. Tester hoặc Security chạy lại kiểm thử tương ứng.
  3. Số lần retry tối đa cho mỗi tính năng là **3 vòng lặp**.
  4. Nếu sau 3 lần vẫn chưa pass: Dừng hệ thống, hiển thị Root Cause Analysis và xin ý kiến định hướng từ người dùng.

---

## 4. Cách Sử Dụng Skill

Khi nhận lệnh với từ khóa `!team` hoặc tiếp nhận file `plan.md`:
1. Kích hoạt vai trò **PO Agent** để tạo Feature Spec và xác nhận Gate 1 (đối chiếu CodeGraph nếu có).
2. Chuyển giao sang **Architect Agent** thiết kế schema & API (kèm Mermaid chart) và lưu vào `specs/`.
3. Kích hoạt **Fullstack Dev Agent** lập plan và xin duyệt Gate 2 trước khi code.
4. Sau khi Dev code xong: Chạy `codegraph sync` để cập nhật knowledge graph.
5. Kích hoạt **QA / Tester Agent** áp dụng skill **`fullstack-smoke-verifier`** (Route Guard redirect, Zero-Hardcode localhost scan, Responsive layout audit) trên Docker / Playwright.
6. Kích hoạt **Security & DevOps Agent** kiểm tra an toàn dữ liệu và bảo mật.
7. Xuất tài liệu kỹ thuật vào thư mục **`specs/`** của dự án (validate đầy đủ Alert callouts theo chuẩn Obsidian) và cập nhật `readme.md` / `guide.md`.




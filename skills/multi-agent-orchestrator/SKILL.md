---
name: multi-agent-orchestrator
description: Coordinate and orchestrate 5 specialized subagents (Product Owner, System Architect, Fullstack Developer, QA Tester, Security & DevOps) with 2 human-in-the-loop approval gates and 3-retry loop control for end-to-end feature delivery.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Codegraph
metadata:
  version: 1.0.0
---

# Multi-Agent Orchestration System

Hệ thống phối hợp đa tác tử (Multi-Agent Orchestration) chuẩn hóa quy trình phát triển tính năng từ bài toán nghiệp vụ, thiết kế kiến trúc, triển khai code, kiểm thử tự động, cho đến audit bảo mật.

## 1. Cơ Cấu 5 Subagents & Bảng Phân Quyền

```
[User Request / Plan]
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
│ 4. QA/Tester │ ◄─── Viết & Chạy Tests (Jest) qua Docker (Max 3 retries)
└──────┬───────┘
       │ [All Tests Passed]
       ▼
┌──────────────┐
│ 5. Security  │ ◄─── Audit OWASP, Data Safety, Docker & Envs (Max 3 retries)
│   & DevOps   │
└──────┬───────┘
       │ [All Security Passed]
       ▼
[Cập nhật readme.md / guide.md & Bàn giao]
```

| Subagent | Tên định danh | Vai trò & Trọng tâm | Tools được phép | Môi trường |
|---|---|---|---|---|
| **PO Agent** | `po-agent` | Làm rõ yêu cầu, phân tích nghiệp vụ, viết User Stories & AC | Read, Grep, Codegraph, Ask Question | Session Chat / Specs Artifact |
| **Architect Agent** | `architect-agent` | Thiết kế Prisma Schema, API DTOs, luồng dữ liệu, Monorepo | Read, Grep, Codegraph | Session Chat / Artifact |
| **Fullstack Dev Agent** | `fullstack-dev-agent` | Lập Implementation Plan, viết code tuần tự API -> Web | Read, Write, Edit, Codegraph, Command | Monorepo Workspace |
| **QA / Tester Agent** | `tester-agent` | Sinh unit/e2e test, chạy test qua Docker container | Read, Write, Edit, Command (Docker exec) | Docker Compose |
| **Security & DevOps Agent** | `security-devops-agent` | Audit bảo mật, an toàn dữ liệu, verify Docker & env | Read, Grep, Command (Audit / Test) | Docker / Local Environment |

---

## 2. Quy Trình Phối Hợp & 2 Điểm Dừng Phê Duyệt (Human-in-the-Loop)

### 2.1. GATE 1: PO Spec Sign-Off
- Sau khi PO phân tích và đưa ra Spec (User Stories + Acceptance Criteria), hệ thống **BẮT BUỘC DỪNG LẠI** và hỏi người dùng.
- **Chỉ khi người dùng xác nhận đồng ý**, tự động lưu spec vào `specs/SPEC-{number}-{tên}.md` và kích hoạt Architect & Developer.

### 2.2. GATE 2: Developer Implementation Plan Sign-Off
- Sau khi Architect thiết kế và Developer quét codebase để lên danh sách file sửa đổi/tạo mới, hệ thống **BẮT BUỘC DỪNG LẠI** lần thứ 2.
- Developer hiển thị Implementation Plan và xin confirm: `Bạn có đồng ý tiến hành sửa/tạo các file này không? (y/n)`.
- **Chỉ khi người dùng xác nhận**, Developer mới bắt đầu sửa/ghi code vào repository.

### 2.3. Cơ Chế Vòng Lặp Tự Sửa Lỗi (Loop Control - Max 3 Retries)
- Khi **Tester báo fail** hoặc **Security báo CRITICAL/HIGH**:
  1. Developer tự động nhận log lỗi, phân tích nguyên nhân và sửa code.
  2. Tester hoặc Security chạy lại kiểm thử tương ứng.
  3. Số lần retry tối đa cho mỗi tính năng là **3 vòng lặp**.
  4. Nếu sau 3 lần vẫn chưa pass: Dừng hệ thống, hiển thị Root Cause Analysis và xin ý kiến định hướng từ người dùng.

---

## 3. Cách Sử Dụng Skill

Khi tiếp nhận một bài toán lớn hoặc file `plan.md` từ người dùng:
1. Kích hoạt vai trò **PO Agent** để tạo Feature Spec và xác nhận Gate 1.
2. Chuyển giao sang **Architect Agent** thiết kế schema & API.
3. Kích hoạt **Fullstack Dev Agent** lập plan và xin duyệt Gate 2 trước khi code.
4. Kích hoạt **QA / Tester Agent** viết test và chạy test trong Docker.
5. Kích hoạt **Security & DevOps Agent** kiểm tra an toàn dữ liệu và bảo mật.
6. Cập nhật `readme.md` và `guide.md` của dự án để hoàn tất.

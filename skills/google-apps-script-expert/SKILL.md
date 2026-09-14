---
name: google-apps-script-expert
description: Develop, optimize, and automate Google Apps Script (GAS) solutions for Google Sheets, Forms, Drive, Gmail, and Webhooks. Covers batch operations, clasp CLI, TypeScript, triggers, and quota management.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# Google Apps Script Expert

Chuyên gia phát triển, tối ưu hóa và tự động hóa các giải pháp trên nền tảng **Google Apps Script (GAS)**, Google Workspace APIs, tích hợp Webhooks và quản lý mã nguồn bằng `@google/clasp`.

## 1. Nguyên Tắc Tối Ưu Hiệu Năng & Tránh Quota Google

### 1.1. Batch Operations (Bắt Buộc)
- **Tuyệt đối không gọi `getValue()` hoặc `setValue()` trong vòng lặp `for/while`**:
  ```javascript
  // ❌ SAI (Gây nghẽn và chạm giới hạn quota API call):
  for (let i = 1; i <= lastRow; i++) {
    const val = sheet.getRange(i, 1).getValue();
    sheet.getRange(i, 2).setValue(val * 2);
  }

  // ✅ ĐÚNG (Đọc 1 lần - Xử lý trong RAM - Ghi 1 lần):
  const data = sheet.getRange(1, 1, lastRow, 1).getValues();
  const output = data.map(row => [row[0] * 2]);
  sheet.getRange(1, 2, output.length, 1).setValues(output);
  ```

### 1.2. Xử Lý Timeout (Giới Hạn 6 Phút / Lần Chạy)
- Khi xử lý dữ liệu lớn (Big Data / hàng nghìn dòng):
  - Lưu lại `lastProcessedRow` vào `PropertiesService.getScriptProperties()`.
  - Tạo Trigger tự động tiếp tục chạy phần còn lại sau 1 phút nếu thời gian thực thi chạm ngưỡng 5 phút 30 giây (`new Date().getTime() - startTime > 330000`).

---

## 2. Quản Lý Mã Nguồn Với `@google/clasp` & TypeScript

```bash
# Cài đặt clasp toàn cục
npm install -g @google/clasp

# Đăng nhập tài khoản Google
clasp login

# Khởi tạo dự án mới (hoặc clone từ Script ID sẵn có)
clasp create --title "Enterprise-Automation-GAS" --type sheets
# hoặc
clasp clone "<SCRIPT_ID>"

# Đẩy code lên Google Apps Script
clasp push

# Mở editor trên trình duyệt
clasp open
```

---

## 3. Webhook Endpoint (`doPost` & `doGet`) Chuẩn An Toàn

```javascript
/**
 * Webhook nhận dữ liệu từ hệ thống bên ngoài (Telegram, Next.js, CRM)
 */
function doPost(e) {
  const lock = LockService.getScriptLock();
  // Tránh xung đột ghi đồng thời (Concurrency Lock)
  lock.tryLock(10000);

  try {
    const payload = JSON.parse(e.postData.contents);
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName("Logs") || ss.insertSheet("Logs");

    sheet.appendRow([new Date(), payload.userId, payload.event, JSON.stringify(payload.data)]);

    return ContentService.createTextOutput(
      JSON.stringify({ success: true, message: "Data logged successfully" })
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService.createTextOutput(
      JSON.stringify({ success: false, error: error.toString() })
    ).setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}
```

---

## 4. Quản Lý Triggers Tự Động Bằng Code

```javascript
function setupDailyCronTrigger() {
  // Xóa triggers cũ tránh trùng lặp
  const triggers = ScriptApp.getProjectTriggers();
  for (const trigger of triggers) {
    if (trigger.getHandlerFunction() === "dailyJob") {
      ScriptApp.deleteTrigger(trigger);
    }
  }

  // Tạo trigger chạy lúc 8:00 sáng mỗi ngày
  ScriptApp.newTrigger("dailyJob")
    .timeBased()
    .everyDays(1)
    .atHour(8)
    .create();
}
```

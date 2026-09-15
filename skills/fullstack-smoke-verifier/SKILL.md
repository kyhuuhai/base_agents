---
name: fullstack-smoke-verifier
description: Production-grade fullstack verification and smoke testing. Pre-flight environment scan, zero-hardcode localhost detector, Playwright E2E tests for Auth route guards (unauthenticated redirect), client-server network intercept (no localhost leaks, CORS, console errors), and 3-viewport responsive layout audit (prevent UI breaks and mobile overflow).
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Codegraph
metadata:
  version: 1.0.0
---

# Fullstack Smoke Verifier & Quality Guard

Quy chuẩn kiểm thử tích hợp thực chiến (Production-grade Smoke & E2E Verification) nhằm loại bỏ triệt để các lỗi nghiêm trọng mà **Unit Test truyền thống không bao giờ phát hiện được**: lọt quyền truy cập (Auth bypass), sai lệch cấu hình mạng/hardcode URL (`localhost:4000`), lỗi console/CORS ngầm, và giao diện vỡ trên mobile/desktop.

---

## 1. Triết Lý: Tại Sao Unit Test Là Chưa Đủ?

| Loại kiểm thử | Phạm vi | Điểm mù trí mạng |
|---|---|---|
| **Unit Test (Jest mocks)** | Hàm cô lập trong RAM (Node.js vm) | Không chạy Browser thật; không test được `middleware.ts`; không phát hiện hardcode URL trong Client Components; không biết CSS hiển thị ra sao. |
| **Fullstack Smoke Verifier** | Trình duyệt thật (Playwright Headless) tương tác toàn diện từ UI ➔ Network ➔ API ➔ DB | Bắt trọn vẹn luồng Auth thật, chặn đứng rò rỉ URL `localhost`, bắt sạch lỗi Console, và audit vỡ layout trên 3 độ phân giải. |

---

## 2. Module 1: Pre-Flight Environment & Zero-Hardcode Audit

Trước khi khởi động kiểm thử giao diện, bắt buộc chạy quét tĩnh (Static Analysis) toàn bộ thư mục `apps/web`:

### 2.1. Quét Hardcoded Port & Localhost Leaks
```bash
# Kiểm tra xem có file nào trong Client gọi trực tiếp localhost không
grep -rnE "http://localhost:[0-9]+" apps/web/src/ || true
```
> [!CAUTION]
> **Quy tắc Zero-Hardcode**: Tuyệt đối **KHÔNG ĐƯỢC** để sót bất kỳ chuỗi `http://localhost:4000` hoặc IP nội bộ trong code Frontend (`apps/web`).
> - Mọi API call trên Client phải đi qua đường dẫn tương đối `/api/v1/...` (Next.js rewrites) hoặc biến môi trường công khai `process.env.NEXT_PUBLIC_API_URL`.

### 2.2. Kiểm Tra Proxy & Rewrites trong `next.config.js`
Đảm bảo Frontend đã cấu hình reverse proxy chính xác sang Backend container:
```javascript
// apps/web/next.config.js
module.exports = {
  async rewrites() {
    return [
      {
        source: '/api/v1/:path*',
        destination: `${process.env.INTERNAL_API_URL || 'http://localhost:4000'}/api/v1/:path*`,
      },
    ];
  },
};
```

---

## 3. Module 2: Playwright E2E Auth Guard (Chống Lọt Quyền Truy Cập)

### Kịch bản bắt buộc: Kiểm tra bảo vệ Route Guard (`middleware.ts`)

```typescript
// tests/e2e/smoke-auth-guard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Auth Route Guard Smoke Test', () => {
  const protectedRoutes = ['/dashboard', '/admin', '/settings', '/profile'];

  for (const route of protectedRoutes) {
    test(`Chưa login truy cập ${route} PHẢI redirect về /login`, async ({ page }) => {
      // 1. Dùng incognito context (chưa có cookie session)
      await page.goto(route);
      
      // 2. Chờ chuyển hướng hoàn tất
      await page.waitForURL('**/login**', { timeout: 5000 });
      
      // 3. Assert: URL hiện tại bắt buộc phải là /login
      expect(page.url()).toContain('/login');
    });
  }

  test('Đăng nhập thành công và truy cập Dashboard hiển thị đủ data', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"], input[name="email"]', 'test@example.com');
    await page.fill('input[type="password"], input[name="password"]', 'Password123!');
    await page.click('button[type="submit"]');

    // Sau khi login, phải vào được dashboard
    await page.waitForURL('**/dashboard', { timeout: 10000 });
    expect(page.url()).toContain('/dashboard');

    // Kiểm tra trang không bị trắng bóc (Empty State do lỗi fetch)
    const content = await page.textContent('body');
    expect(content?.length).toBeGreaterThan(100);
  });
});
```

---

## 4. Module 3: Network Intercept & Console Zero-Error Policy

Lắng nghe toàn bộ lưu lượng mạng và log của trình duyệt trong quá trình test:

```typescript
// tests/e2e/smoke-network.spec.ts
import { test, expect } from '@playwright/test';

test('Browser Network & Console Zero-Error Audit', async ({ page }) => {
  const consoleErrors: string[] = [];
  const leakedRequests: string[] = [];

  // Lắng nghe console log
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  // Lắng nghe network requests từ browser
  page.on('request', (request) => {
    const url = request.url();
    // Bắt lỗi: Browser cố gắng gọi trực tiếp localhost nội bộ
    if (url.includes('localhost:4000') || url.includes('127.0.0.1:4000')) {
      leakedRequests.push(url);
    }
  });

  await page.goto('/');

  // Assert 1: Không có request nào gọi nhầm localhost:4000
  expect(leakedRequests, `Phát hiện Client gọi nhầm URL nội bộ: ${leakedRequests.join(', ')}`).toHaveLength(0);

  // Assert 2: Không có uncaught exception hoặc lỗi 500 trong console
  const criticalErrors = consoleErrors.filter(
    (err) => !err.includes('favicon.ico') && !err.includes('Download the React DevTools')
  );
  expect(criticalErrors, `Phát hiện lỗi Console đỏ lòm: ${criticalErrors.join(' | ')}`).toHaveLength(0);
});
```

---

## 5. Module 4: 3-Viewport Responsive & Layout Integrity Audit

Chống triệt để lỗi **"UI vỡ hoặc chữ quá nhỏ"** trên các thiết bị:

### 5.1. Ma Trận 3 Viewport Chuẩn
- **Mobile**: Viewport `375 x 667` (iPhone SE/Standard Mobile)
- **Tablet**: Viewport `768 x 1024` (iPad Portrait)
- **Desktop**: Viewport `1440 x 900` (MacBook / Laptop)

### 5.2. Kịch Bản Tự Động Quét Lỗi Layout & Tràn Ngang
```typescript
// tests/e2e/smoke-responsive.spec.ts
import { test, expect } from '@playwright/test';

const viewports = [
  { name: 'Mobile (375px)', width: 375, height: 667 },
  { name: 'Tablet (768px)', width: 768, height: 1024 },
  { name: 'Desktop (1440px)', width: 1440, height: 900 },
];

for (const vp of viewports) {
  test(`Audit giao diện trên ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/dashboard');

    // 1. Kiểm tra tràn ngang (Horizontal Scrollbar / Overflow)
    const isHorizontalOverflow = await page.evaluate(() => {
      return document.documentElement.scrollWidth > window.innerWidth;
    });
    expect(isHorizontalOverflow, `Giao diện bị vỡ/tràn ngang trên ${vp.name}!`).toBeFalsy();

    // 2. Kiểm tra cỡ chữ tối thiểu (Không được nhỏ hơn 11px)
    const tooSmallTextCount = await page.evaluate(() => {
      const elements = Array.from(document.querySelectorAll('p, span, a, button, h1, h2, h3, h4, h5, h6, input, label'));
      return elements.filter((el) => {
        const style = window.getComputedStyle(el);
        const fontSize = parseFloat(style.fontSize);
        return fontSize > 0 && fontSize < 11;
      }).length;
    });
    expect(tooSmallTextCount, `Có ${tooSmallTextCount} phần tử chữ quá nhỏ (<11px) trên ${vp.name}!`).toBe(0);

    // 3. Chụp ảnh màn hình lưu bằng chứng
    await page.screenshot({ path: `playwright-report/screenshot-${vp.width}.png`, fullPage: true });
  });
}
```

---

## 6. Checklist Kiểm Thử Nhanh Cho Kỹ Sư (Pre-Delivery Checklist)

Mỗi khi chuẩn bị bàn giao hoặc nghiệm thu:
1. [ ] Đã chạy grep kiểm tra sạch bóng `localhost:4000` trong `apps/web`.
2. [ ] Đã mở trình duyệt ẩn danh vào `/dashboard` ➔ Bị đẩy văng ra `/login`.
3. [ ] Đã login thử ➔ Vào dashboard có dữ liệu render, F12 Console không có lỗi đỏ.
4. [ ] Đã co màn hình về `375px` ➔ Không xuất hiện thanh cuộn ngang, font chữ đọc rõ ràng.

---
name: website-builder-pro
description: Build high-performance websites and landing pages with Next.js, HTML/Tailwind, or WordPress. Covers Core Web Vitals optimization (LCP, CLS, INP), SEO metadata, OpenGraph, JSON-LD Structured Data, and sitemap generation.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
metadata:
  version: 1.0.0
---

# Website Builder Pro

Chuyên gia xây dựng website, landing page và web application hiệu năng cao, tối ưu tuyệt đối điểm **Core Web Vitals (LCP, CLS, INP)** và chuẩn hóa **SEO On-Page**.

---

## 1. Tối Ưu Core Web Vitals (100/100 Google PageSpeed)

### 1.1. Largest Contentful Paint (LCP < 2.5s)
- **Next.js Image Priority**: Gắn `priority` cho hình ảnh Hero/Banner đầu trang.
  ```tsx
  import Image from 'next/image';

  export function HeroImage() {
    return (
      <Image
        src="/images/hero-banner.webp"
        alt="Hero Banner"
        width={1200}
        height={630}
        priority
        className="w-full h-auto object-cover"
      />
    );
  }
  ```
- **Tối ưu Web Fonts**: Sử dụng `next/font/google` để tự động inline CSS font và loại bỏ layout shift (FOUT/FOIT).

### 1.2. Cumulative Layout Shift (CLS < 0.1)
- Luôn chỉ định trước `width` và `height` hoặc `aspect-ratio` cho ảnh, video và khung quảng cáo.
- Giữ chỗ trước cho dynamic content bằng Skeleton Loaders.

### 1.3. Interaction to Next Paint (INP < 200ms)
- Tách nhỏ các tác vụ nặng trên main thread bằng `useTransition` hoặc Web Workers.
- Tránh bundle các thư viện nặng không cần thiết (dùng dynamic imports `next/dynamic` cho Modal, Charts).

---

## 2. Chuẩn Hóa SEO & Metadata (Next.js 14+ App Router)

```tsx
// src/app/layout.tsx hoặc src/app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'D2 Enterprise - Giải Pháp Chuyển Đổi Số Toàn Diện',
  description: 'Nền tảng tích hợp định danh tập trung và tự động hóa quy trình nghiệp vụ doanh nghiệp.',
  keywords: ['SSO', 'Enterprise', 'Identity', 'Next.js', 'Automation'],
  authors: [{ name: 'Krylot Dev Team' }],
  openGraph: {
    title: 'D2 Enterprise - Giải Pháp Chuyển Đổi Số',
    description: 'Nền tảng tích hợp định danh tập trung và tự động hóa quy trình.',
    url: 'https://example.com',
    siteName: 'D2 Enterprise',
    images: [
      {
        url: 'https://example.com/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'D2 Enterprise OpenGraph Image',
      },
    ],
    locale: 'vi_VN',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'D2 Enterprise',
    description: 'Nền tảng tích hợp định danh tập trung.',
    images: ['https://example.com/og-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
  },
};
```

---

## 3. Schema Markup (JSON-LD Structured Data)

```tsx
// src/components/JsonLd.tsx
export function OrganizationJsonLd() {
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'D2 Enterprise',
    url: 'https://example.com',
    logo: 'https://example.com/logo.png',
    contactPoint: {
      '@type': 'ContactPoint',
      telephone: '+84-123-456-789',
      contactType: 'Customer Support',
      areaServed: 'VN',
      availableLanguage: ['Vietnamese', 'English'],
    },
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  );
}
```

---

## 4. Tự Động Sinh Sitemap & Robots.txt (Next.js App Router)

```typescript
// src/app/sitemap.ts
import { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://example.com';
  
  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/pricing`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.8,
    },
  ];
}
```

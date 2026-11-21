# StyleMorph — Architectural Constitution & Engineering Rules (`AGENTS.MD`)

You are a **Senior Full-Stack Engineer & Cloud Architect** working on **StyleMorph**. You MUST strictly enforce every rule in this constitution without exception.

---

## 1. Agent Behavioral Protocol
1. **Language Contract:**
   - All conversations, checklists, explanations, and final reports to the user MUST be strictly in **Persian (فارسی)**.
   - All code, identifiers, comments, logs, docs, and commit messages MUST be strictly in **English**.
2. **Strict Surgical Scope:**
   - Execute ONLY what is requested in the current task. Do NOT refactor unrelated modules, alter themes unprompted, or create extra documentation/scripts.
   - `WebApp/` (HTML files) is a visual/behavioral reference ONLY. NEVER edit or copy raw HTML from it.
3. **Conditional Stop (No Guessing):**
   - NEVER guess on business logic, pricing formulas, database schema changes, new paid APIs, or destructive production operations. Stop and ask the user.
   - For standard engineering details, apply best practices and report your choices in the summary.
4. **Vertical-Slice Execution Protocol:**
   - Work in small, complete vertical slices (Frontend + Backend + Firestore/Storage Rules + Tests per feature).
   - Always present a concise **Persian Checklist** before modifying files.
5. **Zero `// TODO`, Zero `// ignore`, & Feature Flags:**
   - `// TODO` comments are **STRICTLY FORBIDDEN**. Incomplete features must be gated behind **Firebase Remote Config Feature Flags**.
   - NEVER silence linter/analyzer rules (`// ignore` or disabling rules in `analysis_options.yaml` is **FORBIDDEN**).
   - Mock data is ONLY allowed behind an abstract `Repository` interface during UI prototyping. Financial, Wallet, and Security logic MUST NEVER be mocked in production paths.
6. **Self-Verification & 3-Strike Rule:**
   - Run `flutter analyze` / `flutter test` (for `app/` and `admin/`) or `npm run build` / `npm test` (for `backend/`) after every change.
   - If an error persists after **3 consecutive fix attempts**, STOP and report the exact root cause to the user.

---

## 2. Platform Topology, Repo Layout & Preview Exception
- **Consumer App (`app/`):** Built with **Flutter** targeting **Android, iOS, and Responsive Web (PWA + Desktop Dual Layout)** — never contains Admin/Seller dashboards.
- **Admin & Seller Portals (`admin/`):** Built with **Flutter Web** (`shadcn_ui` + Riverpod) for isolated Admin and Seller workspaces with mandatory 2FA.
- **Production 4-Subdomain Topology:**
  - `stylemorph.style` & `app.stylemorph.style` → Consumer Landing + Web App (`app/`).
  - `sellers.stylemorph.style` → Isolated Seller Portal (`admin/`).
  - `admin.stylemorph.style` → Isolated Super/Sub-Admin Command Center (`admin/`).
- **Pre-Launch Preview Exception:** During active development, `app/` and a temporary `/admin/` preview may run on the single preview Firebase project (`stylemorph-preview`). Before production launch, they MUST migrate to isolated `stylemorph-dev` and `stylemorph-prod` GCP projects (`europe-west3`) and dedicated subdomains.
- **Core Consumer Modules (6):**
  1. `Wardrobe & Gallery` (digital closet + AI outputs archive).
  2. `AI Stylist & Virtual Try-On` (chat/voice consultant + fitting room).
  3. `Virtual Atelier` (portrait/editorial/short-video templates).
  4. `Wellness & Beauty` (face/skin/hair/body/mind + Future Self; **ZERO ads allowed**).
  5. `Shop` (catalog, filters, promoted vendor ads CPC/CPM, external seller links in V1).
  6. `Multi-Tab Profile` (fixed header, 8 vertical sidebar tabs with independent inner scroll, zero whole-page scroll).

---

## 3. Frontend Architecture, Design System & Localization (`app/` & `admin/`)
1. **Clean Architecture & Riverpod-Only:**
   - Strict feature-first layout (`core/`, `features/<feature>/{domain,data,presentation}/`, `l10n/`).
   - **ZERO imports from `data/` inside `presentation/`** — `presentation/` depends ONLY on `domain/` entities and abstract repository interfaces.
   - Use **Riverpod (`flutter_riverpod`)** exclusively for state management. Do NOT put business logic in `setState`.
   - **`app_state.dart` Freeze Rule:** `app/lib/core/state/app_state.dart` is **FROZEN** for new feature logic. Every new or refactored module MUST use its own feature-scoped Riverpod providers/notifiers.
2. **Design System (`shadcn_ui` + Design Tokens):**
   - Wrap all `shadcn_ui` components inside `core/widgets/` (`AppButton`, `AppCard`, `AppTextField`, `AppModal`, `AppBottomSheetShell`, `AppBadge`, `AppSwitchTile`, etc.). Never use raw Material widgets when a Base Widget exists.
   - Separate **geometry/layout** (`AppSpacing`, `AppRadius`, `AppTypography`) from **colors/themes** (`AppColors` via `ThemeExtension`). Zero hardcoded colors, radii, or paddings in screens.
   - Support **5 Fashion Themes**: `Minimal Light (White)`, `Luxury Warm Beige`, `Modern Slate`, `Obsidian Dark`, and `Luxury Editorial` (with Light / Dark / System brightness modes).
3. **Localization & RTL-First:**
   - Support `fa` (default, RTL), `ar` (RTL), `en` (LTR), and `tr` (LTR) with bundled `Vazirmatn` font and local icons (no external CDN).
   - Zero hardcoded UI strings. **Writing `if/switch` on `localeCode` in UI widgets is STRICTLY FORBIDDEN.**
   - Use directional widgets exclusively (`EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`).
4. **Offline/Online Policy:**
   - `Offline-First` is **Read-Only** for `Wardrobe` and `Profile` (with cached thumbnails).
   - `Wallet`, `Transactions`, `Shop`, and all `AI` services are strictly **`Online-Only`**.

---

## 4. Canonical Firestore Data Contract (Single Source of Truth)
All code in `app/`, `admin/`, `backend/functions/`, and `firestore.rules` MUST use these exact paths and field names. Duplicate aliases are **FORBIDDEN**.

### A. Root User Document: `users/{uid}`
- **Server-Only / Protected Fields (NEVER writable from client):**
  - `walletBalance` (`number` — **ONLY canonical balance field**; `coins` and `coinBalance` are deprecated/forbidden in new code)
  - `heldBalance` (`number`)
  - `referralCount` (`number`)
  - `networkTier` (`string`)
  - `role` (`'user' | 'seller' | 'sub_admin' | 'admin'` — mirrored from Auth Custom Claims)
  - `permissions` (`string[]`)
- **Profile, Loyalty & Activity Fields:**
  - `firstName`, `lastName`, `nickname`, `email`, `photoURL` (`string`)
  - `emailVerified` (`boolean`), `showEmailInHeader` (`boolean`, default `false`)
  - `stylePoints` (`number`), `loyaltyRank` (`'bronze' | 'silver' | 'gold' | 'diamond'`)
    - Rank thresholds: `bronze` (`0–499`), `silver` (`500–1499`), `gold` (`1500–3999`), `diamond` (`4000+`).
  - Profile Completion Formula: **40% Anatomy / 35% Media / 25% Identity**.
  - `createdAt`, `updatedAt` (`timestamp`).

### B. User Subcollections under `users/{uid}`
- `sessions/{sessionId}` — Controlled multi-session tracking.
- `health_dna/{recordId}` — Sensitive body/wearable/wellness telemetry (strict owner-only + privacy TTL).
- `wardrobe/{itemId}` — Closet items linked to Storage (`thumbUrl`, `originalUrl`, `imageHash`, AI tags).
- `creations/{creationId}` — AI Atelier & Try-On outputs.
- `wellness_logs/{logId}` — Daily mood/skin/fitness logs.
- `kyc/{docId}` — Identity verification records.

### C. Top-Level Collections
- `ledger/{txId}` — **Immutable, append-only** financial ledger (server-only write; `update`/`delete` ALWAYS `false`).
- `wallet_holds/{holdId}` — Active/settled `StyleCoin` holds (server-only write).
- `jobs/{jobId}` — Async AI Cloud Tasks jobs (`PENDING | PROCESSING | VALIDATING | COMPLETED | FAILED`).
- `shops/{shopId}` & `products/{productId}` — Vendor stores, ad wallets, and product catalogs.
- `tickets/{ticketId}` — Context-aware support tickets linked to `txId` or `jobId`.
- `audit_logs/{logId}` — Immutable admin/seller audit trail (server-only write).
- `app_config/version` — Remote app version/build config (public read, admin write).
- `system_config/wallet_promo` — Dynamic promo banner & Store Reviewer Shield config (public read, admin write).

### D. Query & Cost Rules
- Target **1–2 Document Reads** per screen load using Controlled Denormalization.
- **Cursor-Based Pagination (`limit(20)` + `startAfterDocument`) is MANDATORY** on all lists. Unbounded queries are forbidden.
- Register all composite queries in `firestore.indexes.json`.

---

## 5. Backend, AI Gateway, Financial Engine & Security
1. **Tech Stack:**
   - `backend/functions/`: Firebase Cloud Functions (Gen 2, `europe-west3`), **TypeScript (`strict: true`)**, **Zod** validation.
   - `backend/ai-gateway/`: **Google Cloud Run** (TypeScript/Express or Fastify) for low-latency AI routing.
   - Heavy AI jobs run asynchronously via **Google Cloud Tasks** (< 200ms initial response returning `jobId`, completion via **FCM**).
   - Dynamic pricing, quotas, and model names come from **Firebase Remote Config / Firestore**, never hardcoded.
2. **Auth, Soft Gate & Controlled Multi-Session:**
   - Providers: Google, Apple, Email/Password (SMS disabled by default); Biometrics & 2FA supported.
   - **Email Verification (Soft Gate):** New users enter the app freely; unverified email restricts ONLY high-cost AI generation and Wallet/Financial actions.
   - **Controlled Multi-Session Policy:** Max **5 active devices** per user, **1 Primary Device** with authority to inspect/revoke/block other sessions, and **14-day idle session expiration**.
   - Production requires **Firebase App Check**, `TLS 1.3`, `AES-256`, and concurrency tests on financial functions.
3. **Storage & AI Hash Caching:**
   - Compress uploads to `WebP`/`AVIF` (`thumbUrl` < 30KB + `originalUrl`).
   - Compute **`SHA-256` image hash** before calling AI; return cached JSON metadata on duplicate hashes.
4. **AI Gateway (`backend/ai-gateway/`):**
   - Client NEVER calls AI providers directly.
   - **Multi-Account / Multi-Project Key Pool** (Secret Manager + Hot Reload), **Least-Latency & Quota-Aware Load Balancer**, and **< 10ms Circuit Breaker** on `401/403/429/5xx`.
   - **No Silent Downgrade:** Users pick quality tiers (`FAST`, `STANDARD`, `CINEMATIC`). Fallback MUST stay within the **Same-Tier Equivalent**; otherwise abort and `Release` coins.
   - **Automated Visual QA (Self-Correction):** Verify anatomical integrity and safety via Vision model before `Capture`. Always embed permanent `"AI Generated"` watermark/metadata.
5. **Atomic Financial Engine & Tri-Channel Payments:**
   - **Pay-as-you-go:** `1 StyleCoin ≈ $0.02 USD`, purchased coins never expire.
   - **Atomic Cycle (`Hold → Capture / Release`):** Every mutation runs inside `runTransaction` with a unique `idempotencyKey`. Client has `write: false` on balances and `ledger`. Corrections use new `Adjusting Entry` records only.
   - **Tri-Channel Payment SSV:** Unified server-side webhook verification for (1) Native Store IAP (`RevenueCat`), (2) Web Fiat (`Stripe`/`Paddle`), and (3) Web Crypto (`NOWPayments`/`Cryptomus`), logged with `paymentProvider: 'IAP' | 'STRIPE' | 'CRYPTO'`.
   - **Smart Web-Topup Promo & Store Reviewer Shield:** Mobile wallet promo banner ("Extra Bonus Coins") is 100% controlled by Remote Config (`under_review_build_numbers` + `killSwitch`) with 60-second One-Tap Magic Checkout Tokens.
   - **AdMob SSV & Adaptive Generosity:** Rewarded ads credited via Google SSV only; strictly blocked in `Wellness` and for subscribers.

---

## 6. Admin & Seller Web Panel Architecture (`admin/` — 9 Core Subsystems)
Must implement isolated 3-Way Auth Gate (`Admin`, `Seller Portal`, `Consumer Web`) with **4-Tier RBAC** (`Super Admin`, modular `Sub-Admins`, `Shop Multi-Tenancy`, `Normal Users`) via Firebase Custom Claims:
1. **BI & Cultural Drill-Down Analytics:** BigQuery-backed hierarchical drill-down (Year → Hour → Country Heatmap → User), AI error rates by region, cloud cost vs revenue, and session analytics.
2. **Finance & P&L Accounting:** Immutable Ledger explorer, 3-way payment reconciliation (`IAP/Stripe/Crypto`), per-transaction GCP cost vs revenue P&L, dynamic pricing, and audited manual adjustments.
3. **AI Gateway & Prompt Ops:** Multi-key pool health/latency, token usage breakdown, Cloud Tasks monitor, budget circuit-breakers, Self-Correction thresholds, A/B prompt testing, and sentiment alerts.
4. **4-Tier RBAC & Seller Governance:** Modular sub-admin permissions, seller approval queue, commissions, and isolated shop sub-users (`Product Manager`, `Support`, `Accountant`).
5. **Immutable Audit Trail (`audit_logs`):** Actor, timestamp, IP, before/after diff, and reason for every admin/seller action.
6. **Automated Backup & Disaster Recovery:** Firestore PITR (7-day), nightly isolated Coldline backups, 30-day Storage Soft Delete, BigQuery ledger archive, on-demand backup, granular restore, and GDPR deletion.
7. **Event Notifications & Context-Aware Helpdesk:** Dynamic email templates, split-view ticketing with auto-attached `txId`/`jobId`, auto-routing, 1-click Refund, AI reply suggestions, and 72h SLA auto-close.
8. **In-App & Vendor Promoted Ads:** AdMob SSV & Adaptive Generosity controls, vendor CPC/CPM campaigns, AI RAG placement weights, scheduling, and ROI analytics.
9. **Module CMS & Kill-Switches:** Live Remote Config / Firestore control for all 6 consumer modules (including `Wallet Promo Banner CMS`, `AI DNA` fields, `Wardrobe Tag CMS`, `Wellness Privacy Kill-Switches`, `Stylist Persona/Prompt CMS`, `Atelier Template Studio`, and `Shop Campaigns`).
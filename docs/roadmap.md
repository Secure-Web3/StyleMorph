# StyleMorph — Vertical-Slice Execution Roadmap (`docs/roadmap.md`)

All work follows `AGENTS.MD`. Instead of building all UI first and connecting the database later, every module is delivered as a **complete Vertical Slice**:
> **Data Contract (`AGENTS.MD`) → Domain & Repository → Firestore/Storage Rules & Indexes → Backend Cloud Function (if needed) → UI & Localization → Automated Tests → Live Verification.**

---

## Completed Foundation (Done ✅)
- **Foundation & Design System:** Flutter app shell (`app/`), 5 Fashion Themes + Light/Dark/System modes, 4-language RTL/LTR (`fa/en/ar/tr`), `shadcn_ui` Base Widgets, Responsive Web + Desktop Dual Layout.
- **Auth & Profile V2 (Tasks 01–28):** Firebase Auth (Email/Google/Apple), Soft Email Verification Gate, Turnstile + Fallback, Remember Me, Controlled Multi-Session (max 5 devices, 14-day TTL), 8-tab Profile (`Identity`, `KYC`, `Media`, `Anatomy/AI DNA`, `Wallet`, `Referral`, `Companion`, `Settings`, `About`), Loyalty `StylePoints` & weighted completion.
- **Core Backend & Admin Scaffold:** `backend/functions/` (Atomic `StyleCoin` Engine, Payment SSV, Health DNA, Session Guard), `backend/ai-gateway/` (Key Pool, Mock AI, SHA-256 Cache), and unified Flutter Web `admin/` scaffold (8 sections + Seller Portal).

---

## Slice 0: Stabilization, Security Hardening & Contract Alignment (CURRENT PRIORITY 🔴)
**Goal:** Lock down security, unify database field naming, and restore 100% green tests/linter before building new slices.
- **0.1 Security & Data Contract:** Remove open update loophole in `firestore.rules`, protect `walletBalance`/`heldBalance`/`referralCount`/`networkTier`/`role`, and align client reads/writes to canonical `walletBalance`.
- **0.2 Platform & Hosting Hardening:** Add iOS Camera/PhotoLibrary keys (`Info.plist`), Android `allowBackup="false"` + permissions (`AndroidManifest.xml`), Web security headers (`firebase.json`), and create `firestore.indexes.json`.
- **0.3 Code Quality & Tests:** Fix the 17 failing Flutter tests, re-enable ignored rules in `analysis_options.yaml`, remove locale `if` conditions from `camera_alignment_guide_dialog.dart`, run `dart format .`, and patch `zod`/`uuid` vulnerabilities in `backend/`.

---

## Slice 1: Virtual Wardrobe & Storage Pipeline (Full Vertical Slice)
**Goal:** Connect `Wardrobe` 100% to live Firestore (`users/{uid}/wardrobe`), Firebase Storage, and AI tagging.
- Domain entities & `WardrobeRepository` interface (`features/wardrobe/domain/`).
- Live Firestore/Storage implementation with `WebP` compression, `thumbUrl`, `SHA-256` image hash, and cursor pagination (`limit(20)`).
- Strict `firestore.rules` & `storage.rules` + composite indexes + unit/widget tests.

---

## Slice 2: Live StyleCoin Wallet & Cloud Functions Integration (Full Vertical Slice)
**Goal:** Connect `app/` to `backend/functions/` (`cloud_functions` package) so zero financial mutations happen on the client.
- Wire `holdCoins`, `captureCoins`, `releaseCoins`, and `getWalletPromoConfig` (Store Reviewer Shield) to `Wallet` sub-tab and header balance.
- Live read-only `ledger` history with pagination and referral reward Cloud Function.
- End-to-end tests on Firebase Emulator.

---

## Slice 3: Shop V1 & Promoted Vendor Catalog (Full Vertical Slice)
**Goal:** Connect `Shop` to live `shops/` and `products/` collections with filtering, pagination, and click tracking.
- Clean `domain/data/presentation` separation, search/filter indexes, external URL validation, and promoted product placement.

---

## Slice 4: AI Stylist, Virtual Try-On & Virtual Atelier (Full Vertical Slice)
**Goal:** Connect `Stylist` and `Atelier` to live `backend/ai-gateway/` (Cloud Run) + `jobs/{jobId}` + `users/{uid}/creations`.
- Quality-tier confirmation (`FAST`/`STANDARD`/`CINEMATIC`) → `holdCoins` → AI Gateway (`USE_MOCK_AI` toggleable) → Visual QA → `captureCoins` or auto `releaseCoins`.
- Permanent `"AI Generated"` watermark metadata and `My Creations` persistence.

---

## Slice 5: Wellness, Beauty & Health DNA (Full Vertical Slice)
**Goal:** Connect `Wellness` to `users/{uid}/health_dna` and `wellness_logs` with strict privacy controls.
- Wearable sync (`syncHealthDna` / `getHealthDnaSummary`), privacy TTL auto-deletion rules, biometric context passed to AI Stylist, and zero-ads enforcement.

---

## Slice 6: Live Admin & Seller Web Portals (`admin/`)
**Goal:** Replace in-memory mock state in `admin/` with real Firebase Auth (Custom Claims + 2FA), Firestore, and Cloud Functions.
- Separate hosting target & isolated subdomains (`admin.stylemorph.style`, `sellers.stylemorph.style`).
- Wire Immutable Ledger explorer, AI Gateway Key Pool, Seller approval queue, Support Desk (1-click refund), and Module CMS/Kill-Switches.

---

## Slice 7: Production Readiness & Store Launch
**Goal:** Final compliance, security, and multi-environment deployment (`stylemorph-dev` / `stylemorph-prod`).
- Implement mandatory **Account Deletion** flow (UI + cascading Cloud Function for App Store / Google Play compliance).
- Enable **Firebase App Check** (`enforceAppCheck: true`), Crashlytics, BigQuery export, `flutter_secure_storage`, and CI checks (`flutter analyze` + `flutter test` on every push).
- Switch `USE_MOCK_AI=false` with live Secret Manager keys and build production `.aab`, `.ipa`, and Web bundles.
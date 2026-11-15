# StyleMorph Technical Architecture Inventory & Codebase Audit
**Document Version:** 1.0.0  
**Audit Date:** November 15, 2026  
**Auditor:** Senior Principal Architect  
**Scope:** `app/`, `backend/functions/`, `backend/ai-gateway/`, `admin/`, `firestore.rules`, `storage.rules`, `firebase.json`

---

## 1. Directory Structure & Active Tech Stacks

```
StyleMorph/
├── .firebaserc                     # Firebase project configuration (stylemorph-dev)
├── firebase.json                   # Emulator suite & codebase binding configuration
├── firestore.rules                 # Zero-Trust Firestore database access control
├── storage.rules                   # Media upload size, MIME & isolation rules
├── AGENTS.md                       # Comprehensive project constitution & technical requirements
├── WebApp/                         # Visual & behavioral web prototype reference
├── docs/
│   ├── roadmap.md                  # Project development roadmap (Phases 0 - 6)
│   └── CURRENT_ARCHITECTURE.md     # Technical inventory & codebase audit (this document)
├── backend/
│   ├── functions/                  # Firebase Cloud Functions (Gen 2) - Financial Engine & SSV
│   │   ├── package.json            # Node 20, TypeScript, firebase-admin, firebase-functions, zod
│   │   ├── tsconfig.json
│   │   ├── jest.config.js
│   │   └── src/
│   │       ├── index.ts            # Entrypoint exporting financial, SSV, auth & health functions
│   │       ├── health.ts           # Health DNA wearable telemetry & energy readiness scoring
│   │       ├── types/
│   │       │   └── financial.ts    # Zod schemas, ledger enums, and DTO types
│   │       ├── services/
│   │       │   ├── financialEngine.ts # Atomic holdCoins, captureCoins, releaseCoins
│   │       │   ├── paymentWebhooks.ts # IAP, Stripe, Crypto webhooks & Reviewer Shield
│   │       │   └── sessionGuard.ts    # Single-Device session registration & displacement
│   │       └── __tests__/
│   │           ├── financial.test.ts
│   │           ├── financial.unit.test.ts
│   │           └── health.unit.test.ts
│   └── ai-gateway/                 # Cloud Run Microservice - Multi-Key Load Balancer & QA Guard
│       ├── package.json            # Node 20, Express, TypeScript, Zod
│       ├── tsconfig.json
│       └── src/
│           ├── index.ts            # Express server (POST /v1/generate, GET /health, GET /metrics/keys)
│           ├── cache.ts            # SHA-256 fingerprint deduplication & TTL cache
│           ├── financialClient.ts  # Internal HTTP client calling captureCoins / releaseCoins
│           ├── keyPool.ts          # Least-latency, quota-aware multi-project key pool with 429 backoff
│           ├── qualityGuard.ts     # Quality tier router, anatomical validation & watermark injection
│           ├── types.ts            # Zod schemas for AI requests, routes, and responses
│           └── __tests__/
│               └── gateway.test.ts
├── admin/                          # Unified Web Admin Panel & Merchant Portals (Flutter Web)
│   ├── firebase.json               # Firebase Hosting target "admin" -> public: "build/web" with SPA rewrites
│   ├── pubspec.yaml                # Flutter Web dependencies: flutter_riverpod, shadcn_ui, intl
│   ├── analysis_options.yaml       # Strict Flutter linter config (0 issues)
│   ├── assets/fonts/               # Vazirmatn font family assets
│   ├── test/                       # Comprehensive Flutter widget & integration test suite
│   │   └── admin_panel_test.dart   # 8 tests covering 3-Way Auth Gate, 8 Admin sections, Seller isolation, RTL/Theme
│   ├── web/                        # Flutter Web runner index.html, manifest.json, favicon
│   ├── build/web/                  # Compiled production web artifacts ready for Firebase Hosting
│   └── lib/                        # Clean Architecture Flutter Web codebase
│       ├── main.dart               # Entrypoint with 3-Way Auth Gate routing & ShadTheme
│       ├── core/                   # Design tokens, theme, localization (RTL), state management
│       └── features/               # Auth, Layout, 8 Admin sections, Seller Portal, Consumer Web
└── app/                            # Mobile User App (Flutter, Android & iOS targets)
    ├── pubspec.yaml                # Flutter 3.44.8, Riverpod 2.5.1, shadcn_ui 0.57.4
    ├── analysis_options.yaml
    ├── assets/fonts/               # Vazirmatn font family (Regular, Medium, SemiBold, Bold)
    ├── test/                       # 6 test suites covering phase 2, 3, 4, shell, and wearable health
    └── lib/
        ├── main.dart               # App entrypoint with Multi-Language & ShadTheme
        ├── core/
        │   ├── localization/       # AppLanguage enum, AppStrings, LocaleNotifier
        │   ├── services/           # EmulatorConfig, AiGatewayClient, HealthService
        │   ├── state/              # AppState, AppStateNotifier (navigation, wallet, notifications)
        │   ├── theme/              # AppTheme, 5 Fashion Palettes, Light/Dark/System ThemeNotifier
        │   └── widgets/            # Reusable App* base widgets wrapping shadcn_ui
        ├── features/
        │   ├── shell/              # MainShellScreen, AppBottomNav (5 tabs), MainHeader, AppDrawer
        │   ├── wardrobe/           # WardrobeTab, WardrobeRepository, WardrobeProvider, AddItemSheet
        │   ├── shop/               # ShopTab, ShopRepository, ShopProvider, ProductDetailSheet
        │   ├── stylist/            # StylistTab, StylistRepository, StylistProvider, TryOnDialog
        │   ├── atelier/            # AtelierTab, AtelierRepository, AtelierProvider, TemplateDetail
        │   ├── wellness/           # WellnessTab, WellnessRepository, WellnessProvider, WearableConsent
        │   ├── profile/            # ProfileTab with 7 Sub-Tabs (AI DNA, Wallet, Persona, Settings, etc.)
        │   └── auth/               # AuthView (login, biometric, 2FA mock)
        └── l10n/                   # app_fa.arb, app_en.arb, app_ar.arb, app_tr.arb
```

### Framework & Package Inventory

| Workspace Directory | Primary Language / Engine | Key Frameworks / Dependencies | Status / Purpose |
| :--- | :--- | :--- | :--- |
| **`app/`** | Dart 3.12.2 / Flutter 3.44.8 | `flutter_riverpod` (^2.5.1), `shadcn_ui` (^0.57.4), `font_awesome_flutter` (^11.0.0), `intl` (^0.20.2), `cupertino_icons` (^1.0.8) | Production User Mobile Application (iOS/Android). Clean Architecture. |
| **`backend/functions/`** | TypeScript 5.6.3 / Node 20 | `firebase-functions` (^6.1.1, v2), `firebase-admin` (^12.7.0), `zod` (^3.23.8), `jest` (^29.7.0) | Cloud Functions backend (deployed to `europe-west3`). Financial Engine, Session Guard, Payment Webhooks, Health DNA. |
| **`backend/ai-gateway/`** | TypeScript 5.6.3 / Node 20 | `express` (^4.21.1), `zod` (^3.23.8) | Standalone Cloud Run microservice on port 8081. Multi-key load balancing, QA gates, watermark injection, and coin capture/release callbacks. |
| **`admin/`** | Dart 3.12.2 / Flutter 3.44.8 | `flutter_riverpod` (^2.5.1), `shadcn_ui` (^0.57.4), `font_awesome_flutter` (^11.0.0), `intl` (^0.20.2), `cupertino_icons` (^1.0.8) | **Unified Web Admin Panel & Merchant Portals**. 3-Way Auth Gate, 8-Section Admin Panel, Isolated Seller Portal, Consumer Web Portal, Firebase Hosting configured for `build/web`. |

---

## 2. Database Schema & Security Rules (`firestore.rules` & `storage.rules`)

### Firestore Path & Access Control Matrix

| Collection / Document Path | Client Read | Client Write | Protected Fields / Enforcements | Server / Backend Management |
| :--- | :--- | :--- | :--- | :--- |
| `users/{userId}` | **Owner Only** (`isOwner` + `hasValidSessionOnSelf`) | **Create/Update Owner Only**; Delete: **Forbidden** | `walletBalance`, `coinBalance`, `heldBalance`, `role`, `permissions`, `activeDeviceId`, `activeSessionId` | Root user profile. Protected fields are immutable from client SDK and can only be modified via Cloud Functions / Admin SDK. |
| `users/{userId}/wardrobe/{itemId}` | **Owner Only** (`hasValidSessionForUser`) | **Owner Only** (`hasValidSessionForUser`) | Tied to user's single-device session. | Virtual Wardrobe clothes, shoes, bags, and accessories. |
| `users/{userId}/creations/{creationId}` | **Owner Only** (`hasValidSessionForUser`) | **Owner Only** (`hasValidSessionForUser`) | Tied to user's single-device session. | AI Atelier portraits, cinematic videos, and Try-On generations. |
| `users/{userId}/wellness_logs/{logId}` | **Owner Only** (`hasValidSessionForUser`) | **Owner Only** (`hasValidSessionForUser`) | Tied to user's single-device session. | Daily wellness habits, skincare routines, and mental vitality records. |
| `users/{userId}/wellness/{recordId}` | **Owner Only** (`hasValidSessionForUser`) | **Owner Only** (`hasValidSessionForUser`) | Tied to user's single-device session. | Beauty, skin, and hair analysis logs. |
| `users/{userId}/health_dna/{recordId}` | **Owner Only** (`hasValidSessionForUser`) | **Forbidden** (`allow write: if false`) | Read-only for mobile client; write exclusively enforced by `syncHealthDna` Cloud Function. | Sensitive biometric telemetry from Apple HealthKit, Health Connect, and smart watches. |
| `ledger/{txId}` | **Owner Read Only** (`resource.data.userId == uid`) | **Forbidden** (`allow write: if false`) | Client write: 100% blocked. Zero-Trust financial invariant. | Global immutable financial ledger recording every `HOLD`, `CAPTURE`, `RELEASE`, `TOPUP`, `SUBSCRIPTION`, `AD_REWARD`. |
| `wallet_holds/{holdId}` | **Owner Read Only** (`resource.data.userId == uid`) | **Forbidden** (`allow write: if false`) | Client write: 100% blocked. | Ephemeral coin reservation records during AI job pipelines. |
| `jobs/{jobId}` | **Owner Read Only** (`resource.data.userId == uid`) | **Forbidden** (`allow write: if false`) | Client write: 100% blocked. | Asynchronous AI generation job state (`PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`). |
| `shops/{sellerId}` | **Authenticated Read Only** | **Forbidden** (`allow write: if false`) | Public shop directory for mobile shoppers. | Managed via Web Admin / Seller portal. |
| `products/{productId}` | **Authenticated Read Only** | **Forbidden** (`allow write: if false`) | Public product catalog with affiliate/direct links. | Managed via Web Admin / Seller portal. |
| `audit_logs/{logId}` | **Forbidden** (`allow read, write: if false`) | **Forbidden** (`allow read, write: if false`) | Client access completely denied. | Append-only audit trail written by `sessionGuard.ts` and Admin operations. |
| `idempotency_keys/{keyId}` | **Forbidden** (`allow read, write: if false`) | **Forbidden** (`allow read, write: if false`) | Client access completely denied. | Stores SHA-256 operation fingerprints and cached results to prevent double-charges. |
| `payment_events/{eventId}` | **Forbidden** (`allow read, write: if false`) | **Forbidden** (`allow read, write: if false`) | Client access completely denied. | Tri-channel webhook raw payloads and processing logs. |
| `system_config/{docId}` | **Forbidden** (`allow read, write: if false`) | **Forbidden** (`allow read, write: if false`) | Client access completely denied. | Dynamic settings such as `system_config/wallet_promo` for Reviewer Shield. |
| `{document=**}` (Catch-all) | **Forbidden** | **Forbidden** | Default zero-trust deny-all rule. | N/A |

### Single-Device Session Rules Enforced
1. **Rule Helpers:** `hasValidSessionForUser(userId)` and `hasValidSessionOnSelf()`.
2. **Mechanism:** Validates that `request.auth.token.activeDeviceId == userDoc.activeDeviceId`.
3. **Displacement:** When `registerDeviceSession` is invoked from a new device, it updates `activeDeviceId`, revokes Firebase Auth refresh tokens for all existing sessions via `getAuth().revokeRefreshTokens(userId)`, and writes an audit log. The previous device's Firestore rules immediately fail on subsequent calls.

### Storage Rules (`storage.rules`)
- **Bucket Path:** `users/{userId}/{allPaths=**}`
  - **Read:** Permitted if `isOwner(userId)`.
  - **Create / Update:** Permitted if `isOwner(userId)` AND media matches validation:
    - Images: `image/(jpeg|jpg|png|webp|avif|heic|heif)` $\le 15\text{ MB}$.
    - Videos: `video/(mp4|quicktime|webm)` $\le 100\text{ MB}$.
  - **Delete:** Permitted if `isOwner(userId)`.
- **Catch-All:** All other paths default to `allow read, write: if false;`.

---

## 3. Backend Cloud Functions & Financial Engine (`backend/functions/`)

**Global Config:** Deployed to `europe-west3`, `maxInstances: 20`, Node 20 runtime.

### Exported Functions Summary

| Function Name | Export Type | Auth / Security | Input Schema (Zod) | Output / Execution Logic |
| :--- | :--- | :--- | :--- | :--- |
| **`holdCoins`** | `onCall` (Callable) | Firebase Auth UID + `verifyActiveSession` | `HoldCoinsCallableSchema`<br>- `amount`: positive float $\le 1{,}000{,}000$ (max 2 decimals)<br>- `serviceType`: `VIRTUAL_TRYON` \| `ATELIER_PHOTO` \| `ATELIER_VIDEO` \| `STYLIST_CHAT` \| `WELLNESS_ANALYSIS` \| `WARDROBE_CAPACITY`<br>- `qualityTier`: `FAST` \| `STANDARD` \| `CINEMATIC`<br>- `idempotencyKey`: regex `^[a-zA-Z0-9._:-]+$` | Atomically checks `walletBalance >= amount`, moves funds from `walletBalance` to `heldBalance`, creates `wallet_holds/{holdId}` (`status: HELD`), writes `ledger/{txId}` (`type: HOLD`), stores result in `idempotency_keys`. |
| **`captureCoins`** | `onRequest` (HTTP POST) | Internal Secret (`INTERNAL_SERVICE_SECRET` or emulator bypass) | `CaptureCoinsInputSchema`<br>- `holdId`: string<br>- `idempotencyKey`: string<br>- `metadata`: optional object | Validates hold is in `HELD` state. Deducts `heldBalance`, updates hold status to `CAPTURED`, records `ledger/{txId}` (`type: CAPTURE`), writes idempotency record. |
| **`releaseCoins`** | `onRequest` (HTTP POST) | Internal Secret (`INTERNAL_SERVICE_SECRET` or emulator bypass) | `ReleaseCoinsInputSchema`<br>- `holdId`: string<br>- `reason`: string<br>- `idempotencyKey`: string | Restores `heldBalance` back to `walletBalance`, updates hold status to `RELEASED`, records `ledger/{txId}` (`type: RELEASE`) with reason, writes idempotency record. |
| **`iapWebhook`** | `onRequest` (HTTP POST) | Bearer secret (`IAP_WEBHOOK_SECRET`) | `IapWebhookPayloadSchema`<br>- `eventId`, `type`, `appUserId`, `productId`, `store` (`PLAY_STORE` \| `APP_STORE`), `coinsAmount`, `transactionId` | Deduplicates via `payment_events/{eventId}`, credits `walletBalance`, writes `ledger` entry of type `TOPUP` or `SUBSCRIPTION`. |
| **`stripeWebhook`** | `onRequest` (HTTP POST) | HMAC-SHA256 signature (`STRIPE_WEBHOOK_SECRET`) with 5-minute replay window check | `StripeWebhookPayloadSchema`<br>- `eventId`, `type`, `userId`, `packageId`, `baseCoins`, `amountUsdCents`, `paymentIntentId` | Deduplicates via `payment_events/{eventId}`, calculates dynamic web bonus (+20%), credits `walletBalance`, writes `ledger` entry of type `TOPUP`. |
| **`cryptoWebhook`** | `onRequest` (HTTP POST) | HMAC-SHA512 signature (`CRYPTO_WEBHOOK_SECRET`) | `CryptoWebhookPayloadSchema`<br>- `paymentId`, `orderId`, `paymentStatus`, `userId`, `baseCoins`, `payCurrency`, `txHash` | Only processes `paymentStatus === "finished"`, applies crypto bonus (+20%), credits `walletBalance`, writes `ledger` entry of type `TOPUP`. |
| **`getWalletPromoConfig`** | `onCall` (Callable) | None (Public client query) | `WalletPromoConfigRequestSchema`<br>- `buildNumber`: string<br>- `platform`: `android` \| `ios` \| `web` | Queries `system_config/wallet_promo`. If kill-switch active or build is under app store review (`underReviewBuildNumbers`), returns `showPromoBanner: false` to protect against app store rejection. |
| **`registerDeviceSession`** | `onCall` (Callable) | Firebase Auth UID | `RegisterDeviceSessionInputSchema`<br>- `deviceId`, `deviceName`, `platform`, `appVersion` | Updates `users/{userId}.activeDeviceId`, revokes prior device tokens via `revokeRefreshTokens`, writes displacement log to `audit_logs`, returns `{ sessionId, previousDeviceRevoked }`. |
| **`syncHealthDna`** | `onCall` (Callable) | Firebase Auth UID + `verifyActiveSession` | `SyncHealthDnaInputSchema`<br>- `userId`, `steps`, `sleepHours`, `deepSleepHours`, `heartRateBpm`, `weightKg`, `activeCalories`, `sourceDevice`, `consentedScopes` | Filters metrics strictly by consented scopes, computes `energyReadinessScore` (0-100) and `stylistBiometricHint`, stores in `users/{userId}/health_dna/{recordId}`. |
| **`getHealthDnaSummary`** | `onCall` (Callable) | Firebase Auth UID + `verifyActiveSession` | None | Returns the latest health DNA record for the authenticated user. |

---

## 4. AI Gateway Microservice (`backend/ai-gateway/`)

**Architecture:** Standalone Node/Express microservice on port 8081 designed for Cloud Run.

### Microservice Endpoints

| Method & Route | Description & Parameters | Return Codes & Response |
| :--- | :--- | :--- |
| **`GET /health`** | Heartbeat & diagnostics | `200 OK`: `{ status: "ok", mockMode, cacheEntries, watermark, keys }` |
| **`GET /metrics/keys`** | Key pool telemetry | `200 OK`: Detailed list of API keys with latency EMA, remaining quota, 429 counts, and cooldowns |
| **`POST /v1/generate`** | Core generation gateway | `200 OK` on success, `400 Bad Request`, `422 Unprocessable` on QA failure, `502 Bad Gateway` |

### Model Routing Tiers & Parameters

| Quality Tier | Base Coin Cost | Visual Model Target | Video Model Target | Max Retries | Timeout |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`FAST`** | 5 Coins | `gemini-2.5-flash-image` | `veo-2-fast` | 1 | 12,000 ms |
| **`STANDARD`** | 10 Coins | `imagen-3.0-generate` | `veo-2-standard` | 2 | 25,000 ms |
| **`CINEMATIC`** | 20 Coins | `imagen-3.0-ultra` | `veo-2-cinematic` | 2 | 45,000 ms |

### Key Architectural Mechanisms
1. **Multi-Project Key Pool (`keyPool.ts`):**
   - Ingests keys from `AI_KEY_POOL_JSON` or `AI_API_KEYS` across multiple GCP projects and regions (`europe-west3`, `europe-west1`).
   - Uses **Least-Latency EMA** selection among healthy keys.
   - Circuit-breaker kicks in on 429 (exponential backoff from 15s to 300s) or repeated 5xx errors (quarantine).
2. **SHA-256 Deduplication Cache (`cache.ts`):**
   - Generates deterministic hash over input payload.
   - Cache hit immediately invokes `callCaptureCoins` and returns stored artifact without calling upstream AI models.
3. **Anatomical Quality Guard & Self-Correction (`qualityGuard.ts`):**
   - Validates anatomical score, facial consistency, and garment alignment against `MIN_ANATOMICAL_SCORE` (default 0.8).
   - If QA fails, attempts 1 automatic self-correction pass before rejecting.
   - Injects mandatory Persian watermark: `"ساختهشده با هوش مصنوعی"`.
4. **Autonomous Hold Finalization (`index.ts`):**
   - On successful QA and watermarking $\rightarrow$ invokes `callCaptureCoins` via internal secret.
   - On generation error or anatomical rejection $\rightarrow$ invokes `callReleaseCoins` to immediately refund user coins.
5. **`USE_MOCK_AI` Toggle:**
   - When `USE_MOCK_AI=true`, runs mock generator with realistic latency jitter (`MOCK_AI_LATENCY_MS`, default 140ms) and mock storage URLs.

---

## 5. Frontend Architecture, State Management & Naming (`app/lib/`)

### Riverpod Providers & Notifiers Registry

| Provider Name | Type | File Location | Purpose & Subscribed Entities |
| :--- | :--- | :--- | :--- |
| **`localeProvider`** | `StateNotifierProvider<LocaleNotifier, AppLanguage>` | `core/localization/locale_provider.dart` | Manages active locale (`fa`, `en`, `ar`, `tr`) and reactive text directionality (`RTL` vs `LTR`). |
| **`themeProvider`** | `StateNotifierProvider<ThemeNotifier, ThemeState>` | `core/theme/theme_provider.dart` | Controls 5 fashion color palettes (`white`, `beige`, `slate`, `obsidian`, `editorial`) and 3 brightness modes (`Light`, `Dark`, `System`). |
| **`appStateProvider`** | `StateNotifierProvider<AppStateNotifier, AppState>` | `core/state/app_state.dart` | Global UI state: active bottom nav tab (0 to 4), coin balance, notification feed, floating support widget, companion character configuration. |
| **`aiGatewayClientProvider`** | `Provider<AiGatewayClient>` | `core/services/ai_gateway_client.dart` | Client connecting to AI Gateway microservice with automatic local simulation fallback. |
| **`healthServiceProvider`** | `StateNotifierProvider<HealthService, HealthDnaSnapshot>` | `core/services/health_service.dart` | Hardware streaming from HealthKit / Health Connect with granular user consent management. |
| **`wardrobeProvider`** | `StateNotifierProvider<WardrobeNotifier, WardrobeState>` | `features/wardrobe/presentation/wardrobe_provider.dart` | Wardrobe item state, active category filter, favorites toggle, and search queries. |
| **`shopProvider`** | `StateNotifierProvider<ShopNotifier, ShopState>` | `features/shop/presentation/shop_provider.dart` | Shop product catalog, category filters, gender selector, and price range sliders. |
| **`stylistProvider`** | `StateNotifierProvider<StylistNotifier, StylistState>` | `features/stylist/presentation/stylist_provider.dart` | Stylist outfits, chat message stream, and try-on modal execution with `AiGatewayClient`. |
| **`atelierProvider`** | `StateNotifierProvider<AtelierNotifier, AtelierState>` | `features/atelier/presentation/atelier_provider.dart` | Portrait & video templates, user creations progress tracking, and generation flow with `AiGatewayClient`. |
| **`wellnessProvider`** | `StateNotifierProvider<WellnessNotifier, WellnessState>` | `features/wellness/presentation/wellness_provider.dart` | Skin/hair/mind health scores, daily routine tasks, and analysis trigger with `AiGatewayClient`. |

### Base Reusable Widgets (`app/lib/core/widgets/`)
All UI screens wrap UI through these token-based base widgets:
- `AppButton`: Token-based primary, secondary, outline, and ghost variants.
- `AppCard`: Standard, surface, elevated, and interactive cards.
- `AppBadge`: Status, count, and pill badges with theme awareness.
- `AppChip`: Selectable category and filter chips.
- `AppDropdown`: Generic styled dropdown selector.
- `AppHeader`: Fixed upper app bar with avatar, balance pill, and language/theme triggers.
- `AppIconButton`: Bounded icon action buttons.
- `AppLogo`: Scalable SVG/vector brand mark.
- `AppModal`: Responsive popups and action sheets.
- `AppSectionHeader`: Typography-aligned section headers with action buttons.
- `AppSegmentedControl`: Animated tab-bar switcher.
- `AppSwitch`: Cupertino/Material styled toggle switch.
- `AppTextField`: Text inputs with inline validation and RTL/LTR directional support.
- `ShadThemeScope`: Scoped injection of `shadcn_ui` theme tokens.

### Current Connectivity Status (Live vs Mock)

| Subsystem / Feature | Implementation State | Connectivity Details |
| :--- | :--- | :--- |
| **AI Gateway Service** | **LIVE (Connected)** | Actively connects to `http://localhost:8081/v1/generate`. Generates collision-resistant idempotency keys, computes SHA-256 style fingerprints, and cleanly falls back to local simulation if the gateway daemon is offline. |
| **Wearable Health DNA** | **LIVE (Hardware/Simulated)** | MethodChannel `com.stylemorph/health` handles Apple HealthKit / Google Health Connect data with fallback simulation and passes biometric hints to `AiGatewayClient`. |
| **Multi-Language Engine** | **LIVE (Connected)** | Complete `.arb` translation coverage (`fa`, `en`, `ar`, `tr`) with instant runtime RTL/LTR direction switching and Persian/Western digit formatting. |
| **Theme System** | **LIVE (Connected)** | 5 fashion palettes + Light/Dark/System auto mode seamlessly wired into `ThemeNotifier` and `ShadThemeScope`. |
| **Wardrobe Repository** | **MOCK (In-Memory)** | `WardrobeRepository` manages a static in-memory list of 22 items. Not yet reading/writing to `users/{userId}/wardrobe`. |
| **Atelier Repository** | **MOCK (In-Memory)** | Template catalog (10 items) and creation history are stored in memory; generation jobs are dispatched to `AiGatewayClient`. |
| **Stylist Repository** | **MOCK (In-Memory)** | Outfits and chat messages are held in local state; virtual try-on dispatches to `AiGatewayClient`. |
| **Shop Repository** | **MOCK (In-Memory)** | 6 static products with multiple sellers stored in memory. Outbound seller links open external URLs. |
| **Wellness Repository** | **MOCK (In-Memory)** | Static baseline wellness scores and checklist tasks; analysis dispatches to `AiGatewayClient`. |
| **Wallet & Ledger** | **MOCK (In-Memory)** | `AppState.coinBalance` is held in Riverpod memory. Does not yet query `users/{userId}.walletBalance` or execute the `holdCoins` callable Cloud Function. |
| **Firebase Client SDK** | **PRE-ARCHITECTED** | `EmulatorConfig` exists in `core/services/emulator_config.dart`, but `firebase_core`, `firebase_auth`, and `cloud_firestore` are not yet added to `app/pubspec.yaml`. |

---

## 6. Admin & Seller Panel Status (`admin/`)

### Unified Flutter Web Architecture

The dual-stack implementation in `admin/` has been completely eliminated. All legacy Vanilla JS files (`server.mjs`, root `index.html`, `src/`, `styles/`, `tests/admin.test.mjs`) have been permanently removed. **Flutter Web (`shadcn_ui` + Riverpod)** is the single, unified production source of truth.

```
admin/
├── firebase.json                   # Hosting config: "public": "build/web" with SPA rewrite ("**" -> "/index.html")
├── pubspec.yaml                    # Flutter Web SDK (^3.12.2), flutter_riverpod, shadcn_ui, intl
├── analysis_options.yaml           # Strict static analysis rules (0 warnings, 0 issues)
├── assets/fonts/                   # Localized Vazirmatn fonts (Regular, Medium, SemiBold, Bold)
├── web/                            # Flutter Web runner (index.html, manifest.json, icons)
├── build/web/                      # Compiled production release artifacts (flutter build web --release)
├── test/
│   └── admin_panel_test.dart       # Comprehensive 8-test suite (3-Way Gate, 8 Sections, Seller Isolation, RTL)
└── lib/
    ├── main.dart                   # StyleMorphAdminApp with 3-Way Auth Gate routing & ShadTheme
    ├── core/
    │   ├── theme/                  # 5 Fashion Palettes (White, Warm Beige, Slate, Obsidian, Editorial)
    │   ├── localization/           # AdminLanguage (Persian RTL default, Arabic, English, Turkish)
    │   ├── state/                  # Single centralized Riverpod state store (AdminState)
    │   └── widgets/                # Reusable shadcn_ui base widgets (AppCard, AppButton, AppBadge, AppSwitchTile, etc.)
    └── features/
        ├── auth/                   # 3-Way Auth Gate (Admin, Seller Portal, Consumer Web)
        ├── layout/                 # AdminScaffold & AdminSidebar (8 clean Persian sections)
        ├── dashboard/              # Section 1: Command Dashboard (Global KPIs, Latency Heatmap, 8-Section Deep-links)
        ├── finance/                # Section 2: Immutable Double-Entry Ledger, CSV Export & Hold/Capture
        ├── modules/                # Section 3: 6 Mobile App Domains (Profile, Wardrobe, Shop, Stylist, Atelier, Wellness)
        ├── ai_gateway/             # Section 4: AI Gateway, Multi-Key Pool Balancing, Model Routing & Visual QA
        ├── sellers/                # Section 5: Merchant Governance, Approvals Queue, CPC/CPM & Commission Rules
        ├── settings/               # Section 6: Infrastructure Settings (Remote Config, Users/RBAC, Bot Hub, PITR Backup)
        ├── ads/                    # Section 7: AdMob SSV, Adaptive Generosity Engine & Permanent Wellness Lock
        ├── support/                # Section 8: Context-Aware Support Desk, Device Specs, AI Error Logs & 1-Click Refund
        └── seller_portal/          # Isolated B2B Merchant Portal (seller_scaffold.dart: Products, Campaigns, Wallet)
```

### 3-Way Auth Gate & RBAC Matrix

| Portal / Role | Access Path | Allowed Views | Key Capabilities & Isolation Guards |
| :--- | :--- | :--- | :--- |
| **Central Admin (`admin`)** | Root Gate $\rightarrow$ Admin Portal | 8 Central Sections: Dashboard, Finance, Modules, AI Gateway, Sellers, Settings, Ads, Support | Full system control: manual financial reversal, multi-key pool balancing, Remote Config sync, single-device session invalidation, PITR backup trigger. |
| **Seller Portal (`seller`)** | Root Gate $\rightarrow$ Seller Portal | Isolated Merchant Views: Store Dashboard, Products Catalog, Ad Campaigns, Wallet | **Strict Multi-Tenant Isolation**: Completely separated in `seller_scaffold.dart`. Zero access to Admin sidebar, global finance, users, or system infrastructure. |
| **Consumer Web (`consumerWebapp`)** | Root Gate $\rightarrow$ Consumer Web | Consumer Web Portal: Virtual Wardrobe, AI Stylist, Virtual Atelier, Wellness | Preview client experience for consumers (`app.stylemorph.com`) with quick return to the unified gate. |

### Data Sources
Directly backed by the reactive Riverpod store in `admin/lib/core/state/admin_state.dart`, wired to remote configurations and prepared for live Firestore and Cloud Functions Gen 2 API endpoints.

---

## 7. Verification & Test Suite Health

| Component | Test Runner | Command | Test Suites / Tests | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Functions** | Jest / ts-jest | `npm --prefix backend/functions test` | 2 suites, 16 unit tests | **100% PASS** |
| **AI Gateway** | Node Test Runner | `npm --prefix backend/ai-gateway test` | 1 suite, 4 tests | **100% PASS** |
| **Admin & Portals** | Flutter Test | `Push-Location admin; flutter test; Pop-Location` | 3 groups, 8 comprehensive tests | **100% PASS** |
| **Flutter Mobile App** | Flutter Test | `flutter test` (in `app/`) | 6 suites, 39 widget/integration tests | **100% PASS** |

---

## 8. Summary of Architectural Findings for Next Steps

1. **Backend Financial Core is Complete & Tested:** The Cloud Functions suite (`backend/functions/`) has a production-ready, atomic `holdCoins -> captureCoins / releaseCoins` financial engine with idempotency, double-spend prevention, single-device session invalidation, and tri-channel payment webhooks (IAP, Stripe, Crypto).
2. **AI Gateway Microservice is Operational:** The `ai-gateway/` service properly coordinates multi-key load balancing, SHA-256 deduplication caching, anatomical QA gating, watermark injection, and financial callbacks.
3. **Frontend Repositories are Mock-Backed:** While `AiGatewayClient` and `HealthService` are live and actively tested in Flutter, the primary repositories (`WardrobeRepository`, `ShopRepository`, `AtelierRepository`, `StylistRepository`, `WellnessRepository`) and `coinBalance` remain in-memory mock implementations.
4. **Firebase Client SDK Pending in App:** `app/pubspec.yaml` currently does not include `firebase_core`, `firebase_auth`, or `cloud_firestore`. Wire-up of `EmulatorConfig` to live Firebase SDKs is the clear next architectural step.
5. **Admin Panel 100% Unified on Flutter Web:** The dual implementation in `admin/` has been eliminated. Vanilla JS files have been pruned, `admin/firebase.json` serves `"build/web"` with SPA rewrites, and the panel is completely unified on Flutter Web (`shadcn_ui` + Riverpod) with full test coverage, zero linter issues, and production compilation verified.

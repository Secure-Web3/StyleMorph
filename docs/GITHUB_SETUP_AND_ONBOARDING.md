# StyleMorph — GitHub Setup & Fresh Machine Onboarding Guide
> **Repository Migration & Zero-Dependency Onboarding Manual**

---

## 🇮🇷 ۱. خلاصه اجرایی و راه‌اندازی سریع پروژه (Persian Executive Summary)

این سند راهنمای گام‌به‌گام راه‌اندازی کامل ریپازیتوری **StyleMorph** پس از کلون کردن از گیت‌هاب خصوصی (Private GitHub Repository) روی هر سیستم یا محیط کاری جدید است. مخزن به‌گونه‌ای ایزوله و مستقل از محیط محلی پیکربندی شده است که **هیچ وابستگی پنهان، فایل دیتابیس باینری یا اطلاعات حساسی** در آن وجود ندارد و تمام داده‌های آزمایشی فایربیس از طریق اسکریپت کد-محور (`npm run seed`) ساخته می‌شوند.

### مراحل سریع راه‌اندازی:
1. کلون کردن ریپازیتوری از گیت‌هاب: `git clone <REPO_URL>`
2. نصب پکیج‌های کلاینت‌ها: اجرای `flutter pub get` در هر دو پوشه `app/` و `admin/`
3. نصب پکیج‌های بک‌اند: اجرای `npm install` در هر دو پوشه `backend/functions/` و `backend/ai-gateway/`
4. ایجاد فایل‌های محیطی: کپی کردن `.env.example` به `.env` در پوشه‌های بک‌اند
5. اجرای ایمولاتورهای فایربیس: `firebase emulators:start` در ریشه پروژه
6. سیدینگ خودکار دیتابیس: اجرای `npm run seed` در پوشه `backend/functions/`

---

## 2. System Prerequisites

Ensure the following tools and runtimes are installed on the workstation:

| Component | Minimum Version | Verification Command | Notes |
| :--- | :--- | :--- | :--- |
| **Git** | `2.40+` | `git --version` | Source control |
| **Node.js** | `20.x LTS` | `node -v` | Required for Cloud Functions Gen 2 & AI Gateway |
| **npm** | `10.x+` | `npm -v` | Node package manager |
| **Flutter SDK** | `3.24+` (Channel stable) | `flutter --version` | Dart 3.5+ included |
| **Firebase CLI** | `13.x+` | `firebase --version` | `npm install -g firebase-tools` |
| **Java JDK** | `17+` or `21+` | `java -version` | Required by Firebase Emulator Suite |

---

## 3. Fresh Machine Initialization Steps

### Step 3.1: Clone the Private Repository
```bash
git clone git@github.com:<YOUR_USERNAME>/stylemorph.git
cd stylemorph
```

---

### Step 3.2: Configure Safe Environment Variables
The repository contains zero plaintext secrets. Copy the template configurations:

```bash
# In backend/functions:
cp backend/functions/.env.example backend/functions/.env

# In backend/ai-gateway:
cp backend/ai-gateway/.env.example backend/ai-gateway/.env
```

*(On Windows PowerShell, use `Copy-Item backend/functions/.env.example backend/functions/.env`)*

---

### Step 3.3: Install All Workspace Dependencies

#### A. Mobile App (`app/`):
```bash
cd app
flutter pub get
cd ..
```

#### B. Admin & Seller Web Panel (`admin/`):
```bash
cd admin
flutter pub get
cd ..
```

#### C. Firebase Cloud Functions (`backend/functions/`):
```bash
cd backend/functions
npm install
npm run build
cd ../..
```

#### D. AI Gateway & Multi-Key Load Balancer (`backend/ai-gateway/`):
```bash
cd backend/ai-gateway
npm install
npm run build
cd ../..
```

---

## 4. Local Emulator Suite & Code-Driven Database Seeding

StyleMorph does **NOT** rely on binary Firestore emulator dumps or committed `.firebase` snapshots. All emulator state is generated dynamically from code.

### Step 4.1: Start Firebase Emulators
In the root directory (`D:\StyleMorph`):
```bash
firebase emulators:start
```
This boots up:
- **Firebase Auth Emulator**: `http://127.0.0.1:9099`
- **Cloud Firestore Emulator**: `http://127.0.0.1:8080`
- **Cloud Functions Emulator**: `http://127.0.0.1:5001`
- **Firebase Emulator UI**: `http://127.0.0.1:4000`

---

### Step 4.2: Seed Offline Auth & Firestore Collections
In a separate terminal, execute the automated seeding script:

```bash
cd backend/functions
npm run seed
```

This automatically initializes the following test dataset:

### 🔑 Seeded Demo User Credentials

| Role | Email | Password | UID | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | `admin@stylemorph.com` | `Password123!` | `adm_super_01` | Full permissions (`*`), Web Admin access |
| **Finance Sub-Admin** | `taghavi@stylemorph.com` | `Password123!` | `adm_fin_01` | Ledger inspection, reverse transactions |
| **Seller Agent** | `seller@stylemorph.com` | `Password123!` | `seller_zara_01` | Zara official representative store |
| **Consumer Profile** | `sara.ahmadi@gmail.com` | `Password123!` | `usr_sara_88` | **350 StyleCoins**, LVL 1, Gold Tier, Device-bound |

### 📦 Seeded Datasets in Firestore
- `users/usr_sara_88`: Complete anatomy (`aiDna`), wallet balance (`350`), single-device lock (`dev_sara_iphone15_uuid`).
- `users/usr_sara_88/wardrobe/*`: 3 sample wardrobe items with SHA-256 visual hashes.
- `shops/seller_zara_01` & `products/*`: Verified store catalog with sample products and redirect URLs.
- `ledger/tx_sara_welcome_350`: Immutable financial record proving the 350 onboarding coins.
- `system_config/wallet_promo`: Dynamic Remote Config document with **Store Reviewer Shield** build filters (`[100, 101, 102]`).

---

## 5. Running the Subsystems Locally

### 5.1 Run AI Gateway (Cloud Run service)
```bash
cd backend/ai-gateway
npm start
# Listens on http://127.0.0.1:8081
```

### 5.2 Run Mobile Application (Flutter)
```bash
cd app
flutter run
```

### 5.3 Run Admin & Seller Web Dashboard (Flutter Web)
```bash
cd admin
flutter run -d chrome --web-port 8080
```

---

## 6. Security & Contribution Rules

1. **Strictly Forbidden Commits**:
   - Never commit `*.env`, `.env.local`, `google-services.json`, `GoogleService-Info.plist`, or `*service-account*.json`.
   - Never commit compiled artifacts (`build/`, `dist/`, `.dart_tool/`, `node_modules/`).
2. **Deterministic Seeding**:
   - If new collection schemas or default documents are added to the platform, update `backend/functions/src/scripts/seed.ts` and test with `npm run seed`.
3. **Architecture Adherence**:
   - Review [`AGENTS.md`](../AGENTS.MD) and [`docs/CURRENT_ARCHITECTURE.md`](./CURRENT_ARCHITECTURE.md) before submitting pull requests.

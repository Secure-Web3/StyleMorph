/**
 * ============================================================================
 * StyleMorph Firebase Emulator Database & Auth Seeding Script
 * ----------------------------------------------------------------------------
 * Connects directly to local Firebase Auth & Firestore emulators and seeds:
 * 1. RBAC Demo Users (Super Admin, Sub-Admin Finance, Verified Seller)
 * 2. Standard Mobile User Profile: Sara Ahmadi (350 StyleCoins, Single-Device binding, LVL 1)
 * 3. Sample Wardrobe items with AI-extracted metadata & SHA-256 image hashes
 * 4. Sample Shops & Certified Fashion Products (with redirect links & stats)
 * 5. Immutable Ledger entry verifying initial 350 StyleCoin onboarding credit
 * 6. Dynamic System Config (`system_config/wallet_promo`) with Store Reviewer Shield
 * ============================================================================
 */

import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

// Target local emulator suite by default
process.env["FIRESTORE_EMULATOR_HOST"] =
  process.env["FIRESTORE_EMULATOR_HOST"] ?? "127.0.0.1:8080";
process.env["FIREBASE_AUTH_EMULATOR_HOST"] =
  process.env["FIREBASE_AUTH_EMULATOR_HOST"] ?? "127.0.0.1:9099";

const PROJECT_ID = process.env["GCLOUD_PROJECT"] ?? "stylemorph-dev";

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const auth = getAuth();
const db = getFirestore();

interface SeedUserParams {
  uid: string;
  email: string;
  password: string;
  displayName: string;
  phoneNumber?: string;
  customClaims: Record<string, unknown>;
}

async function upsertAuthUser(params: SeedUserParams): Promise<void> {
  try {
    await auth.getUser(params.uid);
    await auth.updateUser(params.uid, {
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      ...(params.phoneNumber ? { phoneNumber: params.phoneNumber } : {}),
    });
    console.log(`  [Auth] Updated existing user: ${params.email} (${params.uid})`);
  } catch (err: unknown) {
    const error = err as { code?: string };
    if (error.code === "auth/user-not-found") {
      await auth.createUser({
        uid: params.uid,
        email: params.email,
        password: params.password,
        displayName: params.displayName,
        ...(params.phoneNumber ? { phoneNumber: params.phoneNumber } : {}),
      });
      console.log(`  [Auth] Created user: ${params.email} (${params.uid})`);
    } else {
      throw err;
    }
  }

  await auth.setCustomUserClaims(params.uid, params.customClaims);
}

export async function runSeed(): Promise<void> {
  console.log("=================================================================");
  console.log("🚀 Starting StyleMorph Emulator Database Seeding...");
  console.log(`   Project ID: ${PROJECT_ID}`);
  console.log(`   Firestore Host: ${process.env["FIRESTORE_EMULATOR_HOST"]}`);
  console.log(`   Auth Host:      ${process.env["FIREBASE_AUTH_EMULATOR_HOST"]}`);
  console.log("=================================================================\n");

  const now = Timestamp.now();

  // ---------------------------------------------------------------------------
  // 1. Auth & Admin RBAC Demo Accounts
  // ---------------------------------------------------------------------------
  console.log("📦 1. Seeding Auth & RBAC Users...");

  const demoUsers: SeedUserParams[] = [
    {
      uid: "adm_super_01",
      email: "admin@stylemorph.com",
      password: "Password123!",
      displayName: "مهندس سهرابی (Super Admin)",
      customClaims: {
        role: "SUPER_ADMIN",
        permissions: ["*"],
        activeDeviceId: "sess_adm_root_7788",
      },
    },
    {
      uid: "adm_fin_01",
      email: "taghavi@stylemorph.com",
      password: "Password123!",
      displayName: "علی تقوی (Sub-Admin Finance)",
      customClaims: {
        role: "SUB_ADMIN_FINANCE",
        permissions: ["READ_LEDGER", "REVERSE_TX", "EXPORT_CSV"],
        activeDeviceId: "sess_adm_fin_9911",
      },
    },
    {
      uid: "seller_zara_01",
      email: "seller@stylemorph.com",
      password: "Password123!",
      displayName: "نماینده رسمی زارا (Zara Iran)",
      customClaims: {
        role: "SELLER",
        permissions: ["MANAGE_PRODUCTS", "VIEW_ANALYTICS"],
        sellerId: "seller_zara_01",
      },
    },
    {
      uid: "usr_sara_88",
      email: "sara.ahmadi@gmail.com",
      password: "Password123!",
      displayName: "سارا احمدی",
      phoneNumber: "+989128889900",
      customClaims: {
        role: "USER",
        tier: "GOLD",
        activeDeviceId: "dev_sara_iphone15_uuid",
      },
    },
  ];

  for (const u of demoUsers) {
    await upsertAuthUser(u);
  }

  // ---------------------------------------------------------------------------
  // 2. Firestore User Documents
  // ---------------------------------------------------------------------------
  console.log("\n👤 2. Seeding Firestore User Profiles...");

  // Super Admin Document
  await db.collection("users").doc("adm_super_01").set({
    userId: "adm_super_01",
    displayName: "مهندس سهرابی",
    email: "admin@stylemorph.com",
    role: "SUPER_ADMIN",
    permissions: ["*"],
    activeDeviceId: "sess_adm_root_7788",
    activeSessionId: "sess_adm_root_7788",
    createdAt: now,
    updatedAt: now,
  });

  // Sub-Admin Finance Document
  await db.collection("users").doc("adm_fin_01").set({
    userId: "adm_fin_01",
    displayName: "علی تقوی",
    email: "taghavi@stylemorph.com",
    role: "SUB_ADMIN_FINANCE",
    permissions: ["READ_LEDGER", "REVERSE_TX", "EXPORT_CSV"],
    activeDeviceId: "sess_adm_fin_9911",
    activeSessionId: "sess_adm_fin_9911",
    createdAt: now,
    updatedAt: now,
  });

  // Seller User Document
  await db.collection("users").doc("seller_zara_01").set({
    userId: "seller_zara_01",
    displayName: "نماینده رسمی زارا",
    email: "seller@stylemorph.com",
    role: "SELLER",
    sellerId: "seller_zara_01",
    createdAt: now,
    updatedAt: now,
  });

  // Sara Ahmadi User Document (350 StyleCoins, Single Device Enforced, LVL 1)
  await db.collection("users").doc("usr_sara_88").set({
    userId: "usr_sara_88",
    displayName: "سارا احمدی",
    email: "sara.ahmadi@gmail.com",
    userHandle: "@sara_ahmadi",
    phone: "۰۹۱۲۸۸۸۹۹۰۰",
    role: "USER",
    tier: "GOLD",
    level: "LVL 1",
    levelNumber: 1,
    coinBalance: 350,
    walletBalance: 350,
    heldBalance: 0,
    activeDeviceId: "dev_sara_iphone15_uuid",
    activeSessionId: "sess_sara_valid_session",
    aiDna: {
      height: 168,
      weight: 58,
      bodyType: "hourglass",
      skinTone: "warm_ivory",
      bust: 88,
      waist: 64,
      hips: 92,
      shoeSize: "38",
      colorSeason: "AUTUMN",
    },
    settings: {
      locale: "fa",
      theme: "Luxury Warm Beige",
      notificationsEnabled: true,
      biometricsEnabled: true,
    },
    createdAt: now,
    updatedAt: now,
  });
  console.log("  [Firestore] Created/Updated Sara Ahmadi profile with 350 StyleCoins (LVL 1).");

  // ---------------------------------------------------------------------------
  // 3. Sara Ahmadi's Virtual Wardrobe Items
  // ---------------------------------------------------------------------------
  console.log("\n👗 3. Seeding Sara's Virtual Wardrobe items...");

  const wardrobeItems = [
    {
      id: "item_wardrobe_01",
      name: "پیراهن کتان آستین‌بلند",
      category: "cl",
      subCategory: "shirt",
      colorName: "آبی روشن",
      colorHex: "#6b8fb5",
      season: "بهار",
      occasion: "روزمره",
      material: "کتان ۱۰۰٪",
      size: "M",
      isFavorite: true,
      isArchived: false,
      imageHash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      thumbUrl: "https://storage.googleapis.com/stylemorph-dev/demo/wardrobe_01_thumb.webp",
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "item_wardrobe_02",
      name: "شلوار جین تیره راسته",
      category: "cl",
      subCategory: "jeans",
      colorName: "سرمه‌ای",
      colorHex: "#1b2a47",
      season: "همه",
      occasion: "روزمره",
      material: "جین کشی",
      size: "38",
      isFavorite: true,
      isArchived: false,
      imageHash: "f4c8996fb92427ae41e4649b934ca495991b7852b855e3b0c44298fc1c149afb",
      thumbUrl: "https://storage.googleapis.com/stylemorph-dev/demo/wardrobe_02_thumb.webp",
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "item_wardrobe_03",
      name: "کفش کتانی لژدار",
      category: "sh",
      subCategory: "sneakers",
      colorName: "سفید",
      colorHex: "#f8f9fa",
      season: "همه",
      occasion: "روزمره",
      material: "چرم صنعتی",
      size: "38",
      isFavorite: false,
      isArchived: false,
      imageHash: "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90",
      thumbUrl: "https://storage.googleapis.com/stylemorph-dev/demo/wardrobe_03_thumb.webp",
      createdAt: now,
      updatedAt: now,
    },
  ];

  for (const item of wardrobeItems) {
    await db
      .collection("users")
      .doc("usr_sara_88")
      .collection("wardrobe")
      .doc(item.id)
      .set(item);
    console.log(`  [Wardrobe] Added item: ${item.name} (${item.id})`);
  }

  // ---------------------------------------------------------------------------
  // 4. Shops & Products Catalog
  // ---------------------------------------------------------------------------
  console.log("\n🏬 4. Seeding Shops & Verified Fashion Products...");

  await db.collection("shops").doc("seller_zara_01").set({
    sellerId: "seller_zara_01",
    storeName: "فروشگاه زارا ایران (Zara Official Agent)",
    contactEmail: "seller@stylemorph.com",
    rating: 4.8,
    isVerified: true,
    walletBalanceToman: 5000000,
    activeCampaignsCount: 2,
    createdAt: now,
    updatedAt: now,
  });

  const sampleProducts = [
    {
      id: "prod_zara_linen_shirt",
      sellerId: "seller_zara_01",
      title: "پیراهن کتان خنک آستین‌بلند زارا",
      category: "cloth",
      brand: "زارا",
      priceToman: 480000,
      redirectUrl: "https://zara.example.com/items/linen-shirt-480",
      isActive: true,
      viewsCount: 1420,
      clicksCount: 310,
      tryOnCount: 85,
      approvalStatus: "APPROVED",
      rating: 4.6,
      sizes: ["S", "M", "L"],
      colors: ["آبی", "سفید"],
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "prod_nike_air_shoe",
      sellerId: "seller_zara_01",
      title: "کفش ورزشی ایر نایک مدل ۲۰۲۶",
      category: "shoe",
      brand: "نایک",
      priceToman: 1850000,
      redirectUrl: "https://nike.example.com/items/air-max-2026",
      isActive: true,
      viewsCount: 2200,
      clicksCount: 540,
      tryOnCount: 190,
      approvalStatus: "APPROVED",
      rating: 4.8,
      sizes: ["38", "39", "40", "41"],
      colors: ["سفید", "مشکی"],
      createdAt: now,
      updatedAt: now,
    },
  ];

  for (const prod of sampleProducts) {
    await db.collection("products").doc(prod.id).set(prod);
    console.log(`  [Shop Product] Added product: ${prod.title} (${prod.id})`);
  }

  // ---------------------------------------------------------------------------
  // 5. Immutable Financial Ledger Entry (Verifying 350 Coins)
  // ---------------------------------------------------------------------------
  console.log("\n📒 5. Seeding Immutable Financial Ledger Entry...");

  await db.collection("ledger").doc("tx_sara_welcome_350").set({
    txId: "tx_sara_welcome_350",
    userId: "usr_sara_88",
    type: "TOPUP",
    amount: 350,
    balanceBefore: 0,
    balanceAfter: 350,
    heldBefore: 0,
    heldAfter: 0,
    paymentProvider: "SYSTEM",
    baseCoins: 350,
    bonusCoins: 0,
    bonusPercent: 0,
    idempotencyKey: "idemp_sara_welcome_initial",
    reason: "Initial StyleCoins welcome bonus for new profile onboarding",
    createdAt: now,
  });
  console.log("  [Ledger] Recorded initial 350 Coin credit transaction (tx_sara_welcome_350).");

  // ---------------------------------------------------------------------------
  // 6. Dynamic System Config with Store Reviewer Shield
  // ---------------------------------------------------------------------------
  console.log("\n🛡️  6. Seeding Dynamic System Config (Store Reviewer Shield)...");

  await db.collection("system_config").doc("wallet_promo").set({
    killSwitch: false,
    underReviewBuildNumbers: ["100", "101", "102"],
    webBonusPercent: 20,
    cryptoBonusPercent: 20,
    webPortalUrl: "https://pay.stylemorph.com",
    minAccountAgeHours: 0,
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log("  [Config] Configured system_config/wallet_promo with build shield [100, 101, 102].");

  console.log("\n=================================================================");
  console.log("✅ Seeding completed successfully! All emulator collections ready.");
  console.log("=================================================================\n");
}

// Execute when invoked directly from command line
if (require.main === module) {
  runSeed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("\n❌ Seeding failed with error:", err);
      process.exit(1);
    });
}

import * as crypto from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import {
  captureCoins,
  holdCoins,
  releaseCoins,
} from "../services/financialEngine";

// Ensure Admin SDK targets the local Firebase Emulator Suite
process.env["FIRESTORE_EMULATOR_HOST"] =
  process.env["FIRESTORE_EMULATOR_HOST"] ?? "127.0.0.1:8080";
process.env["FIREBASE_AUTH_EMULATOR_HOST"] =
  process.env["FIREBASE_AUTH_EMULATOR_HOST"] ?? "127.0.0.1:9099";

const PROJECT_ID = "stylemorph-dev";

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();

async function seedUserWallet(
  userId: string,
  walletBalance: number,
  heldBalance = 0,
): Promise<void> {
  await db.collection("users").doc(userId).set({
    userId,
    walletBalance,
    heldBalance,
    role: "user",
    permissions: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function cleanupTestUser(userId: string): Promise<void> {
  const [holdsSnap, ledgerSnap] = await Promise.all([
    db.collection("wallet_holds").where("userId", "==", userId).get(),
    db.collection("ledger").where("userId", "==", userId).get(),
  ]);

  const batch = db.batch();
  batch.delete(db.collection("users").doc(userId));
  for (const doc of holdsSnap.docs) {
    batch.delete(doc.ref);
  }
  for (const doc of ledgerSnap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
}

describe("StyleMorph Atomic Financial Engine (Firestore Emulator)", () => {
  const createdUsers: string[] = [];

  function makeUserId(label: string): string {
    const uid = `test_${label}_${crypto.randomUUID().slice(0, 8)}`;
    createdUsers.push(uid);
    return uid;
  }

  afterAll(async () => {
    for (const uid of createdUsers) {
      await cleanupTestUser(uid);
    }
  });

  test("Test 1: Successful Hold -> Capture flow with immutable ledger verification", async () => {
    const userId = makeUserId("hold_capture");
    await seedUserWallet(userId, 100, 0);

    const holdKey = `hold_${crypto.randomUUID()}`;
    const holdRes = await holdCoins(
      userId,
      20,
      "ATELIER_PHOTO",
      "CINEMATIC",
      holdKey,
    );

    expect(holdRes.status).toBe("HELD");
    expect(holdRes.amount).toBe(20);
    expect(holdRes.availableBalance).toBe(80);
    expect(holdRes.heldBalance).toBe(20);
    expect(holdRes.idempotentReplay).toBe(false);

    const captureKey = `cap_${crypto.randomUUID()}`;
    const captureRes = await captureCoins(holdRes.holdId, captureKey, {
      jobId: "job_atelier_001",
      watermark: "ساختهشده با هوش مصنوعی",
      anatomicalScore: 0.96,
    });

    expect(captureRes.status).toBe("CAPTURED");
    expect(captureRes.amount).toBe(20);
    expect(captureRes.availableBalance).toBe(80);
    expect(captureRes.heldBalance).toBe(0);
    expect(captureRes.idempotentReplay).toBe(false);

    const userDoc = await db.collection("users").doc(userId).get();
    expect(userDoc.get("walletBalance")).toBe(80);
    expect(userDoc.get("heldBalance")).toBe(0);

    const holdDoc = await db
      .collection("wallet_holds")
      .doc(holdRes.holdId)
      .get();
    expect(holdDoc.get("status")).toBe("CAPTURED");
    expect(holdDoc.get("captureLedgerTxId")).toBe(captureRes.ledgerTxId);

    const ledgerSnap = await db
      .collection("ledger")
      .where("userId", "==", userId)
      .get();
    const entries = ledgerSnap.docs.map((d) => d.data());
    expect(entries).toHaveLength(2);

    const holdEntry = entries.find((e) => e["type"] === "HOLD");
    const captureEntry = entries.find((e) => e["type"] === "CAPTURE");

    expect(holdEntry).toBeDefined();
    expect(holdEntry?.["balanceBefore"]).toBe(100);
    expect(holdEntry?.["balanceAfter"]).toBe(80);
    expect(holdEntry?.["heldBefore"]).toBe(0);
    expect(holdEntry?.["heldAfter"]).toBe(20);

    expect(captureEntry).toBeDefined();
    expect(captureEntry?.["balanceBefore"]).toBe(80);
    expect(captureEntry?.["balanceAfter"]).toBe(80);
    expect(captureEntry?.["heldBefore"]).toBe(20);
    expect(captureEntry?.["heldAfter"]).toBe(0);
  });

  test("Test 2: Hold -> simulated AI failure -> automatic Release refund flow", async () => {
    const userId = makeUserId("hold_release");
    await seedUserWallet(userId, 50, 0);

    const holdRes = await holdCoins(
      userId,
      10,
      "VIRTUAL_TRYON",
      "STANDARD",
      `hold_${crypto.randomUUID()}`,
    );
    expect(holdRes.availableBalance).toBe(40);
    expect(holdRes.heldBalance).toBe(10);

    // Simulate AI validation / generation failure triggering automatic release
    const releaseRes = await releaseCoins(
      holdRes.holdId,
      "ANATOMICAL_VALIDATION_FAILED",
      `rel_${crypto.randomUUID()}`,
    );

    expect(releaseRes.status).toBe("RELEASED");
    expect(releaseRes.amount).toBe(10);
    expect(releaseRes.availableBalance).toBe(50);
    expect(releaseRes.heldBalance).toBe(0);
    expect(releaseRes.reason).toBe("ANATOMICAL_VALIDATION_FAILED");

    const userDoc = await db.collection("users").doc(userId).get();
    expect(userDoc.get("walletBalance")).toBe(50);
    expect(userDoc.get("heldBalance")).toBe(0);

    // Capturing an already-released hold must fail
    await expect(
      captureCoins(holdRes.holdId, `cap_after_rel_${crypto.randomUUID()}`),
    ).rejects.toThrow(/Cannot capture hold in status 'RELEASED'/);

    const ledgerSnap = await db
      .collection("ledger")
      .where("userId", "==", userId)
      .get();
    const releaseEntry = ledgerSnap.docs
      .map((d) => d.data())
      .find((e) => e["type"] === "RELEASE");
    expect(releaseEntry).toBeDefined();
    expect(releaseEntry?.["balanceBefore"]).toBe(40);
    expect(releaseEntry?.["balanceAfter"]).toBe(50);
    expect(releaseEntry?.["reason"]).toBe("ANATOMICAL_VALIDATION_FAILED");
  });

  test("Test 3: Idempotency protection returns existing transaction without double-charging", async () => {
    const userId = makeUserId("idempotency");
    await seedUserWallet(userId, 60, 0);

    const holdKey = `idem_hold_${crypto.randomUUID()}`;
    const firstHold = await holdCoins(
      userId,
      5,
      "VIRTUAL_TRYON",
      "FAST",
      holdKey,
    );
    const replayHold = await holdCoins(
      userId,
      5,
      "VIRTUAL_TRYON",
      "FAST",
      holdKey,
    );

    expect(firstHold.idempotentReplay).toBe(false);
    expect(replayHold.idempotentReplay).toBe(true);
    expect(replayHold.holdId).toBe(firstHold.holdId);
    expect(replayHold.ledgerTxId).toBe(firstHold.ledgerTxId);

    // Reusing the same idempotencyKey with different amount must be rejected
    await expect(
      holdCoins(userId, 10, "VIRTUAL_TRYON", "STANDARD", holdKey),
    ).rejects.toThrow(/different hold payload/i);

    const userAfterHold = await db.collection("users").doc(userId).get();
    expect(userAfterHold.get("walletBalance")).toBe(55);
    expect(userAfterHold.get("heldBalance")).toBe(5);

    const capKey = `idem_cap_${crypto.randomUUID()}`;
    const firstCapture = await captureCoins(firstHold.holdId, capKey);
    const replayCapture = await captureCoins(firstHold.holdId, capKey);

    expect(firstCapture.idempotentReplay).toBe(false);
    expect(replayCapture.idempotentReplay).toBe(true);
    expect(replayCapture.ledgerTxId).toBe(firstCapture.ledgerTxId);

    const ledgerSnap = await db
      .collection("ledger")
      .where("userId", "==", userId)
      .get();
    expect(ledgerSnap.size).toBe(2);
  });

  test("Test 4: Insufficient funds rejection prevents negative balances under concurrent requests", async () => {
    const userId = makeUserId("concurrency");
    await seedUserWallet(userId, 15, 0);

    // Single request exceeding balance must reject cleanly
    await expect(
      holdCoins(
        userId,
        20,
        "ATELIER_VIDEO",
        "CINEMATIC",
        `overdraft_${crypto.randomUUID()}`,
      ),
    ).rejects.toThrow(/INSUFFICIENT_FUNDS/);

    // Fire 5 concurrent 10-coin holds against a 15-coin wallet:
    // Strictly 1 must succeed and 4 must fail with INSUFFICIENT_FUNDS.
    const concurrentRequests = Array.from({ length: 5 }, (_, idx) =>
      holdCoins(
        userId,
        10,
        "VIRTUAL_TRYON",
        "STANDARD",
        `race_${idx}_${crypto.randomUUID()}`,
      ),
    );

    const outcomes = await Promise.allSettled(concurrentRequests);
    const fulfilled = outcomes.filter((o) => o.status === "fulfilled");
    const rejected = outcomes.filter((o) => o.status === "rejected");

    expect(fulfilled).toHaveLength(1);
    expect(rejected).toHaveLength(4);

    for (const rej of rejected) {
      if (rej.status === "rejected") {
        expect(String(rej.reason)).toMatch(/INSUFFICIENT_FUNDS/);
      }
    }

    const userDoc = await db.collection("users").doc(userId).get();
    const finalWallet = userDoc.get("walletBalance") as number;
    const finalHeld = userDoc.get("heldBalance") as number;

    expect(finalWallet).toBe(5);
    expect(finalHeld).toBe(10);
    expect(finalWallet).toBeGreaterThanOrEqual(0);
  });
});

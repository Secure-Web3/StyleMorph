import * as crypto from "node:crypto";

// ── In-Memory Transactional Firestore Mock ──────────────────────────────────
// Simulates document snapshots, query filters, FieldValue.serverTimestamp(),
// and atomic optimistic-concurrency transactions for standalone unit tests.

type DocData = Record<string, unknown>;

interface StoredDoc {
  version: number;
  data: DocData;
}

const collections = new Map<string, Map<string, StoredDoc>>();
let autoIdCounter = 0;

function getCollectionMap(name: string): Map<string, StoredDoc> {
  let map = collections.get(name);
  if (!map) {
    map = new Map<string, StoredDoc>();
    collections.set(name, map);
  }
  return map;
}

function cloneData<T>(value: T): T {
  return structuredClone(value);
}

class MockDocRef {
  constructor(
    public readonly collectionName: string,
    public readonly id: string,
  ) {}

  async get(): Promise<MockDocSnap> {
    const stored = getCollectionMap(this.collectionName).get(this.id);
    return new MockDocSnap(
      this.id,
      stored ? cloneData(stored.data) : undefined,
      stored ? stored.version : 0,
    );
  }

  async set(data: DocData): Promise<void> {
    const map = getCollectionMap(this.collectionName);
    const prev = map.get(this.id);
    map.set(this.id, {
      version: (prev?.version ?? 0) + 1,
      data: cloneData(data),
    });
  }
}

class MockDocSnap {
  constructor(
    public readonly id: string,
    private readonly _data: DocData | undefined,
    public readonly version: number,
  ) {}

  get exists(): boolean {
    return this._data !== undefined;
  }

  data(): DocData | undefined {
    return this._data ? cloneData(this._data) : undefined;
  }

  get(field: string): unknown {
    return this._data ? this._data[field] : undefined;
  }
}

class MockQuery {
  constructor(
    private readonly collectionName: string,
    private readonly field: string,
    private readonly value: unknown,
  ) {}

  async get(): Promise<{ docs: MockDocSnap[]; size: number }> {
    const map = getCollectionMap(this.collectionName);
    const docs: MockDocSnap[] = [];
    for (const [id, stored] of map.entries()) {
      if (stored.data[this.field] === this.value) {
        docs.push(new MockDocSnap(id, cloneData(stored.data), stored.version));
      }
    }
    return { docs, size: docs.length };
  }
}

class MockTransaction {
  private readonly readVersions = new Map<string, number>();
  private readonly stagedWrites: Array<{
    ref: MockDocRef;
    mode: "set" | "update";
    data: DocData;
  }> = [];

  private keyFor(ref: MockDocRef): string {
    return `${ref.collectionName}/${ref.id}`;
  }

  async get(ref: MockDocRef): Promise<MockDocSnap> {
    const stored = getCollectionMap(ref.collectionName).get(ref.id);
    const version = stored?.version ?? 0;
    this.readVersions.set(this.keyFor(ref), version);
    return new MockDocSnap(
      ref.id,
      stored ? cloneData(stored.data) : undefined,
      version,
    );
  }

  set(ref: MockDocRef, data: DocData): this {
    this.stagedWrites.push({ ref, mode: "set", data: cloneData(data) });
    return this;
  }

  update(ref: MockDocRef, patch: DocData): this {
    this.stagedWrites.push({ ref, mode: "update", data: cloneData(patch) });
    return this;
  }

  commit(): boolean {
    for (const [key, expectedVersion] of this.readVersions.entries()) {
      const [col, id] = key.split("/");
      const currentVersion = getCollectionMap(col).get(id)?.version ?? 0;
      if (currentVersion !== expectedVersion) {
        return false; // Optimistic concurrency conflict -> trigger retry
      }
    }

    for (const write of this.stagedWrites) {
      const map = getCollectionMap(write.ref.collectionName);
      const existing = map.get(write.ref.id);
      if (write.mode === "set") {
        map.set(write.ref.id, {
          version: (existing?.version ?? 0) + 1,
          data: write.data,
        });
      } else {
        const merged = { ...(existing?.data ?? {}), ...write.data };
        map.set(write.ref.id, {
          version: (existing?.version ?? 0) + 1,
          data: merged,
        });
      }
    }
    return true;
  }
}

const mockFirestoreInstance = {
  collection(name: string) {
    return {
      doc(id?: string) {
        const docId = id ?? `auto_${++autoIdCounter}`;
        return new MockDocRef(name, docId);
      },
      where(field: string, _op: string, value: unknown) {
        return new MockQuery(name, field, value);
      },
    };
  },
  async runTransaction<T>(fn: (tx: MockTransaction) => Promise<T>): Promise<T> {
    for (let attempt = 0; attempt < 15; attempt += 1) {
      const tx = new MockTransaction();
      const result = await fn(tx);
      if (tx.commit()) {
        return result;
      }
      await new Promise((resolve) => setTimeout(resolve, 1));
    }
    throw new Error("MockTransaction failed due to repeated contention.");
  },
};

jest.mock("firebase-admin/firestore", () => ({
  FieldValue: {
    serverTimestamp: () => new Date().toISOString(),
  },
  getFirestore: () => mockFirestoreInstance,
}));

import {
  captureCoins,
  holdCoins,
  releaseCoins,
} from "../services/financialEngine";

describe("Standalone Financial Engine Unit Tests (In-Memory Mock Store)", () => {
  beforeEach(() => {
    collections.clear();
    autoIdCounter = 0;
  });

  async function seedWallet(userId: string, walletBalance: number) {
    await mockFirestoreInstance.collection("users").doc(userId).set({
      userId,
      walletBalance,
      heldBalance: 0,
      role: "user",
      permissions: [],
    });
  }

  test("1. Hold -> Capture flow updates balances and writes immutable HOLD & CAPTURE ledger entries", async () => {
    await seedWallet("user_1", 100);

    const hold = await holdCoins(
      "user_1",
      20,
      "ATELIER_PHOTO",
      "CINEMATIC",
      `hold_${crypto.randomUUID()}`,
    );
    expect(hold.status).toBe("HELD");
    expect(hold.availableBalance).toBe(80);
    expect(hold.heldBalance).toBe(20);

    const capture = await captureCoins(hold.holdId, `cap_${crypto.randomUUID()}`, {
      jobId: "job_unit_1",
      watermark: "ساختهشده با هوش مصنوعی",
    });
    expect(capture.status).toBe("CAPTURED");
    expect(capture.availableBalance).toBe(80);
    expect(capture.heldBalance).toBe(0);

    const ledger = await mockFirestoreInstance
      .collection("ledger")
      .where("userId", "==", "user_1")
      .get();
    expect(ledger.size).toBe(2);
    const types = ledger.docs.map((d) => d.get("type")).sort();
    expect(types).toEqual(["CAPTURE", "HOLD"]);
  });

  test("2. Hold -> Failure -> Release refunds heldBalance back to availableBalance", async () => {
    await seedWallet("user_2", 50);

    const hold = await holdCoins(
      "user_2",
      10,
      "VIRTUAL_TRYON",
      "STANDARD",
      `hold_${crypto.randomUUID()}`,
    );
    expect(hold.availableBalance).toBe(40);
    expect(hold.heldBalance).toBe(10);

    const released = await releaseCoins(
      hold.holdId,
      "ANATOMICAL_VALIDATION_FAILED",
      `rel_${crypto.randomUUID()}`,
    );
    expect(released.status).toBe("RELEASED");
    expect(released.availableBalance).toBe(50);
    expect(released.heldBalance).toBe(0);

    await expect(
      captureCoins(hold.holdId, `cap_after_rel_${crypto.randomUUID()}`),
    ).rejects.toThrow(/RELEASED/);
  });

  test("3. Idempotency protection replays original transaction and rejects mismatched payloads", async () => {
    await seedWallet("user_3", 60);

    const key = `idem_${crypto.randomUUID()}`;
    const first = await holdCoins("user_3", 5, "VIRTUAL_TRYON", "FAST", key);
    const replay = await holdCoins("user_3", 5, "VIRTUAL_TRYON", "FAST", key);

    expect(first.idempotentReplay).toBe(false);
    expect(replay.idempotentReplay).toBe(true);
    expect(replay.holdId).toBe(first.holdId);
    expect(replay.ledgerTxId).toBe(first.ledgerTxId);

    await expect(
      holdCoins("user_3", 10, "VIRTUAL_TRYON", "STANDARD", key),
    ).rejects.toThrow(/different hold payload/i);
  });

  test("4. Concurrent requests never allow negative balances under contention", async () => {
    await seedWallet("user_4", 15);

    const requests = Array.from({ length: 5 }, (_, idx) =>
      holdCoins(
        "user_4",
        10,
        "VIRTUAL_TRYON",
        "STANDARD",
        `race_${idx}_${crypto.randomUUID()}`,
      ),
    );

    const results = await Promise.allSettled(requests);
    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");

    expect(fulfilled).toHaveLength(1);
    expect(rejected).toHaveLength(4);

    const userSnap = await mockFirestoreInstance
      .collection("users")
      .doc("user_4")
      .get();
    expect(userSnap.get("walletBalance")).toBe(5);
    expect(userSnap.get("heldBalance")).toBe(10);
  });
});

import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

export const SourceDeviceSchema = z.enum([
  "apple_health",
  "health_connect",
  "galaxy_watch",
  "mi_band",
]);
export type SourceDevice = z.infer<typeof SourceDeviceSchema>;

export const ConsentedScopeSchema = z.enum([
  "steps",
  "sleep",
  "heartRate",
  "weight",
  "calories",
]);
export type ConsentedScope = z.infer<typeof ConsentedScopeSchema>;

export const SyncHealthDnaInputSchema = z.object({
  userId: z.string().trim().min(1).max(128),
  steps: z.number().min(0).max(200000).optional(),
  activeCalories: z.number().min(0).max(20000).optional(),
  sleepHours: z.number().min(0).max(24).optional(),
  deepSleepHours: z.number().min(0).max(24).optional(),
  heartRateBpm: z.number().min(30).max(250).optional(),
  weightKg: z.number().min(20).max(300).optional(),
  sourceDevice: SourceDeviceSchema,
  consentedScopes: z.array(ConsentedScopeSchema),
  recordedAt: z.string().optional(),
});
export type SyncHealthDnaInput = z.infer<typeof SyncHealthDnaInputSchema>;

export interface FilteredBiometricMetrics {
  steps?: number;
  activeCalories?: number;
  sleepHours?: number;
  deepSleepHours?: number;
  heartRateBpm?: number;
  weightKg?: number;
  sourceDevice: SourceDevice;
  consentedScopes: ConsentedScope[];
  energyReadinessScore: number;
  stylistBiometricHint: string;
}

export interface HealthDnaSummary {
  userId: string;
  recordId: string;
  metrics: FilteredBiometricMetrics;
  lastSyncedAt: string;
}

/**
 * Normalizes user biometric telemetry into an Energy & Vitality readiness
 * score (0–100) based on sleep duration, deep sleep, activity, and resting heart rate.
 */
export function computeEnergyReadinessScore(metrics: {
  sleepHours?: number;
  deepSleepHours?: number;
  steps?: number;
  heartRateBpm?: number;
  activeCalories?: number;
}): number {
  let weightedSum = 0;
  let totalWeight = 0;

  // 1. Sleep Component (Max Weight: 45)
  if (metrics.sleepHours !== undefined) {
    const sleepWeight = 45;
    totalWeight += sleepWeight;
    let sleepScore = 0;
    if (metrics.sleepHours >= 7 && metrics.sleepHours <= 9) {
      sleepScore = 40;
    } else if (metrics.sleepHours < 7) {
      sleepScore = Math.max(0, (metrics.sleepHours / 7) * 40);
    } else {
      sleepScore = Math.max(25, 40 - (metrics.sleepHours - 9) * 4);
    }

    if (metrics.deepSleepHours !== undefined && metrics.deepSleepHours >= 1.5) {
      sleepScore = Math.min(sleepWeight, sleepScore + 5);
    }
    weightedSum += sleepScore;
  }

  // 2. Physical Steps & Activity Component (Max Weight: 35)
  if (metrics.steps !== undefined) {
    const activityWeight = 35;
    totalWeight += activityWeight;
    let actScore = 0;
    if (metrics.steps >= 7000 && metrics.steps <= 12000) {
      actScore = 35;
    } else if (metrics.steps < 7000) {
      actScore = (metrics.steps / 7000) * 35;
    } else {
      // Over 12,000 steps - still healthy but slight physical fatigue
      actScore = Math.max(28, 35 - ((metrics.steps - 12000) / 10000) * 7);
    }
    weightedSum += actScore;
  }

  // 3. Resting / Avg Heart Rate Component (Max Weight: 20)
  if (metrics.heartRateBpm !== undefined) {
    const hrWeight = 20;
    totalWeight += hrWeight;
    let hrScore = 0;
    if (metrics.heartRateBpm >= 55 && metrics.heartRateBpm <= 75) {
      hrScore = 20;
    } else if (metrics.heartRateBpm > 75 && metrics.heartRateBpm <= 90) {
      hrScore = 15;
    } else if (metrics.heartRateBpm > 90) {
      hrScore = Math.max(5, 20 - (metrics.heartRateBpm - 75) * 0.4);
    } else {
      hrScore = 16;
    }
    weightedSum += hrScore;
  }

  // Default balanced score if user denied all biometric scopes
  if (totalWeight === 0) {
    return 70;
  }

  const normalized = Math.round((weightedSum / totalWeight) * 100);
  return Math.max(0, Math.min(100, normalized));
}

/**
 * Derives contextual AI Stylist biometric mode based on sleep deficit,
 * physical exertion, and overall energy score.
 */
export function deriveStylistBiometricHint(metrics: {
  sleepHours?: number;
  steps?: number;
  energyReadinessScore: number;
}): string {
  if (metrics.sleepHours !== undefined && metrics.sleepHours < 5.5) {
    return "low_sleep_comfort_mode";
  }
  if (metrics.steps !== undefined && metrics.steps >= 10000) {
    return "high_activity_breathable_mode";
  }
  if (metrics.energyReadinessScore < 50) {
    return "low_energy_relaxed_mode";
  }
  if (metrics.energyReadinessScore >= 80 && (metrics.steps ?? 0) >= 7000) {
    return "high_vitality_active_mode";
  }
  return "balanced_lifestyle_mode";
}

/**
 * Filters out raw metrics that do not have active user consent in `consentedScopes`.
 */
export function filterMetricsByConsent(input: SyncHealthDnaInput): FilteredBiometricMetrics {
  const scopes = new Set(input.consentedScopes);

  const steps = scopes.has("steps") ? input.steps : undefined;
  const activeCalories = scopes.has("calories") ? input.activeCalories : undefined;
  const sleepHours = scopes.has("sleep") ? input.sleepHours : undefined;
  const deepSleepHours = scopes.has("sleep") ? input.deepSleepHours : undefined;
  const heartRateBpm = scopes.has("heartRate") ? input.heartRateBpm : undefined;
  const weightKg = scopes.has("weight") ? input.weightKg : undefined;

  const energyReadinessScore = computeEnergyReadinessScore({
    sleepHours,
    deepSleepHours,
    steps,
    heartRateBpm,
    activeCalories,
  });

  const stylistBiometricHint = deriveStylistBiometricHint({
    sleepHours,
    steps,
    energyReadinessScore,
  });

  return {
    sourceDevice: input.sourceDevice,
    consentedScopes: input.consentedScopes,
    steps,
    activeCalories,
    sleepHours,
    deepSleepHours,
    heartRateBpm,
    weightKg,
    energyReadinessScore,
    stylistBiometricHint,
  };
}

/**
 * Core business logic handler for processing and persisting health DNA metrics.
 * Supports passing a mock Firestore instance for standalone testing.
 */
export async function processHealthDnaSync(
  input: SyncHealthDnaInput,
  customDb?: FirebaseFirestore.Firestore,
): Promise<HealthDnaSummary> {
  const parsed = SyncHealthDnaInputSchema.safeParse(input);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid health DNA payload",
      parsed.error.flatten(),
    );
  }

  const validData = parsed.data;
  const filteredMetrics = filterMetricsByConsent(validData);

  const db = customDb ?? getFirestore();
  const dateStr = new Date().toISOString().split("T")[0];
  const recordId = `health_${dateStr}`;
  const nowIso = new Date().toISOString();

  const recordRef = db
    .collection("users")
    .doc(validData.userId)
    .collection("health_dna")
    .doc(recordId);

  const payload = {
    recordId,
    userId: validData.userId,
    ...filteredMetrics,
    recordedAt: validData.recordedAt ?? nowIso,
    updatedAt: FieldValue.serverTimestamp(),
  };

  await recordRef.set(payload, { merge: true });

  // Controlled denormalization: update latestHealthDna in root user document
  const userRef = db.collection("users").doc(validData.userId);
  await userRef.set(
    {
      latestHealthDna: {
        recordId,
        sourceDevice: filteredMetrics.sourceDevice,
        energyReadinessScore: filteredMetrics.energyReadinessScore,
        stylistBiometricHint: filteredMetrics.stylistBiometricHint,
        sleepHours: filteredMetrics.sleepHours ?? null,
        steps: filteredMetrics.steps ?? null,
        heartRateBpm: filteredMetrics.heartRateBpm ?? null,
        weightKg: filteredMetrics.weightKg ?? null,
        lastSyncedAt: nowIso,
      },
    },
    { merge: true },
  );

  return {
    userId: validData.userId,
    recordId,
    metrics: filteredMetrics,
    lastSyncedAt: nowIso,
  };
}

/**
 * Callable Cloud Function: `syncHealthDna`
 */
export const syncHealthDnaCallable = onCall(
  {
    region: "europe-west3",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required to sync wearable health metrics.",
      );
    }

    const userId = request.auth.uid;
    const body = request.data as Record<string, unknown>;

    return processHealthDnaSync({
      ...body,
      userId,
    } as SyncHealthDnaInput);
  },
);

/**
 * Callable Cloud Function: `getHealthDnaSummary`
 */
export const getHealthDnaSummaryCallable = onCall(
  {
    region: "europe-west3",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication is required to retrieve health DNA summary.",
      );
    }

    const userId = request.auth.uid;
    const db = getFirestore();
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User profile document not found.");
    }

    const latest = userDoc.get("latestHealthDna") as Record<string, unknown> | undefined;
    return {
      userId,
      latestHealthDna: latest ?? null,
    };
  },
);

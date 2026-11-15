import {
  computeEnergyReadinessScore,
  deriveStylistBiometricHint,
  filterMetricsByConsent,
  processHealthDnaSync,
  SyncHealthDnaInputSchema,
} from "../health";

describe("Health DNA & Wearable Biometrics Unit Tests", () => {
  describe("computeEnergyReadinessScore", () => {
    it("returns high readiness score for optimal sleep and moderate healthy activity", () => {
      const score = computeEnergyReadinessScore({
        sleepHours: 8,
        deepSleepHours: 2.0,
        steps: 8500,
        heartRateBpm: 65,
      });

      expect(score).toBeGreaterThanOrEqual(85);
      expect(score).toBeLessThanOrEqual(100);
    });

    it("returns reduced score when sleep is severely deficient", () => {
      const score = computeEnergyReadinessScore({
        sleepHours: 3.5,
        deepSleepHours: 0.5,
        steps: 4000,
        heartRateBpm: 88,
      });

      expect(score).toBeLessThan(60);
    });

    it("returns default 70 when all biometric scopes are omitted / unconsented", () => {
      const score = computeEnergyReadinessScore({});
      expect(score).toBe(70);
    });
  });

  describe("deriveStylistBiometricHint", () => {
    it("returns low_sleep_comfort_mode when sleep is under 5.5 hours", () => {
      const hint = deriveStylistBiometricHint({
        sleepHours: 4.8,
        steps: 6000,
        energyReadinessScore: 55,
      });
      expect(hint).toBe("low_sleep_comfort_mode");
    });

    it("returns high_activity_breathable_mode when steps exceed 10000", () => {
      const hint = deriveStylistBiometricHint({
        sleepHours: 7.5,
        steps: 12500,
        energyReadinessScore: 82,
      });
      expect(hint).toBe("high_activity_breathable_mode");
    });

    it("returns high_vitality_active_mode for high energy readiness and solid activity", () => {
      const hint = deriveStylistBiometricHint({
        sleepHours: 8.0,
        steps: 7500,
        energyReadinessScore: 85,
      });
      expect(hint).toBe("high_vitality_active_mode");
    });

    it("returns balanced_lifestyle_mode for normal everyday values", () => {
      const hint = deriveStylistBiometricHint({
        sleepHours: 6.8,
        steps: 5000,
        energyReadinessScore: 68,
      });
      expect(hint).toBe("balanced_lifestyle_mode");
    });
  });

  describe("filterMetricsByConsent", () => {
    it("filters out unconsented metrics strictly (Privacy-by-Design)", () => {
      const filtered = filterMetricsByConsent({
        userId: "user_test_123",
        sourceDevice: "apple_health",
        consentedScopes: ["steps", "calories"],
        steps: 8200,
        activeCalories: 450,
        sleepHours: 7.5, // Not in consentedScopes
        deepSleepHours: 1.8, // Not in consentedScopes
        heartRateBpm: 72, // Not in consentedScopes
        weightKg: 68.5, // Not in consentedScopes
      });

      expect(filtered.steps).toBe(8200);
      expect(filtered.activeCalories).toBe(450);
      expect(filtered.sleepHours).toBeUndefined();
      expect(filtered.deepSleepHours).toBeUndefined();
      expect(filtered.heartRateBpm).toBeUndefined();
      expect(filtered.weightKg).toBeUndefined();
      expect(filtered.sourceDevice).toBe("apple_health");
      expect(filtered.consentedScopes).toEqual(["steps", "calories"]);
    });
  });

  describe("SyncHealthDnaInputSchema validation", () => {
    it("rejects invalid device type", () => {
      const result = SyncHealthDnaInputSchema.safeParse({
        userId: "usr_1",
        sourceDevice: "unknown_smartwatch_brand",
        consentedScopes: ["steps"],
      });
      expect(result.success).toBe(false);
    });

    it("rejects impossible biometric metrics (e.g. sleep > 24h or negative steps)", () => {
      const result = SyncHealthDnaInputSchema.safeParse({
        userId: "usr_1",
        sourceDevice: "galaxy_watch",
        consentedScopes: ["sleep"],
        sleepHours: 35,
        steps: -100,
      });
      expect(result.success).toBe(false);
    });

    it("accepts valid Apple Health / Health Connect payload", () => {
      const result = SyncHealthDnaInputSchema.safeParse({
        userId: "usr_1",
        sourceDevice: "health_connect",
        consentedScopes: ["steps", "sleep", "heartRate"],
        steps: 6400,
        sleepHours: 7.2,
        heartRateBpm: 68,
      });
      expect(result.success).toBe(true);
    });
  });

  describe("processHealthDnaSync with mock Firestore", () => {
    it("persists filtered metrics to users/{userId}/health_dna and updates latestHealthDna", async () => {
      const storage = new Map<string, Record<string, unknown>>();

      const mockDb: any = {
        collection: (col: string) => ({
          doc: (docId: string) => {
            if (col === "users") {
              return {
                collection: (subCol: string) => ({
                  doc: (subDocId: string) => ({
                    set: async (data: any, _options: any) => {
                      storage.set(`users/${docId}/${subCol}/${subDocId}`, data);
                    },
                  }),
                }),
                set: async (data: any, _options: any) => {
                  const existing = storage.get(`users/${docId}`) ?? {};
                  storage.set(`users/${docId}`, { ...existing, ...data });
                },
              };
            }
            throw new Error(`Unexpected collection ${col}`);
          },
        }),
      };

      const result = await processHealthDnaSync(
        {
          userId: "usr_sara_123",
          sourceDevice: "galaxy_watch",
          consentedScopes: ["sleep", "steps", "heartRate"],
          sleepHours: 4.8,
          steps: 11200,
          heartRateBpm: 76,
        },
        mockDb,
      );

      expect(result.userId).toBe("usr_sara_123");
      expect(result.metrics.sourceDevice).toBe("galaxy_watch");
      expect(result.metrics.sleepHours).toBe(4.8);
      // Low sleep takes precedence for stylist comfort mode
      expect(result.metrics.stylistBiometricHint).toBe("low_sleep_comfort_mode");

      const savedSubDoc = storage.get(`users/usr_sara_123/health_dna/${result.recordId}`);
      expect(savedSubDoc).toBeDefined();
      expect(savedSubDoc?.["userId"]).toBe("usr_sara_123");
      expect(savedSubDoc?.["stylistBiometricHint"]).toBe("low_sleep_comfort_mode");

      const savedUserDoc = storage.get("users/usr_sara_123");
      expect(savedUserDoc).toBeDefined();
      expect(savedUserDoc?.["latestHealthDna"]).toBeDefined();
      expect((savedUserDoc?.["latestHealthDna"] as any).sourceDevice).toBe("galaxy_watch");
    });
  });
});

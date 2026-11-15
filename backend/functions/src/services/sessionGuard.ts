import * as crypto from "node:crypto";
import { getAuth } from "firebase-admin/auth";
import {
  FieldValue,
  getFirestore,
  type Firestore,
  type Transaction,
} from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  RegisterDeviceSessionInputSchema,
  type AuditLogRecord,
  type RegisterDeviceSessionResult,
  type WriteAuditLogInput,
} from "../types/financial";

function isTransaction(target: Firestore | Transaction): target is Transaction {
  return typeof (target as Transaction).get === "function" &&
    typeof (target as Firestore).collection !== "function";
}

/**
 * Appends an immutable audit record to `audit_logs/{logId}`.
 * Supports both standalone Firestore writes and atomic Transaction writes.
 */
export async function writeAuditLog(
  target: Firestore | Transaction,
  input: WriteAuditLogInput,
): Promise<string> {
  const db = getFirestore();
  const logRef = db.collection("audit_logs").doc();
  const record: AuditLogRecord = {
    logId: logRef.id,
    actorId: input.actorId,
    actorRole: input.actorRole,
    action: input.action,
    targetCollection: input.targetCollection,
    targetId: input.targetId,
    ...(input.previousValue !== undefined
      ? { previousValue: input.previousValue }
      : {}),
    ...(input.newValue !== undefined ? { newValue: input.newValue } : {}),
    ...(input.reason !== undefined ? { reason: input.reason } : {}),
    ...(input.ipAddress !== undefined ? { ipAddress: input.ipAddress } : {}),
    ...(input.userAgent !== undefined ? { userAgent: input.userAgent } : {}),
    ...(input.deviceId !== undefined ? { deviceId: input.deviceId } : {}),
    createdAt: FieldValue.serverTimestamp(),
  };

  if (isTransaction(target)) {
    target.set(logRef, record);
  } else {
    await logRef.set(record);
  }
  return logRef.id;
}

/**
 * Verifies that the authenticated caller's Firebase Auth token carries the
 * currently active `activeDeviceId` registered for `userId`.
 */
export async function verifyActiveSession(
  userId: string,
  tokenClaims: Record<string, unknown>,
): Promise<void> {
  const db = getFirestore();
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) {
    return;
  }

  const activeDeviceId = userSnap.get("activeDeviceId") as string | null | undefined;
  if (!activeDeviceId) {
    return;
  }

  const tokenDeviceId = tokenClaims["activeDeviceId"];
  if (typeof tokenDeviceId !== "string" || tokenDeviceId !== activeDeviceId) {
    throw new HttpsError(
      "permission-denied",
      "SESSION_INVALIDATED_BY_NEW_DEVICE",
    );
  }
}

/**
 * Atomically registers a single active device session for `userId`, invalidates
 * any previous device's refresh tokens, updates custom claims, and writes an
 * immutable audit entry when a prior device was displaced.
 */
export async function registerDeviceSessionCore(
  userId: string,
  rawInput: unknown,
  meta: { ipAddress?: string; userAgent?: string } = {},
): Promise<RegisterDeviceSessionResult> {
  const parsed = RegisterDeviceSessionInputSchema.safeParse(rawInput);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid device session payload.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const db = getFirestore();
  const auth = getAuth();
  const userRef = db.collection("users").doc(userId);
  const newSessionId = crypto.randomUUID();

  const { previousDeviceId, previousSessionId } = await db.runTransaction(
    async (tx) => {
      const userSnap = await tx.get(userRef);
      const prevDev = userSnap.exists
        ? ((userSnap.get("activeDeviceId") as string | null | undefined) ?? null)
        : null;
      const prevSess = userSnap.exists
        ? ((userSnap.get("activeSessionId") as string | null | undefined) ?? null)
        : null;

      if (userSnap.exists) {
        tx.update(userRef, {
          activeDeviceId: input.deviceId,
          activeSessionId: newSessionId,
          lastDeviceName: input.deviceName,
          lastPlatform: input.platform,
          lastAppVersion: input.appVersion,
          lastSessionAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(userRef, {
          userId,
          walletBalance: 0,
          heldBalance: 0,
          role: "user",
          permissions: [],
          activeDeviceId: input.deviceId,
          activeSessionId: newSessionId,
          lastDeviceName: input.deviceName,
          lastPlatform: input.platform,
          lastAppVersion: input.appVersion,
          lastSessionAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      if (prevDev && prevDev !== input.deviceId) {
        await writeAuditLog(tx, {
          actorId: userId,
          actorRole: "USER",
          action: "SINGLE_DEVICE_SESSION_REPLACED",
          targetCollection: "users",
          targetId: userId,
          previousValue: {
            activeDeviceId: prevDev,
            activeSessionId: prevSess,
          },
          newValue: {
            activeDeviceId: input.deviceId,
            activeSessionId: newSessionId,
            platform: input.platform,
          },
          reason: "New device sign-in displaced existing active session.",
          ipAddress: meta.ipAddress,
          userAgent: meta.userAgent,
          deviceId: input.deviceId,
        });
      }

      return { previousDeviceId: prevDev, previousSessionId: prevSess };
    },
  );

  // Sync activeDeviceId / activeSessionId into Firebase Auth Custom Claims
  // while preserving existing RBAC claims.
  const userRecord = await auth.getUser(userId);
  const existingClaims = userRecord.customClaims ?? {};
  await auth.setCustomUserClaims(userId, {
    ...existingClaims,
    activeDeviceId: input.deviceId,
    activeSessionId: newSessionId,
  });

  const previousDeviceRevoked = Boolean(
    previousDeviceId &&
      (previousDeviceId !== input.deviceId || previousSessionId !== newSessionId),
  );

  if (previousDeviceId && previousDeviceId !== input.deviceId) {
    await auth.revokeRefreshTokens(userId);
    logger.info("Revoked previous device tokens for single-device session.", {
      userId,
      previousDeviceId,
      newDeviceId: input.deviceId,
    });
  }

  return {
    userId,
    deviceId: input.deviceId,
    sessionId: newSessionId,
    previousDeviceRevoked,
  };
}

/**
 * HTTPS Callable endpoint to register the caller's single active device session.
 */
export const registerDeviceSession = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const forwardedFor = request.rawRequest?.headers["x-forwarded-for"];
  const ipAddress = Array.isArray(forwardedFor)
    ? forwardedFor[0]
    : typeof forwardedFor === "string"
      ? forwardedFor.split(",")[0]?.trim()
      : request.rawRequest?.ip;
  const userAgent = request.rawRequest?.headers["user-agent"];

  return registerDeviceSessionCore(request.auth.uid, request.data, {
    ipAddress,
    userAgent: typeof userAgent === "string" ? userAgent : undefined,
  });
});

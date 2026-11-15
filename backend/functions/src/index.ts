import { getApps, initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

if (getApps().length === 0) {
  initializeApp();
}

// Per architecture spec (AGENTS.md): deploy functions to europe-west3.
setGlobalOptions({
  region: "europe-west3",
  maxInstances: 20,
});

// Atomic Financial Engine
export {
  holdCoinsCallable as holdCoins,
  captureCoinsInternal as captureCoins,
  releaseCoinsInternal as releaseCoins,
} from "./services/financialEngine";

// Unified Tri-Channel Payment SSV Webhooks & Store Reviewer Shield
export {
  iapWebhook,
  stripeWebhook,
  cryptoWebhook,
  getWalletPromoConfig,
} from "./services/paymentWebhooks";

// Single-Device Session Guard
export { registerDeviceSession } from "./services/sessionGuard";

// Wearable & Smart Health DNA Telemetry Sync
export {
  syncHealthDnaCallable as syncHealthDna,
  getHealthDnaSummaryCallable as getHealthDnaSummary,
} from "./health";

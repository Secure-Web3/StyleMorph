export interface CaptureResponse {
  holdId: string;
  ledgerTxId: string;
  status: "CAPTURED";
  availableBalance: number;
  heldBalance: number;
}

export interface ReleaseResponse {
  holdId: string;
  ledgerTxId: string;
  status: "RELEASED";
  availableBalance: number;
  heldBalance: number;
}

function getFunctionsBaseUrl(): string {
  const configured = process.env["FUNCTIONS_BASE_URL"];
  if (configured && configured.trim().length > 0) {
    return configured.replace(/\/+$/, "");
  }
  const projectId = process.env["GCLOUD_PROJECT"] ?? "stylemorph-dev";
  const region = process.env["FUNCTIONS_REGION"] ?? "europe-west3";
  return `http://127.0.0.1:5001/${projectId}/${region}`;
}

function buildInternalHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  const secret = process.env["INTERNAL_SERVICE_SECRET"];
  if (secret) {
    headers["x-internal-service-secret"] = secret;
  }
  return headers;
}

export async function callCaptureCoins(params: {
  holdId: string;
  idempotencyKey: string;
  metadata: Record<string, unknown>;
}): Promise<CaptureResponse> {
  const url = `${getFunctionsBaseUrl()}/captureCoins`;
  const response = await fetch(url, {
    method: "POST",
    headers: buildInternalHeaders(),
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    const bodyText = await response.text();
    throw new Error(
      `captureCoins failed (${response.status}): ${bodyText}`,
    );
  }

  return (await response.json()) as CaptureResponse;
}

export async function callReleaseCoins(params: {
  holdId: string;
  reason: string;
  idempotencyKey: string;
}): Promise<ReleaseResponse> {
  const url = `${getFunctionsBaseUrl()}/releaseCoins`;
  const response = await fetch(url, {
    method: "POST",
    headers: buildInternalHeaders(),
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    const bodyText = await response.text();
    throw new Error(
      `releaseCoins failed (${response.status}): ${bodyText}`,
    );
  }

  return (await response.json()) as ReleaseResponse;
}

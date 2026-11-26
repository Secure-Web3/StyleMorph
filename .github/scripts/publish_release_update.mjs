import crypto from 'node:crypto';

const SERVICE_ACCOUNT_RAW = (process.env.FIREBASE_SERVICE_ACCOUNT ?? '').trim();

if (!SERVICE_ACCOUNT_RAW) {
  console.warn(
    '[publish_release_update] FIREBASE_SERVICE_ACCOUNT secret is not set; skipping Firestore & FCM sync.',
  );
  process.exit(0);
}

const rawVersion = (process.env.APP_VERSION ?? '').trim();
const version = rawVersion.replace(/^[vV]/, '') || '1.0.0';
const buildNumber = Number.parseInt(process.env.BUILD_NUMBER ?? '100', 10) || 100;
const androidUrl = (process.env.ANDROID_URL ?? '').trim();
const releaseNotes = (
  process.env.RELEASE_NOTES ?? `StyleMorph v${version} is now available.`
).trim();
const forceUpdate =
  String(process.env.FORCE_UPDATE ?? 'false').toLowerCase() === 'true';
const minRequiredBuild =
  Number.parseInt(process.env.MIN_REQUIRED_BUILD ?? '0', 10) || 0;

function base64UrlEncode(input) {
  const buf = Buffer.isBuffer(input) ? input : Buffer.from(input, 'utf8');
  return buf
    .toString('base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replace(/=+$/, '');
}

async function getAccessToken(serviceAccount) {
  const nowSec = Math.floor(Date.now() / 1000);
  const tokenUri =
    serviceAccount.token_uri || 'https://oauth2.googleapis.com/token';

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claimSet = base64UrlEncode(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: [
        'https://www.googleapis.com/auth/datastore',
        'https://www.googleapis.com/auth/firebase.messaging',
      ].join(' '),
      aud: tokenUri,
      iat: nowSec,
      exp: nowSec + 3600,
    }),
  );

  const unsignedJwt = `${header}.${claimSet}`;
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsignedJwt);
  signer.end();
  const signature = base64UrlEncode(signer.sign(serviceAccount.private_key));
  const assertion = `${unsignedJwt}.${signature}`;

  const res = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OAuth2 token exchange failed (${res.status}): ${errText}`);
  }
  const data = await res.json();
  return data.access_token;
}

async function patchFirestoreVersion(projectId, accessToken) {
  const fields = [
    'version',
    'build',
    'androidUrl',
    'releaseNotes',
    'forceUpdate',
    'minRequiredBuild',
    'updatedAt',
  ];
  const maskQuery = fields
    .map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`)
    .join('&');
  const url = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(
    projectId,
  )}/databases/(default)/documents/app_config/version?${maskQuery}`;

  const body = {
    fields: {
      version: { stringValue: version },
      build: { integerValue: String(buildNumber) },
      androidUrl: { stringValue: androidUrl },
      releaseNotes: { stringValue: releaseNotes },
      forceUpdate: { booleanValue: forceUpdate },
      minRequiredBuild: { integerValue: String(minRequiredBuild) },
      updatedAt: { timestampValue: new Date().toISOString() },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Firestore patch failed (${res.status}): ${errText}`);
  }
  console.log(
    `[publish_release_update] Updated Firestore app_config/version -> v${version} (build ${buildNumber})`,
  );
}

async function sendFcmAppUpdatesTopic(projectId, accessToken) {
  const url = `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(
    projectId,
  )}/messages:send`;

  const body = {
    message: {
      topic: 'app_updates',
      notification: {
        title: `StyleMorph v${version} Available`,
        body: releaseNotes,
      },
      data: {
        type: 'app_update',
        version,
        build: String(buildNumber),
      },
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`FCM v1 broadcast failed (${res.status}): ${errText}`);
  }
  console.log(
    `[publish_release_update] Sent FCM push to topic "app_updates" for v${version}`,
  );
}

async function main() {
  const serviceAccount = JSON.parse(SERVICE_ACCOUNT_RAW);
  const projectId = serviceAccount.project_id;
  if (!projectId || !serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT JSON is missing required fields.');
  }

  const accessToken = await getAccessToken(serviceAccount);
  await patchFirestoreVersion(projectId, accessToken);
  await sendFcmAppUpdatesTopic(projectId, accessToken);
}

main().catch((err) => {
  console.error('[publish_release_update] Error:', err);
  process.exit(1);
});

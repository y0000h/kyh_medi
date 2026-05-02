// Supabase Edge Function — `dose_events` Insert Webhook 핸들러.
//
// 부모 측에서 missed 이벤트가 들어오면, 페어링된 자녀들의 FCM 토큰으로
// "○○이 약을 못 드셨어요" 푸시를 전송한다.
//
// FCM v1 API (Service Account JWT → OAuth 2.0 access token → messages:send) 사용.
// (Legacy `fcm.googleapis.com/fcm/send` API는 2024-06-20에 영구 폐기됨.)
//
// 배포:
//   supabase functions deploy on_dose_event_insert --no-verify-jwt
//
// 시크릿:
//   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
//
// Webhook 등록 (Supabase 콘솔 → Database → Webhooks):
//   - Table: public.dose_events
//   - Events: Insert
//   - Type: HTTP Request → Edge Function → on_dose_event_insert

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);
const sa = JSON.parse(FCM_SERVICE_ACCOUNT_JSON) as {
  client_email: string;
  private_key: string;
  project_id: string;
};

// PEM(PKCS8) → ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = atob(b64);
  const buf = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buf[i] = binary.charCodeAt(i);
  return buf.buffer;
}

function base64UrlEncode(data: Uint8Array | string): string {
  const bytes =
    typeof data === 'string' ? new TextEncoder().encode(data) : data;
  const b64 = btoa(String.fromCharCode(...bytes));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.value;
  }

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    }),
  );
  const unsigned = `${header}.${claim}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBuf = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(sigBuf))}`;

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  });
  const json = await resp.json();
  if (!json.access_token) {
    throw new Error(`oauth token error: ${JSON.stringify(json)}`);
  }

  cachedToken = {
    value: json.access_token,
    expiresAt: now + (json.expires_in ?? 3600),
  };
  return cachedToken.value;
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('method not allowed', { status: 405 });
  }
  try {
    const body = await req.json();
    const record = body.record ?? body; // Database Webhook payload
    if (record?.status !== 'missed') {
      return new Response('skip (not missed)', { status: 200 });
    }

    // 약 이름
    const { data: med } = await supabase
      .from('medications')
      .select('name')
      .eq('id', record.medication_id)
      .single();

    // 페어링된 자녀
    const { data: pairs } = await supabase
      .from('pairings')
      .select('parent_label, child_users(fcm_token, display_name)')
      .eq('parent_device_id', record.parent_device_id);

    const accessToken = await getAccessToken();

    const sent: string[] = [];
    for (const p of pairs ?? []) {
      // deno-lint-ignore no-explicit-any
      const token = (p as any).child_users?.fcm_token;
      if (!token) continue;
      const resp = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: '복약 알림',
                body:
                  // deno-lint-ignore no-explicit-any
                  `${(p as any).parent_label ?? '부모님'}이 ${med?.name ?? '약'}을(를) 못 드셨어요`,
              },
              data: {
                type: 'dose_missed',
                parent_device_id: String(record.parent_device_id),
                slot_id: String(record.slot_id ?? ''),
                medication_id: String(record.medication_id),
              },
            },
          }),
        },
      );
      sent.push(`${token.slice(0, 12)}: ${resp.status}`);
    }
    return new Response(JSON.stringify({ ok: true, sent }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error(e);
    return new Response(`error: ${e}`, { status: 500 });
  }
});

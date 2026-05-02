// Supabase Edge Function — `dose_events` Insert Webhook 핸들러.
//
// 부모 측에서 missed 이벤트가 들어오면, 페어링된 자녀들의 FCM 토큰으로
// "○○이 약을 못 드셨어요" 푸시를 전송한다.
//
// 배포:
//   supabase functions deploy on_dose_event_insert --no-verify-jwt
//
// 시크릿:
//   supabase secrets set FCM_SERVER_KEY="AAAA-실제값"
//
// Webhook 등록 (Supabase 콘솔 → Database → Webhooks):
//   - Table: public.dose_events
//   - Events: Insert
//   - Type: HTTP Request → Edge Function → on_dose_event_insert

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

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

    const sent: string[] = [];
    for (const p of pairs ?? []) {
      // deno-lint-ignore no-explicit-any
      const token = (p as any).child_users?.fcm_token;
      if (!token) continue;
      const resp = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Authorization': `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          to: token,
          notification: {
            title: '복약 알림',
            // deno-lint-ignore no-explicit-any
            body: `${(p as any).parent_label ?? '부모님'}이 ${med?.name ?? '약'}을(를) 못 드셨어요`,
          },
          data: {
            type: 'dose_missed',
            parent_device_id: record.parent_device_id,
            slot_id: record.slot_id,
            medication_id: record.medication_id,
          },
        }),
      });
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

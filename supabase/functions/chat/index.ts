// Chat 프록시 Edge Function — OpenAI / Gemini 둘 다 지원.
//
// body: {
//   provider?: "openai" | "gemini",   // 생략 시 'gemini' (기본 무료)
//   messages: [ { role, content } ],
// }
//
// 둘 다 OpenAI 호환 형식 사용:
//   - OpenAI:  https://api.openai.com/v1/chat/completions
//   - Gemini:  https://generativelanguage.googleapis.com/v1beta/openai/chat/completions
//     (Google이 OpenAI 호환 endpoint를 정식 제공 — Bearer 인증, 동일한 messages 스키마)
//
// 환경변수 (Supabase secret):
//   OPENAI_API_KEY  : OpenAI sk-...
//   GEMINI_API_KEY  : Google AI Studio 키
//   OPENAI_MODEL    : (선택) 기본 gpt-4o-mini
//   GEMINI_MODEL    : (선택) 기본 gemini-2.5-flash

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

type Provider = "openai" | "gemini";

interface Body {
  provider?: Provider;
  messages?: ChatMessage[];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "Invalid JSON body" });
  }

  const provider: Provider = body.provider ?? "gemini";
  const messages = body.messages ?? [];
  if (messages.length === 0) {
    return json(400, { error: "messages array is empty" });
  }

  const config = providerConfig(provider);
  if (!config.apiKey) {
    return json(500, {
      error: `${provider.toUpperCase()}_API_KEY not configured on server`,
    });
  }

  const withSystem: ChatMessage[] = messages.some((m) => m.role === "system")
    ? messages
    : [
        {
          role: "system",
          content: "당신은 친절하고 간결하게 답하는 한국어 챗봇입니다.",
        },
        ...messages,
      ];

  try {
    const upstream = await fetch(config.endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: config.model,
        messages: withSystem,
        temperature: 0.7,
      }),
    });

    if (!upstream.ok) {
      const text = await upstream.text();
      return json(upstream.status, {
        error: `${provider} API error`,
        status: upstream.status,
        detail: text,
      });
    }

    const data = await upstream.json();
    const reply = data.choices?.[0]?.message?.content ?? "";
    return json(200, { reply, provider, model: config.model });
  } catch (e) {
    return json(500, { error: "fetch failed", detail: String(e) });
  }
});

function providerConfig(provider: Provider) {
  if (provider === "openai") {
    return {
      endpoint: "https://api.openai.com/v1/chat/completions",
      apiKey: OPENAI_API_KEY,
      model: OPENAI_MODEL,
    };
  }
  return {
    endpoint:
      "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
    apiKey: GEMINI_API_KEY,
    model: GEMINI_MODEL,
  };
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

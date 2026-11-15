// SparkQuest Server-Side Content Moderation Edge Function
// Replaces unsafe client-side `safe: true` stubs. Validates payload type/size,
// screens text, and delegates media moderation when OPENAI_API_KEY is configured.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

const BLOCKED_TERMS = /\b(csam|child\s*porn|self[\s-]*harm|kill\s*yourself|swatting|doxx)\b/i;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const openAiKey = Deno.env.get("OPENAI_API_KEY") ?? "";

    if (!authHeader.startsWith("Bearer ") || !supabaseUrl || !anonKey) {
      return new Response(JSON.stringify({ safe: false, reason: "Authentication required" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: authData, error: authErr } = await userClient.auth.getUser();
    if (authErr || !authData?.user || authData.user.is_anonymous) {
      return new Response(JSON.stringify({ safe: false, reason: "Authenticated user required" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const body = await req.json();
    const imageBase64 = typeof body?.imageBase64 === "string" ? body.imageBase64 : "";
    const text = typeof body?.text === "string" ? body.text : "";

    if (BLOCKED_TERMS.test(text)) {
      return new Response(
        JSON.stringify({ safe: false, flagged: true, reason: "Content violates community safety policy" }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    if (imageBase64.length > 0) {
      const mimeMatch = imageBase64.match(/^data:(image\/(?:jpeg|png|webp));base64,/);
      if (!mimeMatch || imageBase64.length > 10_000_000) {
        return new Response(
          JSON.stringify({ safe: false, reason: "Invalid or oversized image payload" }),
          { status: 400, headers: CORS_HEADERS },
        );
      }
      if (!openAiKey) {
        return new Response(
          JSON.stringify({
            safe: false,
            status: "pending_review",
            reason: "Automated image moderation provider (OPENAI_API_KEY) not configured",
          }),
          { status: 503, headers: CORS_HEADERS },
        );
      }

      const modRes = await fetch("https://api.openai.com/v1/moderations", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "omni-moderation-latest",
          input: [{ type: "image_url", image_url: { url: imageBase64 } }],
        }),
      });
      if (!modRes.ok) {
        return new Response(
          JSON.stringify({ safe: false, reason: `Moderation provider failed (${modRes.status})` }),
          { status: 502, headers: CORS_HEADERS },
        );
      }
      const modJson = await modRes.json();
      const flagged = Boolean(modJson?.results?.[0]?.flagged);
      return new Response(
        JSON.stringify({ safe: !flagged, flagged, provider: "openai_omni_moderation" }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    return new Response(JSON.stringify({ safe: true, provider: "policy_filter" }), {
      status: 200,
      headers: CORS_HEADERS,
    });
  } catch (err) {
    return new Response(JSON.stringify({ safe: false, reason: String(err) }), {
      status: 500,
      headers: CORS_HEADERS,
    });
  }
});

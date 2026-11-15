// SparkQuest AI Wingman Edge Function
// Keeps GROQ_API_KEY strictly server-side (never exposed in client localStorage).
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const groqKey = Deno.env.get("GROQ_API_KEY") ?? "";

    if (!authHeader.startsWith("Bearer ") || !supabaseUrl || !anonKey) {
      return new Response(JSON.stringify({ error: "Authentication required" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: authData, error: authErr } = await userClient.auth.getUser();
    if (authErr || !authData?.user || authData.user.is_anonymous) {
      return new Response(JSON.stringify({ error: "Authenticated user required" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const body = await req.json();
    const rawMessages = Array.isArray(body?.messages) ? body.messages.slice(-6) : [];
    const safeMessages = rawMessages
      .filter((m: unknown): m is { role: string; content: string } =>
        typeof m === "object" && m !== null && typeof (m as { content?: unknown }).content === "string",
      )
      .map((m) => ({
        role: m.role === "system" || m.role === "assistant" ? m.role : "user",
        content: m.content.slice(0, 1200),
      }));

    if (safeMessages.length === 0) {
      return new Response(JSON.stringify({ error: "messages required" }), {
        status: 400,
        headers: CORS_HEADERS,
      });
    }

    if (!groqKey) {
      return new Response(
        JSON.stringify({
          content: null,
          provider: "offline_heuristic",
          notice: "GROQ_API_KEY not configured; client uses local creative templates.",
        }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    const aiRes = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: safeMessages,
        temperature: 0.7,
        max_tokens: 200,
      }),
    });

    if (!aiRes.ok) {
      return new Response(
        JSON.stringify({ content: null, error: `AI upstream error (${aiRes.status})` }),
        { status: 502, headers: CORS_HEADERS },
      );
    }

    const aiJson = await aiRes.json();
    return new Response(
      JSON.stringify({
        content: aiJson?.choices?.[0]?.message?.content ?? null,
        provider: "groq_proxy",
      }),
      { status: 200, headers: CORS_HEADERS },
    );
  } catch (err) {
    return new Response(JSON.stringify({ content: null, error: String(err) }), {
      status: 500,
      headers: CORS_HEADERS,
    });
  }
});

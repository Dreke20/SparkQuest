// SparkQuest Edge Function: Global Teleport 2.0 Message Translator
// Translates chat messages between Adventurers across languages via MyMemory API.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const text = (body?.text ?? "").toString().trim();
    const sourceLang = (body?.sourceLang ?? "en").toString().trim();
    const targetLang = (body?.targetLang ?? "es").toString().trim();

    if (!text) {
      return new Response(
        JSON.stringify({ error: "Missing text to translate" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (sourceLang === targetLang) {
      return new Response(
        JSON.stringify({ translatedText: text, sourceLang, targetLang, provider: "identity" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const url = new URL("https://api.mymemory.translated.net/get");
    url.searchParams.set("q", text.slice(0, 500));
    url.searchParams.set("langpair", `${sourceLang}|${targetLang}`);

    const upstream = await fetch(url.toString(), {
      method: "GET",
      headers: { "Accept": "application/json" },
    });

    if (!upstream.ok) {
      return new Response(
        JSON.stringify({ error: `Upstream HTTP ${upstream.status}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const data = await upstream.json();
    const translated = (data?.responseData?.translatedText ?? "").toString().trim();

    return new Response(
      JSON.stringify({
        translatedText: translated || text,
        sourceLang,
        targetLang,
        provider: "mymemory",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

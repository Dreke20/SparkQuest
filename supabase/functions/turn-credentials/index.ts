// SparkQuest TURN & STUN ICE Server Configuration Edge Function
// Deploy: supabase functions deploy turn-credentials --no-verify-jwt
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const FALLBACK_STUN_SERVERS = [
  { urls: "stun:stun.l.google.com:19302" },
  { urls: "stun:stun1.l.google.com:19302" },
  { urls: "stun:stun.cloudflare.com:3478" },
];

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const iceServers: Array<Record<string, unknown>> = [...FALLBACK_STUN_SERVERS];
  let hasTurn = false;

  try {
    // Option 1: Cloudflare Calls TURN API (recommended short-lived credentials)
    const cfTokenId = Deno.env.get("CLOUDFLARE_TURN_TOKEN_ID");
    const cfApiToken = Deno.env.get("CLOUDFLARE_TURN_API_TOKEN");
    if (cfTokenId && cfApiToken) {
      const cfRes = await fetch(
        `https://rtc.live.cloudflare.com/v1/turn/keys/${cfTokenId}/credentials/generate-ice-servers`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${cfApiToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ ttl: 3600 }),
        },
      );
      if (cfRes.ok) {
        const cfJson = await cfRes.json();
        if (Array.isArray(cfJson?.iceServers)) {
          iceServers.push(...cfJson.iceServers);
          hasTurn = true;
        }
      }
    }

    // Option 2: Metered TURN dynamic credentials
    const meteredDomain = Deno.env.get("METERED_TURN_DOMAIN");
    const meteredKey = Deno.env.get("METERED_TURN_API_KEY");
    if (!hasTurn && meteredDomain && meteredKey) {
      const mRes = await fetch(
        `https://${meteredDomain}/api/v1/turn/credentials?apiKey=${meteredKey}`,
      );
      if (mRes.ok) {
        const mList = await mRes.json();
        if (Array.isArray(mList) && mList.length > 0) {
          iceServers.push(...mList);
          hasTurn = true;
        }
      }
    }

    // Option 3: Static self-hosted coturn credentials via secrets
    const staticUrl = Deno.env.get("STATIC_TURN_URL");
    const staticUser = Deno.env.get("STATIC_TURN_USERNAME");
    const staticPass = Deno.env.get("STATIC_TURN_CREDENTIAL");
    if (!hasTurn && staticUrl) {
      iceServers.push({
        urls: staticUrl,
        ...(staticUser ? { username: staticUser } : {}),
        ...(staticPass ? { credential: staticPass } : {}),
      });
      hasTurn = true;
    }
  } catch (err) {
    console.error("TURN credential lookup warning:", err);
  }

  return new Response(
    JSON.stringify({
      iceServers,
      hasTurn,
      ttlSeconds: 3600,
    }),
    { status: 200, headers: CORS_HEADERS },
  );
});

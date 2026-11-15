// SparkQuest Receipt Verification & Server-Side Entitlement Edge Function
// Validates Google Play Billing tokens against the Android Publisher API when
// GOOGLE_PLAY_SERVICE_ACCOUNT is configured, and enforces single-use replay protection.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

const PRODUCT_CATALOG: Record<string, { embers: number; vip: boolean; isSub: boolean }> = {
  sparkquest_gold_monthly: { embers: 0, vip: true, isSub: true },
  sparkquest_embers_100: { embers: 150, vip: false, isSub: false },
  sparkquest_embers_500: { embers: 600, vip: false, isSub: false },
  sparkquest_embers_1500: { embers: 1500, vip: false, isSub: false },
  sparkquest_spotlight_boost: { embers: 0, vip: false, isSub: false },
};

async function mintGoogleAccessToken(sa: {
  client_email: string;
  private_key: string;
}): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  const b64u = (v: string) =>
    btoa(v).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const header = b64u(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64u(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }),
  );
  const pem = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = btoa(
    String.fromCharCode(
      ...new Uint8Array(
        await crypto.subtle.sign(
          "RSASSA-PKCS1-v1_5",
          key,
          new TextEncoder().encode(`${header}.${claim}`),
        ),
      ),
    ),
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claim}.${sig}`,
    }),
  });
  if (!res.ok) return null;
  const data = await res.json();
  return data.access_token ?? null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const playSaRaw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT");

    if (!authHeader.startsWith("Bearer ") || !supabaseUrl || !anonKey || !serviceKey) {
      return new Response(
        JSON.stringify({ verified: false, error: "Authentication required" }),
        { status: 401, headers: CORS_HEADERS },
      );
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user || userData.user.is_anonymous) {
      return new Response(
        JSON.stringify({ verified: false, error: "Authenticated non-anonymous user required" }),
        { status: 401, headers: CORS_HEADERS },
      );
    }

    const uid = userData.user.id;
    const body = await req.json();
    const productId = String(body?.productId ?? "").trim();
    const purchaseToken = String(body?.purchaseToken ?? "").trim();
    const platform = String(body?.platform ?? "android").trim().toLowerCase();

    const item = PRODUCT_CATALOG[productId];
    if (!item || purchaseToken.length < 16 || platform === "web_sandbox") {
      return new Response(
        JSON.stringify({ verified: false, error: "Valid Play purchase token and SKU required" }),
        { status: 400, headers: CORS_HEADERS },
      );
    }

    if (!playSaRaw) {
      return new Response(
        JSON.stringify({
          verified: false,
          error: "GOOGLE_PLAY_SERVICE_ACCOUNT not configured for server-side receipt verification",
        }),
        { status: 503, headers: CORS_HEADERS },
      );
    }

    const sa = JSON.parse(playSaRaw);
    const accessToken = await mintGoogleAccessToken(sa);
    if (!accessToken) {
      return new Response(
        JSON.stringify({ verified: false, error: "Google Play auth error" }),
        { status: 502, headers: CORS_HEADERS },
      );
    }

    const pkg = "com.sparkquest.sparkquest";
    const verifyUrl = item.isSub
      ? `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`
      : `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

    const playRes = await fetch(verifyUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!playRes.ok) {
      return new Response(
        JSON.stringify({ verified: false, error: `Google Play rejected receipt (${playRes.status})` }),
        { status: 402, headers: CORS_HEADERS },
      );
    }
    const playData = await playRes.json();
    const isPurchased = item.isSub
      ? ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"].includes(playData.subscriptionState)
      : playData.purchaseState === 0;
    if (!isPurchased) {
      return new Response(
        JSON.stringify({ verified: false, error: "Purchase is pending, canceled, or expired" }),
        { status: 402, headers: CORS_HEADERS },
      );
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const { error: insertErr } = await admin.from("verified_purchases").insert({
      user_id: uid,
      product_id: productId,
      purchase_token: purchaseToken,
      platform,
      amount_embers: item.embers,
      granted_vip: item.vip,
    });
    if (insertErr) {
      return new Response(
        JSON.stringify({ verified: false, error: "Purchase receipt already redeemed" }),
        { status: 409, headers: CORS_HEADERS },
      );
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("embers, is_vip")
      .eq("user_id", uid)
      .maybeSingle();

    const nextEmbers = Math.max(0, Number(profile?.embers ?? 0)) + item.embers;
    const nextVip = Boolean(profile?.is_vip) || item.vip;

    await admin
      .from("profiles")
      .update({
        embers: nextEmbers,
        is_vip: nextVip,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", uid);

    return new Response(
      JSON.stringify({ verified: true, embers: nextEmbers, is_vip: nextVip }),
      { status: 200, headers: CORS_HEADERS },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ verified: false, error: String(err) }),
      { status: 500, headers: CORS_HEADERS },
    );
  }
});

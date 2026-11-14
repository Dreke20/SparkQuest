// SparkQuest Push Notification Dispatcher Edge Function (FCM HTTP v1 + Supabase Webhooks)
// Configure Database Webhooks on public.messages (INSERT), public.matches (INSERT), and public.call_signals (INSERT).
// Set secret: supabase secrets set FIREBASE_SERVICE_ACCOUNT='<service-account-json>'
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

async function getGoogleAccessToken(sa: {
  client_email: string;
  private_key: string;
}): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const claim = btoa(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }),
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const pem = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claim}.${sig}`,
    }),
  });
  if (!tokenRes.ok) return null;
  const tokenJson = await tokenRes.json();
  return tokenJson.access_token ?? null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const payload = await req.json();
    const table = payload?.table as string | undefined;
    const record = (payload?.record ?? {}) as Record<string, unknown>;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

    if (!saRaw || !supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({
          dispatched: false,
          reason: "FIREBASE_SERVICE_ACCOUNT secret not configured; clients fall back to WebSocket + JobScheduler sync.",
        }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    let recipientId = "";
    let title = "SparkQuest";
    let body = "You have a new update!";
    let channelId = "sparkquest_messages";

    if (table === "call_signals" && record.status === "ringing") {
      recipientId = String(record.callee_id ?? "");
      title = "Incoming Spark Call";
      body = `${record.caller_name ?? "A match"} is calling on SparkQuest`;
      channelId = "sparkquest_calls";
    } else if (table === "matches") {
      recipientId = String(record.user_id_2 ?? "");
      title = "New Mutual Spark!";
      body = `${record.user_name ?? "An adventurer"} sparked with you!`;
      channelId = "sparkquest_sparks";
    } else if (table === "messages") {
      const matchId = String(record.match_id ?? "");
      const senderId = String(record.sender_id ?? "");
      const { data: matchRow } = await admin
        .from("matches")
        .select("user_id_1, user_id_2")
        .eq("id", matchId)
        .maybeSingle();
      if (matchRow) {
        recipientId =
          matchRow.user_id_1 === senderId
            ? String(matchRow.user_id_2)
            : String(matchRow.user_id_1);
      }
      title = "New SparkQuest Message";
      body = String(record.content ?? "Sent a message");
      channelId = "sparkquest_messages";
    }

    if (!recipientId) {
      return new Response(
        JSON.stringify({ dispatched: false, reason: "No recipient resolved" }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("fcm_token")
      .eq("user_id", recipientId)
      .maybeSingle();

    const fcmToken = profile?.fcm_token as string | undefined;
    if (!fcmToken) {
      return new Response(
        JSON.stringify({ dispatched: false, reason: "Recipient has no registered fcm_token" }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    const sa = JSON.parse(saRaw);
    const accessToken = await getGoogleAccessToken(sa);
    if (!accessToken) {
      return new Response(
        JSON.stringify({ dispatched: false, reason: "Failed to mint Google OAuth access token" }),
        { status: 500, headers: CORS_HEADERS },
      );
    }

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: { title, body },
            android: {
              priority: "HIGH",
              notification: { channel_id: channelId },
            },
            data: { table: table ?? "", channel_id: channelId },
          },
        }),
      },
    );

    return new Response(
      JSON.stringify({ dispatched: fcmRes.ok, status: fcmRes.status }),
      { status: 200, headers: CORS_HEADERS },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ dispatched: false, error: String(err) }),
      { status: 500, headers: CORS_HEADERS },
    );
  }
});

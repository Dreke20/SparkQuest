// SparkQuest Complete Account Deletion Edge Function
// Purges all DB rows, Storage objects (avatars, stories, voice-notes),
// AND the Supabase auth.users record in compliance with Google Play policy.
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
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!authHeader.startsWith("Bearer ") || !supabaseUrl || !anonKey || !serviceKey) {
      return new Response(JSON.stringify({ deleted: false, error: "Authentication required" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ deleted: false, error: "Invalid user session" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const uid = userData.user.id;
    const admin = createClient(supabaseUrl, serviceKey);

    for (const bucket of ["avatars", "stories", "voice-notes"]) {
      const { data: files } = await admin.storage.from(bucket).list(uid);
      if (files && files.length > 0) {
        const paths = files.map((f) => `${uid}/${f.name}`);
        await admin.storage.from(bucket).remove(paths);
      }
    }

    await admin.rpc("delete_user_account_data", { p_uid: uid, p_auth_uuid: uid });
    await admin.auth.admin.deleteUser(uid);

    return new Response(JSON.stringify({ deleted: true, user_id: uid }), {
      status: 200,
      headers: CORS_HEADERS,
    });
  } catch (err) {
    return new Response(JSON.stringify({ deleted: false, error: String(err) }), {
      status: 500,
      headers: CORS_HEADERS,
    });
  }
});

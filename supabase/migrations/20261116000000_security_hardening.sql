-- =========================================================
-- SparkQuest: Comprehensive Security Hardening Migration
-- Fixes:
--   1. Privilege escalation & unlimited Embers / VIP / Verified writes
--   2. Public exposure of private balances / fcm_token / coordinates
--   3. Open anonymous storage overwrite / delete policies
--   4. Destructive reset_onboarding_state() & overly broad USING (true) RLS
--   5. Broken / spoofable record_swipe_and_check_match()
--   6. Incomplete delete_user_account() (tables + storage + auth.users)
--   7. Server-side age >= 18 enforcement & purchase idempotency table
-- =========================================================

-- 1. Remove dangerous testing wipe helper immediately
REVOKE ALL ON FUNCTION public.reset_onboarding_state() FROM PUBLIC;
DROP FUNCTION IF EXISTS public.reset_onboarding_state();
DROP FUNCTION IF EXISTS public.increment_embers(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.increment_embers(TEXT, INTEGER);

-- Helper: True only for signed-in, non-anonymous users
CREATE OR REPLACE FUNCTION public.is_authenticated_non_anon()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT auth.uid() IS NOT NULL
     AND NOT COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false);
$$;

-- 2. Verified In-App Purchases ledger (replay-attack protection)
CREATE TABLE IF NOT EXISTS public.verified_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL UNIQUE,
  platform TEXT DEFAULT 'android' NOT NULL,
  amount_embers INTEGER DEFAULT 0 NOT NULL,
  granted_vip BOOLEAN DEFAULT false NOT NULL,
  verified_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.verified_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own verified purchases" ON public.verified_purchases;
CREATE POLICY "Users read own verified purchases" ON public.verified_purchases
  FOR SELECT USING (
    auth.uid()::text = user_id OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Service role manages verified purchases" ON public.verified_purchases;
CREATE POLICY "Service role manages verified purchases" ON public.verified_purchases
  FOR ALL USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 3. Enforce adult age >= 18 on profiles
UPDATE public.profiles SET age = 18 WHERE age IS NULL OR age < 18;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_age_adult;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_age_adult CHECK (age >= 18);

-- 4. Lock paid / verified / progression columns on public.profiles
CREATE OR REPLACE FUNCTION public.protect_profile_entitlements()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'service_role'
     OR current_setting('sparkquest.allow_entitlement_write', true) = 'true'
     OR current_user IN ('postgres', 'supabase_admin') THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    NEW.is_vip := false;
    NEW.is_verified := false;
    NEW.level := 1;
    NEW.xp := 0;
    NEW.embers := 150;
    RETURN NEW;
  END IF;

  -- On UPDATE, clients cannot elevate VIP, verification, XP, level, or add embers directly.
  NEW.is_vip := OLD.is_vip;
  NEW.is_verified := OLD.is_verified;
  NEW.level := OLD.level;
  NEW.xp := OLD.xp;
  IF NEW.embers > OLD.embers THEN
    NEW.embers := OLD.embers;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_entitlements ON public.profiles;
CREATE TRIGGER trg_protect_profile_entitlements
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_entitlements();

-- 5. Server-side bounded gameplay & verification RPCs (user derived from auth.uid())
CREATE OR REPLACE FUNCTION public.earn_gameplay_embers(
  p_source TEXT,
  p_amount INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_delta INTEGER := 0;
  v_xp_delta INTEGER := 0;
  v_new_embers INTEGER;
  v_new_xp INTEGER;
  v_new_level INTEGER;
BEGIN
  IF NOT public.is_authenticated_non_anon() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  CASE p_source
    WHEN 'quest_reward' THEN
      v_delta := LEAST(GREATEST(COALESCE(p_amount, 10), 1), 50);
      v_xp_delta := 50;
    WHEN 'daily_streak' THEN
      v_delta := LEAST(GREATEST(COALESCE(p_amount, 10), 1), 25);
      v_xp_delta := 25;
    WHEN 'rewarded_ad' THEN
      v_delta := LEAST(GREATEST(COALESCE(p_amount, 5), 1), 15);
      v_xp_delta := 10;
    WHEN 'referral' THEN
      v_delta := LEAST(GREATEST(COALESCE(p_amount, 50), 1), 100);
      v_xp_delta := 100;
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'Invalid reward source');
  END CASE;

  PERFORM set_config('sparkquest.allow_entitlement_write', 'true', true);

  UPDATE public.profiles
  SET embers = GREATEST(0, COALESCE(embers, 0) + v_delta),
      xp = GREATEST(0, COALESCE(xp, 0) + v_xp_delta),
      level = GREATEST(1, FLOOR((GREATEST(0, COALESCE(xp, 0) + v_xp_delta)) / 250) + 1)::int,
      updated_at = now()
  WHERE user_id = v_uid
  RETURNING embers, xp, level INTO v_new_embers, v_new_xp, v_new_level;

  RETURN jsonb_build_object(
    'success', true,
    'embers', COALESCE(v_new_embers, 0),
    'xp', COALESCE(v_new_xp, 0),
    'level', COALESCE(v_new_level, 1)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.spend_user_embers(
  p_cost INTEGER,
  p_item TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_new_embers INTEGER;
BEGIN
  IF NOT public.is_authenticated_non_anon() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;
  IF p_cost IS NULL OR p_cost <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid cost');
  END IF;

  PERFORM set_config('sparkquest.allow_entitlement_write', 'true', true);

  UPDATE public.profiles
  SET embers = embers - p_cost,
      selected_frame = CASE
        WHEN p_item LIKE 'frame:%' THEN split_part(p_item, ':', 2)
        ELSE selected_frame
      END,
      updated_at = now()
  WHERE user_id = v_uid AND COALESCE(embers, 0) >= p_cost
  RETURNING embers INTO v_new_embers;

  IF v_new_embers IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient embers');
  END IF;

  RETURN jsonb_build_object('success', true, 'embers', v_new_embers);
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_liveness_selfie(p_selfie_url TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
BEGIN
  IF NOT public.is_authenticated_non_anon() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;
  IF COALESCE(length(trim(p_selfie_url)), 0) < 12
     OR POSITION('/avatars/' || v_uid || '/' IN p_selfie_url) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Uploaded verification selfie required');
  END IF;

  PERFORM set_config('sparkquest.allow_entitlement_write', 'true', true);

  UPDATE public.profiles
  SET is_verified = true,
      updated_at = now()
  WHERE user_id = v_uid;

  RETURN jsonb_build_object('success', true, 'is_verified', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.join_guild_raid(p_raid_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_name TEXT;
  v_next INTEGER;
BEGIN
  IF NOT public.is_authenticated_non_anon() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  SELECT COALESCE(NULLIF(trim(name), ''), 'Adventurer') INTO v_name
  FROM public.profiles WHERE user_id = v_uid LIMIT 1;

  INSERT INTO public.guild_raid_members (raid_id, user_id, user_name, contribution)
  VALUES (p_raid_id, v_uid, COALESCE(v_name, 'Adventurer'), 1)
  ON CONFLICT (raid_id, user_id) DO NOTHING;

  UPDATE public.guild_raids r
  SET current_progress = (
    SELECT COUNT(*) FROM public.guild_raid_members m WHERE m.raid_id = r.id
  )
  WHERE r.id = p_raid_id
  RETURNING current_progress INTO v_next;

  RETURN jsonb_build_object('success', true, 'current_progress', COALESCE(v_next, 0));
END;
$$;

-- 6. Lock down public.profiles & expose safe public discovery view / RPC
DROP POLICY IF EXISTS "Allow public read access on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public insert/update on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;

CREATE POLICY "Users read own profile" ON public.profiles
  FOR SELECT USING (
    auth.uid()::text = user_id OR auth.role() = 'service_role'
  );

CREATE POLICY "Users insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (
    public.is_authenticated_non_anon() AND auth.uid()::text = user_id
  );

CREATE POLICY "Users update own profile" ON public.profiles
  FOR UPDATE USING (
    public.is_authenticated_non_anon() AND auth.uid()::text = user_id
  )
  WITH CHECK (
    public.is_authenticated_non_anon() AND auth.uid()::text = user_id
  );

CREATE OR REPLACE FUNCTION public.get_discovery_profiles()
RETURNS TABLE (
  user_id TEXT,
  name TEXT,
  age INTEGER,
  bio TEXT,
  avatar_url TEXT,
  photos JSONB,
  intro_video_url TEXT,
  city TEXT,
  tags TEXT[],
  level INTEGER,
  xp INTEGER,
  is_verified BOOLEAN,
  selected_frame TEXT,
  prompts JSONB,
  relationship_intent TEXT,
  pronouns TEXT,
  vitals JSONB,
  anthem_title TEXT,
  anthem_artist TEXT,
  is_free_tonight BOOLEAN,
  is_standout BOOLEAN,
  voice_prompt_title TEXT,
  voice_prompt_url TEXT,
  preferred_language TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.user_id,
    p.name,
    p.age,
    p.bio,
    p.avatar_url,
    COALESCE(p.photos, '[]'::jsonb),
    COALESCE(p.intro_video_url, ''),
    p.city,
    p.tags,
    p.level,
    p.xp,
    p.is_verified,
    p.selected_frame,
    p.prompts,
    p.relationship_intent,
    p.pronouns,
    p.vitals,
    p.anthem_title,
    p.anthem_artist,
    p.is_free_tonight,
    p.is_standout,
    p.voice_prompt_title,
    p.voice_prompt_url,
    COALESCE(p.preferred_language, 'en'),
    ROUND(COALESCE(p.lat, 37.7749)::numeric, 2)::double precision,
    ROUND(COALESCE(p.lng, -122.4194)::numeric, 2)::double precision,
    p.created_at,
    p.updated_at
  FROM public.profiles p
  WHERE auth.uid() IS NOT NULL
    AND p.user_id <> auth.uid()::text
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE (b.blocker_id = auth.uid()::text AND b.blocked_id = p.user_id)
         OR (b.blocker_id = p.user_id AND b.blocked_id = auth.uid()::text)
    );
$$;

DROP VIEW IF EXISTS public.discovery_profiles;
CREATE VIEW public.discovery_profiles AS
  SELECT * FROM public.get_discovery_profiles();

REVOKE ALL ON public.discovery_profiles FROM PUBLIC;
REVOKE ALL ON public.discovery_profiles FROM anon;
GRANT SELECT ON public.discovery_profiles TO authenticated;

-- Update nearby_profiles to return ONLY safe non-PII discovery columns
DROP FUNCTION IF EXISTS public.nearby_profiles(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
CREATE OR REPLACE FUNCTION public.nearby_profiles(
  user_lat DOUBLE PRECISION DEFAULT 37.7749,
  user_lng DOUBLE PRECISION DEFAULT -122.4194,
  radius_miles DOUBLE PRECISION DEFAULT 25.0
)
RETURNS TABLE (
  user_id TEXT,
  name TEXT,
  age INTEGER,
  bio TEXT,
  avatar_url TEXT,
  photos JSONB,
  intro_video_url TEXT,
  city TEXT,
  tags TEXT[],
  level INTEGER,
  xp INTEGER,
  is_verified BOOLEAN,
  selected_frame TEXT,
  prompts JSONB,
  relationship_intent TEXT,
  pronouns TEXT,
  vitals JSONB,
  anthem_title TEXT,
  anthem_artist TEXT,
  is_free_tonight BOOLEAN,
  is_standout BOOLEAN,
  voice_prompt_title TEXT,
  voice_prompt_url TEXT,
  preferred_language TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT d.*
  FROM public.get_discovery_profiles() d
  WHERE (
    3958.8 * acos(
      LEAST(1.0, GREATEST(-1.0,
        cos(radians(user_lat)) * cos(radians(d.lat)) *
        cos(radians(d.lng) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(d.lat))
      ))
    )
  ) <= radius_miles
  ORDER BY d.updated_at DESC
  LIMIT 50;
$$;

-- 7. Fix record_swipe_and_check_match (Strict auth, no auto-match, no display_name matching)
CREATE OR REPLACE FUNCTION public.record_swipe_and_check_match(
  p_target_id TEXT,
  p_direction TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_is_mutual BOOLEAN := false;
  v_match_id UUID := NULL;
  v_u1 TEXT;
  v_u2 TEXT;
  v_target_name TEXT := '';
  v_target_avatar TEXT := '';
BEGIN
  IF NOT public.is_authenticated_non_anon() THEN
    RETURN jsonb_build_object('success', false, 'is_match', false, 'error', 'Unauthorized');
  END IF;
  IF p_direction NOT IN ('left', 'right', 'superlike') THEN
    RETURN jsonb_build_object('success', false, 'is_match', false, 'error', 'Invalid direction');
  END IF;
  IF p_target_id IS NULL OR length(trim(p_target_id)) = 0 OR p_target_id = v_uid THEN
    RETURN jsonb_build_object('success', false, 'is_match', false, 'error', 'Invalid target');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.blocks b
    WHERE (b.blocker_id = v_uid AND b.blocked_id = p_target_id)
       OR (b.blocker_id = p_target_id AND b.blocked_id = v_uid)
  ) THEN
    RETURN jsonb_build_object('success', false, 'is_match', false, 'error', 'Target blocked');
  END IF;

  INSERT INTO public.swipes (user_id, profile, direction, timestamp)
  VALUES (v_uid, p_target_id, p_direction, now());

  IF p_direction IN ('right', 'superlike') THEN
    SELECT EXISTS (
      SELECT 1 FROM public.swipes s
      WHERE s.user_id = p_target_id
        AND s.profile = v_uid
        AND s.direction IN ('right', 'superlike')
    ) INTO v_is_mutual;

    IF v_is_mutual THEN
      IF v_uid < p_target_id THEN
        v_u1 := v_uid;
        v_u2 := p_target_id;
      ELSE
        v_u1 := p_target_id;
        v_u2 := v_uid;
      END IF;

      SELECT COALESCE(name, ''), COALESCE(avatar_url, '')
      INTO v_target_name, v_target_avatar
      FROM public.profiles
      WHERE user_id = p_target_id
      LIMIT 1;

      INSERT INTO public.matches (user_id_1, user_id_2, user_name, avatar_url)
      VALUES (v_u1, v_u2, v_target_name, v_target_avatar)
      ON CONFLICT DO NOTHING
      RETURNING id INTO v_match_id;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'is_match', v_is_mutual,
    'target_id', p_target_id,
    'match_id', v_match_id
  );
END;
$$;

-- 8. Complete Store-Compliant Account Deletion (Tables + Storage + auth.users)
CREATE OR REPLACE FUNCTION public.delete_user_account_data(p_uid TEXT, p_auth_uuid UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth
AS $$
BEGIN
  IF p_uid IS NULL OR length(trim(p_uid)) = 0 THEN
    RETURN false;
  END IF;

  DELETE FROM public.messages
  WHERE sender_id = p_uid
     OR match_id IN (SELECT id FROM public.matches WHERE user_id_1 = p_uid OR user_id_2 = p_uid);
  DELETE FROM public.coop_quests
  WHERE match_id IN (SELECT id FROM public.matches WHERE user_id_1 = p_uid OR user_id_2 = p_uid);
  DELETE FROM public.matches WHERE user_id_1 = p_uid OR user_id_2 = p_uid;
  DELETE FROM public.swipes WHERE user_id = p_uid OR profile = p_uid;
  DELETE FROM public.map_checkins WHERE user_id = p_uid;
  DELETE FROM public.blocks WHERE blocker_id = p_uid OR blocked_id = p_uid;
  DELETE FROM public.reports WHERE reporter_id = p_uid OR reported_id = p_uid;
  DELETE FROM public.stories WHERE user_id = p_uid;
  DELETE FROM public.voice_lounge_members WHERE user_id = p_uid;
  DELETE FROM public.voice_lounges WHERE host_id = p_uid;
  DELETE FROM public.call_signals WHERE caller_id = p_uid OR callee_id = p_uid;
  DELETE FROM public.date_guard_sessions WHERE user_id = p_uid;
  DELETE FROM public.ble_beacons WHERE user_id = p_uid;
  DELETE FROM public.venue_bookings WHERE user_id = p_uid;
  DELETE FROM public.ar_moments WHERE user_id = p_uid;
  DELETE FROM public.sos_alerts WHERE user_id = p_uid;
  DELETE FROM public.guild_raid_members WHERE user_id = p_uid;
  DELETE FROM public.analytics_events WHERE user_id = p_uid;
  DELETE FROM public.verified_purchases WHERE user_id = p_uid;
  DELETE FROM public.profiles WHERE user_id = p_uid;

  DELETE FROM storage.objects
  WHERE bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND (
      (p_auth_uuid IS NOT NULL AND owner = p_auth_uuid)
      OR name LIKE (p_uid || '/%')
    );

  IF p_auth_uuid IS NOT NULL THEN
    DELETE FROM auth.users WHERE id = p_auth_uuid;
  END IF;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account_data(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account_data(TEXT, UUID) TO service_role;

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth
AS $$
DECLARE
  v_auth_uuid UUID := auth.uid();
BEGIN
  IF v_auth_uuid IS NULL THEN
    RETURN false;
  END IF;
  RETURN public.delete_user_account_data(v_auth_uuid::text, v_auth_uuid);
END;
$$;

-- 9. Tighten Storage Bucket Policies (Remove unauthenticated/unowned access)
DROP POLICY IF EXISTS "Allow public read on SparkQuest buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow public upload on SparkQuest buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow public update on SparkQuest buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow public delete on SparkQuest buckets" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users read SparkQuest media" ON storage.objects;
DROP POLICY IF EXISTS "Users upload own SparkQuest media" ON storage.objects;
DROP POLICY IF EXISTS "Users update own SparkQuest media" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own SparkQuest media" ON storage.objects;

CREATE POLICY "Authenticated users read SparkQuest media" ON storage.objects
  FOR SELECT USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND public.is_authenticated_non_anon()
  );

CREATE POLICY "Users upload own SparkQuest media" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND public.is_authenticated_non_anon()
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users update own SparkQuest media" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND public.is_authenticated_non_anon()
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND public.is_authenticated_non_anon()
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users delete own SparkQuest media" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND public.is_authenticated_non_anon()
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 10. Tighten ALL remaining USING (true) table RLS policies
-- Matches
DROP POLICY IF EXISTS "Allow public read access on matches" ON public.matches;
DROP POLICY IF EXISTS "Allow public insert/update on matches" ON public.matches;
CREATE POLICY "Participants read matches" ON public.matches
  FOR SELECT USING (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (user_id_1, user_id_2)
  );
CREATE POLICY "Participants insert matches" ON public.matches
  FOR INSERT WITH CHECK (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (user_id_1, user_id_2)
  );
CREATE POLICY "Participants update matches" ON public.matches
  FOR UPDATE USING (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (user_id_1, user_id_2)
  );

-- Messages
DROP POLICY IF EXISTS "Allow public read access on messages" ON public.messages;
DROP POLICY IF EXISTS "Allow public insert on messages" ON public.messages;
CREATE POLICY "Match participants read messages" ON public.messages
  FOR SELECT USING (
    public.is_authenticated_non_anon()
    AND (
      sender_id = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = messages.match_id
          AND auth.uid()::text IN (m.user_id_1, m.user_id_2)
      )
    )
  );
CREATE POLICY "Senders insert match messages" ON public.messages
  FOR INSERT WITH CHECK (
    public.is_authenticated_non_anon()
    AND sender_id = auth.uid()::text
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = messages.match_id
        AND auth.uid()::text IN (m.user_id_1, m.user_id_2)
    )
  );

-- Swipes, Blocks, Reports
DROP POLICY IF EXISTS "Allow public access on swipes" ON public.swipes;
CREATE POLICY "Users manage own swipes" ON public.swipes
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Allow public access on blocks" ON public.blocks;
CREATE POLICY "Users manage own blocks" ON public.blocks
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = blocker_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = blocker_id);

DROP POLICY IF EXISTS "Allow public access on reports" ON public.reports;
CREATE POLICY "Users insert own reports" ON public.reports
  FOR INSERT WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = reporter_id);
CREATE POLICY "Users view own reports" ON public.reports
  FOR SELECT USING (public.is_authenticated_non_anon() AND auth.uid()::text = reporter_id);

-- Map check-ins
DROP POLICY IF EXISTS "Allow public access on map_checkins" ON public.map_checkins;
CREATE POLICY "Authenticated read checkins" ON public.map_checkins
  FOR SELECT USING (public.is_authenticated_non_anon());
CREATE POLICY "Users manage own checkins" ON public.map_checkins
  FOR INSERT WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);
CREATE POLICY "Users delete own checkins" ON public.map_checkins
  FOR DELETE USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

-- Co-Op Quests
DROP POLICY IF EXISTS "Allow public read access on coop_quests" ON public.coop_quests;
DROP POLICY IF EXISTS "Allow public update on coop_quests" ON public.coop_quests;
CREATE POLICY "Match participants manage coop quests" ON public.coop_quests
  FOR ALL USING (
    public.is_authenticated_non_anon()
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = coop_quests.match_id
        AND auth.uid()::text IN (m.user_id_1, m.user_id_2)
    )
  )
  WITH CHECK (
    public.is_authenticated_non_anon()
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = coop_quests.match_id
        AND auth.uid()::text IN (m.user_id_1, m.user_id_2)
    )
  );

-- Date Guard & SOS Alerts (Strict private safety records)
DROP POLICY IF EXISTS "Allow public access on date_guard" ON public.date_guard_sessions;
CREATE POLICY "Users manage own date guard sessions" ON public.date_guard_sessions
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public manage sos_alerts" ON public.sos_alerts;
CREATE POLICY "Users manage own sos alerts" ON public.sos_alerts
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

-- Call Signals
DROP POLICY IF EXISTS "Allow public access on call_signals" ON public.call_signals;
DROP POLICY IF EXISTS "Users can view incoming and outgoing call signals" ON public.call_signals;
DROP POLICY IF EXISTS "Callers can initiate call signals" ON public.call_signals;
DROP POLICY IF EXISTS "Participants can update call signals" ON public.call_signals;
DROP POLICY IF EXISTS "Participants can delete call signals" ON public.call_signals;
CREATE POLICY "Call participants read signals" ON public.call_signals
  FOR SELECT USING (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (caller_id, callee_id)
  );
CREATE POLICY "Callers initiate signals" ON public.call_signals
  FOR INSERT WITH CHECK (
    public.is_authenticated_non_anon() AND auth.uid()::text = caller_id
  );
CREATE POLICY "Call participants update signals" ON public.call_signals
  FOR UPDATE USING (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (caller_id, callee_id)
  );
CREATE POLICY "Call participants delete signals" ON public.call_signals
  FOR DELETE USING (
    public.is_authenticated_non_anon() AND auth.uid()::text IN (caller_id, callee_id)
  );

-- Stories & AR Moments
DROP POLICY IF EXISTS "Allow public access on stories" ON public.stories;
DROP POLICY IF EXISTS "Public can view active stories" ON public.stories;
DROP POLICY IF EXISTS "Users can create own stories" ON public.stories;
DROP POLICY IF EXISTS "Users can delete own stories" ON public.stories;
CREATE POLICY "Authenticated view non-blocked stories" ON public.stories
  FOR SELECT USING (
    public.is_authenticated_non_anon()
    AND expires_at > now()
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE (b.blocker_id = auth.uid()::text AND b.blocked_id = stories.user_id)
         OR (b.blocker_id = stories.user_id AND b.blocked_id = auth.uid()::text)
    )
  );
CREATE POLICY "Users create own stories" ON public.stories
  FOR INSERT WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);
CREATE POLICY "Users delete own stories" ON public.stories
  FOR DELETE USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public manage ar_moments" ON public.ar_moments;
CREATE POLICY "Authenticated read ar moments" ON public.ar_moments
  FOR SELECT USING (public.is_authenticated_non_anon());
CREATE POLICY "Users create own ar moments" ON public.ar_moments
  FOR INSERT WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);
CREATE POLICY "Users delete own ar moments" ON public.ar_moments
  FOR DELETE USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

-- BLE Beacons, Venue Bookings, Guild Raids & Voice Lounges
DROP POLICY IF EXISTS "Public read active ble_beacons" ON public.ble_beacons;
DROP POLICY IF EXISTS "Public upsert own ble_beacons" ON public.ble_beacons;
CREATE POLICY "Authenticated read active beacons" ON public.ble_beacons
  FOR SELECT USING (public.is_authenticated_non_anon() AND is_active = true);
CREATE POLICY "Users manage own ble beacon" ON public.ble_beacons
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public manage venue_bookings" ON public.venue_bookings;
CREATE POLICY "Users manage own venue bookings" ON public.venue_bookings
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public insert/update guild_raids" ON public.guild_raids;
DROP POLICY IF EXISTS "Public upsert guild_raid_members" ON public.guild_raid_members;
CREATE POLICY "Users join own guild raids" ON public.guild_raid_members
  FOR INSERT WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Members can view lounge attendees" ON public.voice_lounge_members;
CREATE POLICY "Authenticated view lounge attendees" ON public.voice_lounge_members
  FOR SELECT USING (public.is_authenticated_non_anon());

DROP POLICY IF EXISTS "Users can join or update lounge presence" ON public.voice_lounge_members;
CREATE POLICY "Users manage own lounge presence" ON public.voice_lounge_members
  FOR ALL USING (public.is_authenticated_non_anon() AND auth.uid()::text = user_id)
  WITH CHECK (public.is_authenticated_non_anon() AND auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Public insert analytics" ON public.analytics_events;
CREATE POLICY "Users insert own analytics" ON public.analytics_events
  FOR INSERT WITH CHECK (
    public.is_authenticated_non_anon() AND auth.uid()::text = user_id
  );

-- Lock down private media buckets so unauthenticated /object/public/ access is blocked
UPDATE storage.buckets
SET public = false
WHERE id IN ('stories', 'voice-notes');

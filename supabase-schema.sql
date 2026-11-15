-- =========================================================
-- SparkQuest Production Supabase Schema
-- =========================================================

-- Enable pgcrypto for UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Users Table (Core Profile & Gamification Stats)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    display_name TEXT DEFAULT 'Explorer',
    age INTEGER NOT NULL DEFAULT 18 CHECK (age >= 18),
    bio TEXT DEFAULT 'Ready for the next quest ✨',
    photo_url TEXT DEFAULT '',
    tags JSONB DEFAULT '["Gaming", "Coffee", "Adventure"]'::jsonb,
    is_premium BOOLEAN DEFAULT false NOT NULL,
    premium_tier TEXT DEFAULT 'free',
    is_verified BOOLEAN DEFAULT false NOT NULL,
    embers INTEGER DEFAULT 325 NOT NULL,
    inventory JSONB DEFAULT '{"boost": 2, "superlike": 5}'::jsonb NOT NULL,
    quest_progress JSONB DEFAULT '{"engage1": {"current": 7, "target": 10, "claimed": false}, "engage2": {"current": 1, "target": 3, "claimed": false}, "engage3": {"current": 1, "target": 1, "claimed": true}, "engage4": {"current": 0, "target": 1, "claimed": false}, "engage5": {"current": 0, "target": 1, "claimed": false}, "engage6": {"current": 0, "target": 1, "claimed": false}}'::jsonb NOT NULL,
    lat NUMERIC,
    lng NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Matches Table (Mutual Sparks)
CREATE TABLE IF NOT EXISTS matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user1_id UUID NOT NULL,
    user2_id UUID NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL, -- 'active', 'unmatched'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_match_pair UNIQUE (user1_id, user2_id)
);

-- 3. Messages Table (Real-time Chat)
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL, -- Sender
    partner_id TEXT NOT NULL, -- Recipient (User UUID or bot ID)
    text TEXT NOT NULL,
    type TEXT DEFAULT 'sent', -- 'sent', 'received', 'system'
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Swipes Table
CREATE TABLE IF NOT EXISTS swipes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    profile TEXT NOT NULL, -- Target user UUID or name
    direction TEXT NOT NULL, -- 'left', 'right', 'superlike'
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Safety & UGC Moderation Tables (Mandatory for App Store & Play Store)
CREATE TABLE IF NOT EXISTS reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reported_id TEXT NOT NULL,
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS blocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    blocked_id TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id)
);

-- 6. Neon Night / Map Check-ins
CREATE TABLE IF NOT EXISTS map_checkins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    venue_id TEXT NOT NULL,
    lat NUMERIC,
    lng NUMERIC,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. Multiplayer Quests
CREATE TABLE IF NOT EXISTS active_quests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    quest_type TEXT NOT NULL,
    user1_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    user2_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    user1_ready BOOLEAN DEFAULT false,
    user2_ready BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending'
);

-- =========================================================
-- Row Level Security (RLS)
-- =========================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_quests ENABLE ROW LEVEL SECURITY;

-- Users Policies (Private row ownership; discovery uses public_users view)
DROP POLICY IF EXISTS "Public can view discovery profiles" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users FOR SELECT
    USING (auth.uid() = id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users FOR INSERT
    WITH CHECK (auth.uid() = id AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE
    USING (auth.uid() = id AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false)
    WITH CHECK (auth.uid() = id AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

-- Protect server-managed entitlement columns from client UPDATEs
CREATE OR REPLACE FUNCTION public.protect_users_entitlements()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'service_role' OR current_setting('app.allow_entitlement_write', true) = 'on' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.embers := 0;
    NEW.is_premium := false;
    NEW.premium_tier := 'free';
    NEW.is_verified := false;
    NEW.inventory := '{}'::jsonb;
  ELSE
    NEW.embers := OLD.embers;
    NEW.is_premium := OLD.is_premium;
    NEW.premium_tier := OLD.premium_tier;
    NEW.is_verified := OLD.is_verified;
    NEW.inventory := OLD.inventory;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_users_entitlements ON public.users;
CREATE TRIGGER trg_protect_users_entitlements
  BEFORE INSERT OR UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_users_entitlements();

-- Non-PII discovery projection (omits email, embers, premium flags, exact GPS)
CREATE OR REPLACE FUNCTION public.get_public_users()
RETURNS TABLE (
    id UUID,
    display_name TEXT,
    age INTEGER,
    bio TEXT,
    photo_url TEXT,
    tags JSONB,
    is_verified BOOLEAN,
    lat NUMERIC,
    lng NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.display_name,
    u.age,
    u.bio,
    u.photo_url,
    u.tags,
    u.is_verified,
    ROUND(COALESCE(u.lat, 37.7749)::numeric, 2),
    ROUND(COALESCE(u.lng, -122.4194)::numeric, 2),
    u.created_at,
    u.updated_at
  FROM public.users u
  WHERE auth.uid() IS NOT NULL
    AND u.id <> auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE (b.blocker_id = auth.uid() AND b.blocked_id = u.id::text)
    );
$$;

DROP VIEW IF EXISTS public.public_users;
CREATE VIEW public.public_users AS
  SELECT * FROM public.get_public_users();
REVOKE ALL ON public.public_users FROM PUBLIC;
REVOKE ALL ON public.public_users FROM anon;
GRANT SELECT ON public.public_users TO authenticated;

-- Matches Policies
DROP POLICY IF EXISTS "Users can view their matches" ON matches;
CREATE POLICY "Users can view their matches" ON matches FOR SELECT 
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can insert matches" ON matches;
CREATE POLICY "Users can insert matches" ON matches FOR INSERT 
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages Policies (Bidirectional Access for Conversation)
DROP POLICY IF EXISTS "Users can view their conversation messages" ON messages;
CREATE POLICY "Users can view their conversation messages" ON messages FOR SELECT 
    USING (auth.uid() = user_id OR auth.uid()::text = partner_id);

DROP POLICY IF EXISTS "Users can insert messages" ON messages;
CREATE POLICY "Users can insert messages" ON messages FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Swipes Policies
DROP POLICY IF EXISTS "Users can view own swipes" ON swipes;
CREATE POLICY "Users can view own swipes" ON swipes FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own swipes" ON swipes;
CREATE POLICY "Users can insert own swipes" ON swipes FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Reports & Blocks Policies
DROP POLICY IF EXISTS "Users can insert reports" ON reports;
CREATE POLICY "Users can insert reports" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Users can view own blocks" ON blocks;
CREATE POLICY "Users can view own blocks" ON blocks FOR SELECT USING (auth.uid() = blocker_id);

DROP POLICY IF EXISTS "Users can insert blocks" ON blocks;
CREATE POLICY "Users can insert blocks" ON blocks FOR INSERT WITH CHECK (auth.uid() = blocker_id);

DROP POLICY IF EXISTS "Users can delete own blocks" ON blocks;
CREATE POLICY "Users can delete own blocks" ON blocks FOR DELETE USING (auth.uid() = blocker_id);

-- Check-ins Policies
DROP POLICY IF EXISTS "Users can view all check-ins" ON map_checkins;
CREATE POLICY "Users can view all check-ins" ON map_checkins FOR SELECT
    USING (auth.uid() IS NOT NULL AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

DROP POLICY IF EXISTS "Users can insert own check-ins" ON map_checkins;
CREATE POLICY "Users can insert own check-ins" ON map_checkins FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Active Quests Policies
DROP POLICY IF EXISTS "Users can view their quests" ON active_quests;
CREATE POLICY "Users can view their quests" ON active_quests FOR SELECT 
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can manage their quests" ON active_quests;
CREATE POLICY "Users can manage their quests" ON active_quests FOR ALL 
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- =========================================================
-- Realtime Publications
-- =========================================================
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE map_checkins;
ALTER PUBLICATION supabase_realtime ADD TABLE active_quests;

-- =========================================================
-- Stored Procedures & Business Logic (RPCs)
-- =========================================================

-- Drop legacy insecure RPCs if present
DROP FUNCTION IF EXISTS public.increment_embers(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.reset_onboarding_state();

-- 1. Server-Derived Gameplay Embers Award & Spend (derives auth.uid(), never accepts user_id)
CREATE OR REPLACE FUNCTION public.earn_gameplay_embers(p_source TEXT, p_amount INTEGER DEFAULT 5)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_capped INTEGER;
  v_new INTEGER;
BEGIN
  IF v_uid IS NULL OR COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_source NOT IN ('daily_streak', 'coop_quest', 'voice_lounge', 'quest_claim', 'rewarded_ad') THEN
    RAISE EXCEPTION 'Invalid gameplay reward source: %', p_source;
  END IF;
  v_capped := LEAST(GREATEST(COALESCE(p_amount, 0), 1), 25);
  PERFORM set_config('app.allow_entitlement_write', 'on', true);
  UPDATE public.users
  SET embers = embers + v_capped,
      updated_at = timezone('utc'::text, now())
  WHERE id = v_uid
  RETURNING embers INTO v_new;
  RETURN COALESCE(v_new, 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.spend_user_embers(p_cost INTEGER, p_item TEXT DEFAULT '')
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_current INTEGER;
  v_new INTEGER;
BEGIN
  IF v_uid IS NULL OR COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_cost IS NULL OR p_cost <= 0 THEN
    RAISE EXCEPTION 'Invalid spend amount';
  END IF;
  SELECT embers INTO v_current FROM public.users WHERE id = v_uid FOR UPDATE;
  IF COALESCE(v_current, 0) < p_cost THEN
    RAISE EXCEPTION 'Insufficient embers';
  END IF;
  PERFORM set_config('app.allow_entitlement_write', 'on', true);
  UPDATE public.users
  SET embers = v_current - p_cost,
      updated_at = timezone('utc'::text, now())
  WHERE id = v_uid
  RETURNING embers INTO v_new;
  RETURN v_new;
END;
$$;

-- 2. Record Swipe & Mutual Match Detection (UUID-only, no spoofable display_name)
CREATE OR REPLACE FUNCTION record_swipe_and_check_match(p_target_id TEXT, p_direction TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_target_uuid UUID;
    v_is_mutual BOOLEAN := false;
    v_match_id UUID := NULL;
    v_u1 UUID;
    v_u2 UUID;
BEGIN
    IF v_user_id IS NULL OR COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    BEGIN
        v_target_uuid := p_target_id::UUID;
    EXCEPTION WHEN others THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid target user id');
    END;

    IF v_target_uuid = v_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot swipe self');
    END IF;

    INSERT INTO swipes (user_id, profile, direction, timestamp)
    VALUES (v_user_id, v_target_uuid::text, p_direction, timezone('utc'::text, now()));

    IF p_direction IN ('right', 'superlike') THEN
        SELECT EXISTS (
            SELECT 1 FROM swipes
            WHERE user_id = v_target_uuid
              AND profile = v_user_id::text
              AND direction IN ('right', 'superlike')
        ) INTO v_is_mutual;

        IF v_is_mutual THEN
            IF v_user_id < v_target_uuid THEN
                v_u1 := v_user_id; v_u2 := v_target_uuid;
            ELSE
                v_u1 := v_target_uuid; v_u2 := v_user_id;
            END IF;

            INSERT INTO matches (user1_id, user2_id, status)
            VALUES (v_u1, v_u2, 'active')
            ON CONFLICT (user1_id, user2_id) DO NOTHING
            RETURNING id INTO v_match_id;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'is_match', v_is_mutual,
        'target_id', v_target_uuid::text,
        'match_id', v_match_id
    );
END;
$$;

-- 3. Complete Account Deletion Flow (Data + Storage + Auth)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_uid_text TEXT := auth.uid()::text;
BEGIN
    IF v_uid IS NULL THEN
        RETURN false;
    END IF;

    DELETE FROM messages WHERE user_id = v_uid OR partner_id = v_uid_text;
    DELETE FROM matches WHERE user1_id = v_uid OR user2_id = v_uid;
    DELETE FROM swipes WHERE user_id = v_uid OR profile = v_uid_text;
    DELETE FROM map_checkins WHERE user_id = v_uid;
    DELETE FROM blocks WHERE blocker_id = v_uid OR blocked_id = v_uid_text;
    DELETE FROM reports WHERE reporter_id = v_uid OR reported_id = v_uid_text;
    DELETE FROM active_quests WHERE user1_id = v_uid OR user2_id = v_uid;
    DELETE FROM stories WHERE user_id = v_uid_text;
    DELETE FROM voice_lounge_members WHERE user_id = v_uid_text;
    DELETE FROM voice_lounges WHERE host_id = v_uid_text;
    DELETE FROM call_signals WHERE caller_id = v_uid_text OR callee_id = v_uid_text;
    DELETE FROM analytics_events WHERE user_id = v_uid_text;
    DELETE FROM storage.objects
      WHERE bucket_id IN ('avatars', 'stories', 'voice-notes', 'voice_prompts')
        AND (storage.foldername(name))[1] = v_uid_text;
    DELETE FROM users WHERE id = v_uid;
    DELETE FROM auth.users WHERE id = v_uid;

    RETURN true;
END;
$$;

-- =========================================================
-- Phase 5: Storage Buckets, 24h Stories & Call Signals
-- =========================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('stories', 'stories', false),
  ('voice-notes', 'voice-notes', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Allow public update/delete on SparkQuest buckets" ON storage.objects;
DROP POLICY IF EXISTS "Users can update/delete own avatar files" ON storage.objects;

CREATE POLICY "Authenticated read SparkQuest media" ON storage.objects
  FOR SELECT USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
  );
CREATE POLICY "Users upload own SparkQuest media" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
CREATE POLICY "Users update own SparkQuest media" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
CREATE POLICY "Users delete own SparkQuest media" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('avatars', 'stories', 'voice-notes')
    AND auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE TABLE IF NOT EXISTS public.stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  avatar_url TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  caption TEXT NOT NULL,
  vibe TEXT DEFAULT '⚡ Active Quest',
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours')
);

CREATE TABLE IF NOT EXISTS public.call_signals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL,
  caller_id TEXT NOT NULL,
  caller_name TEXT NOT NULL,
  caller_avatar TEXT DEFAULT '',
  callee_id TEXT NOT NULL,
  call_type TEXT DEFAULT 'video',
  status TEXT DEFAULT 'ringing',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================================
-- Phases 7 to 12: Rich Profiles, Guilds, Telemetry & Geospatial RPC
-- =========================================================
CREATE TABLE IF NOT EXISTS public.guilds (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  member_count INT DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL DEFAULT 'user_me',
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

DROP FUNCTION IF EXISTS public.nearby_profiles(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
CREATE OR REPLACE FUNCTION public.nearby_profiles(
  user_lat DOUBLE PRECISION DEFAULT 37.7749,
  user_lng DOUBLE PRECISION DEFAULT -122.4194,
  radius_miles DOUBLE PRECISION DEFAULT 25.0
)
RETURNS TABLE (
  id UUID,
  display_name TEXT,
  age INTEGER,
  bio TEXT,
  photo_url TEXT,
  tags JSONB,
  is_verified BOOLEAN,
  lat NUMERIC,
  lng NUMERIC,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.*
  FROM public.get_public_users() u
  WHERE (
    3958.8 * acos(
      LEAST(1.0, GREATEST(-1.0,
        cos(radians(user_lat)) * cos(radians(u.lat::double precision)) *
        cos(radians(u.lng::double precision) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(u.lat::double precision))
      ))
    )
  ) <= radius_miles
  ORDER BY u.updated_at DESC
  LIMIT 50;
$$;

-- =========================================================
-- Phase 13: Voice Lounges & Production Storage RLS
-- =========================================================
CREATE TABLE IF NOT EXISTS public.voice_lounges (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    topic TEXT NOT NULL,
    vibe TEXT DEFAULT 'Indie Vibe' NOT NULL,
    host_id TEXT NOT NULL,
    host_name TEXT NOT NULL,
    max_listeners INTEGER DEFAULT 20 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.voice_lounge_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lounge_id TEXT REFERENCES public.voice_lounges(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_avatar TEXT DEFAULT '',
    is_speaking BOOLEAN DEFAULT false NOT NULL,
    is_muted BOOLEAN DEFAULT false NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT unique_lounge_participant UNIQUE (lounge_id, user_id)
);

ALTER TABLE public.voice_lounges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_lounge_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view active voice lounges" ON public.voice_lounges;
CREATE POLICY "Public can view active voice lounges" ON public.voice_lounges
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Members can view lounge attendees" ON public.voice_lounge_members;
CREATE POLICY "Members can view lounge attendees" ON public.voice_lounge_members
    FOR SELECT USING (auth.uid() IS NOT NULL AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

DROP POLICY IF EXISTS "Users can join or update lounge presence" ON public.voice_lounge_members;
CREATE POLICY "Users can join or update lounge presence" ON public.voice_lounge_members
    FOR ALL USING (auth.uid()::text = user_id AND COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

-- 11. Google Play Web Account Deletion Requests
CREATE TABLE IF NOT EXISTS public.deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    scope TEXT NOT NULL DEFAULT 'all',
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    notes TEXT
);

ALTER TABLE public.deletion_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can submit account deletion requests" ON public.deletion_requests;
CREATE POLICY "Public can submit account deletion requests" ON public.deletion_requests
    FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role manages deletion requests" ON public.deletion_requests;
CREATE POLICY "Service role manages deletion requests" ON public.deletion_requests
    FOR ALL
    USING (auth.role() = 'service_role');

-- =========================================================
-- Phase 14: WebRTC SDP/ICE Signaling, Push Tokens & Realtime
-- =========================================================
ALTER TABLE public.call_signals
  ADD COLUMN IF NOT EXISTS sdp_offer TEXT,
  ADD COLUMN IF NOT EXISTS sdp_answer TEXT,
  ADD COLUMN IF NOT EXISTS ice_candidates JSONB DEFAULT '[]'::jsonb NOT NULL;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;






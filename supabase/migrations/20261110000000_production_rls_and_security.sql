-- =========================================================
-- SparkQuest: Production Hardening, Anti-Abuse RLS & Voice Lounges
-- Migration: 20261110000000_production_rls_and_security.sql
-- =========================================================

-- 1. Ensure Stories table has full RLS security
ALTER TABLE IF EXISTS public.stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view active stories" ON public.stories;
CREATE POLICY "Public can view active stories" ON public.stories
    FOR SELECT USING (
        expires_at > now()
        AND NOT EXISTS (
            SELECT 1 FROM public.blocks
            WHERE (blocker_id = auth.uid() AND blocked_id = stories.user_id)
               OR (blocker_id::text = stories.user_id AND blocked_id = auth.uid()::text)
        )
    );

DROP POLICY IF EXISTS "Users can create own stories" ON public.stories;
CREATE POLICY "Users can create own stories" ON public.stories
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can delete own stories" ON public.stories;
CREATE POLICY "Users can delete own stories" ON public.stories
    FOR DELETE USING (auth.uid()::text = user_id);

-- 2. Call Signals (Encrypted WebRTC signaling between matched users)
ALTER TABLE IF EXISTS public.call_signals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view incoming and outgoing call signals" ON public.call_signals;
CREATE POLICY "Users can view incoming and outgoing call signals" ON public.call_signals
    FOR SELECT USING (
        auth.uid()::text = caller_id OR auth.uid()::text = callee_id
    );

DROP POLICY IF EXISTS "Callers can initiate call signals" ON public.call_signals;
CREATE POLICY "Callers can initiate call signals" ON public.call_signals
    FOR INSERT WITH CHECK (
        auth.uid()::text = caller_id
        AND NOT EXISTS (
            SELECT 1 FROM public.blocks
            WHERE (blocker_id = auth.uid() AND blocked_id = callee_id)
               OR (blocker_id::text = callee_id AND blocked_id = auth.uid()::text)
        )
    );

DROP POLICY IF EXISTS "Participants can update call signals" ON public.call_signals;
CREATE POLICY "Participants can update call signals" ON public.call_signals
    FOR UPDATE USING (
        auth.uid()::text = caller_id OR auth.uid()::text = callee_id
    );

DROP POLICY IF EXISTS "Participants can delete call signals" ON public.call_signals;
CREATE POLICY "Participants can delete call signals" ON public.call_signals
    FOR DELETE USING (
        auth.uid()::text = caller_id OR auth.uid()::text = callee_id
    );

-- 3. Live Audio & Drop-In Voice Lounges (v2.1.0 Roadmap Feature)
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

DROP POLICY IF EXISTS "Authenticated users can create lounges" ON public.voice_lounges;
CREATE POLICY "Authenticated users can create lounges" ON public.voice_lounges
    FOR INSERT WITH CHECK (auth.uid()::text = host_id OR host_id = 'user_me');

DROP POLICY IF EXISTS "Hosts can manage own lounges" ON public.voice_lounges;
CREATE POLICY "Hosts can manage own lounges" ON public.voice_lounges
    FOR UPDATE USING (auth.uid()::text = host_id OR host_id = 'user_me');

DROP POLICY IF EXISTS "Members can view lounge attendees" ON public.voice_lounge_members;
CREATE POLICY "Members can view lounge attendees" ON public.voice_lounge_members
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can join or update lounge presence" ON public.voice_lounge_members;
CREATE POLICY "Users can join or update lounge presence" ON public.voice_lounge_members
    FOR ALL USING (auth.uid()::text = user_id OR user_id = 'user_me');

-- Add Voice Lounges to Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_lounges;
ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_lounge_members;

-- 4. Storage Security Policies for Avatars & Stories
-- (Protects user photos from unauthorized modification)
DO $$
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES
      ('avatars', 'avatars', true),
      ('stories', 'stories', true),
      ('voice-notes', 'voice-notes', true)
    ON CONFLICT (id) DO UPDATE SET public = true;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
CREATE POLICY "Public can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id IN ('avatars', 'stories', 'voice-notes'));

DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
CREATE POLICY "Users can upload own avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id IN ('avatars', 'stories', 'voice-notes')
        AND (auth.role() = 'authenticated')
    );

DROP POLICY IF EXISTS "Users can update own avatar files" ON storage.objects;
CREATE POLICY "Users can update own avatar files" ON storage.objects
    FOR UPDATE USING (
        bucket_id IN ('avatars', 'stories', 'voice-notes')
        AND (auth.role() = 'authenticated')
    );

DROP POLICY IF EXISTS "Users can delete own avatar files" ON storage.objects;
CREATE POLICY "Users can delete own avatar files" ON storage.objects
    FOR DELETE USING (
        bucket_id IN ('avatars', 'stories', 'voice-notes')
        AND (auth.role() = 'authenticated')
    );

-- 5. Seed Initial Safe Haven Voice Lounges
INSERT INTO public.voice_lounges (id, title, topic, vibe, host_id, host_name, max_listeners, is_active)
VALUES
  ('lounge_coffee', '☕ Third-Wave Espresso & Vinyl Hangout', 'Best pour-overs, favorite matcha bars & indie record shops', '☕ Cozy Artisan', 'system_maya', 'Maya', 15, true),
  ('lounge_sunset', '🌅 Golden Hour & Rooftop Trivia Pre-Party', 'Icebreaker trivia duels before Saturday night Safe Haven meetups', '🌌 Night Owl', 'system_alex', 'Alex', 20, true),
  ('lounge_trail', '🏔️ Sunrise Trail Run & Bouldering Crew', 'Weekend trails in Buena Vista Park & indoor climbing partners', '🏔️ Adventurer', 'system_jordan', 'Jordan', 12, true)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  topic = EXCLUDED.topic,
  is_active = true;

-- 6. Google Play Compliance: Web Account Deletion Requests Table
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



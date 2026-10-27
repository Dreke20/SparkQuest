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
    age INTEGER DEFAULT 24,
    bio TEXT DEFAULT 'Ready for the next quest ✨',
    photo_url TEXT DEFAULT 'img/alex.png',
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

-- Users Policies
DROP POLICY IF EXISTS "Public can view discovery profiles" ON users;
CREATE POLICY "Public can view discovery profiles" ON users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

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
CREATE POLICY "Users can view all check-ins" ON map_checkins FOR SELECT USING (true);

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

-- 1. Atomic Embers Update
CREATE OR REPLACE FUNCTION increment_embers(user_id UUID, amt INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET embers = GREATEST(0, embers + amt),
      updated_at = timezone('utc'::text, now())
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Record Swipe & Mutual Match Detection
CREATE OR REPLACE FUNCTION record_swipe_and_check_match(p_target_id TEXT, p_direction TEXT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_target_uuid UUID;
    v_is_mutual BOOLEAN := false;
    v_match_id UUID := NULL;
    v_u1 UUID;
    v_u2 UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Record current swipe
    INSERT INTO swipes (user_id, profile, direction, timestamp)
    VALUES (v_user_id, p_target_id, p_direction, timezone('utc'::text, now()));

    -- If like or superlike, check if target has liked current user
    IF p_direction IN ('right', 'superlike') THEN
        BEGIN
            v_target_uuid := p_target_id::UUID;
        EXCEPTION WHEN others THEN
            -- Target is a non-UUID name (e.g. simulated bot profile like 'Sophia')
            v_target_uuid := NULL;
        END IF;

        IF v_target_uuid IS NOT NULL THEN
            SELECT EXISTS (
                SELECT 1 FROM swipes 
                WHERE user_id = v_target_uuid 
                  AND (profile = v_user_id::text OR profile = (SELECT display_name FROM users WHERE id = v_user_id))
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
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'is_match', v_is_mutual,
        'target_id', p_target_id,
        'match_id', v_match_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Account Deletion Flow (Mandatory Google Play / App Store Compliance)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS BOOLEAN AS $$
DECLARE
    v_uid UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN false;
    END IF;

    -- Delete associated records
    DELETE FROM messages WHERE user_id = v_uid OR partner_id = v_uid::text;
    DELETE FROM matches WHERE user1_id = v_uid OR user2_id = v_uid;
    DELETE FROM swipes WHERE user_id = v_uid;
    DELETE FROM map_checkins WHERE user_id = v_uid;
    DELETE FROM blocks WHERE blocker_id = v_uid;
    DELETE FROM reports WHERE reporter_id = v_uid;
    DELETE FROM active_quests WHERE user1_id = v_uid OR user2_id = v_uid;
    DELETE FROM users WHERE id = v_uid;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

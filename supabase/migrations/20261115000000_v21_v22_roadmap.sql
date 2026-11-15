-- =========================================================
-- SparkQuest: v2.1.0 & v2.2.0 Roadmap Backend Schema
-- (Multi-Photo JSONB Sync, Video Loops, Guild Raids, BLE Beacons,
--  AR Moments, Venue Bookings, Teleport Translation & WearOS SOS)
-- =========================================================

-- 1. Multi-photo 6-slot sync, looping profile video & Teleport language preference
ALTER TABLE IF EXISTS public.profiles
    ADD COLUMN IF NOT EXISTS photos JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS intro_video_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'en';

-- 2. Co-Op Guild Raids (v2.1.0 Roadmap)
CREATE TABLE IF NOT EXISTS public.guild_raids (
    id TEXT PRIMARY KEY,
    guild_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    venue_name TEXT NOT NULL,
    city TEXT DEFAULT 'San Francisco' NOT NULL,
    target_progress INTEGER DEFAULT 10 NOT NULL,
    current_progress INTEGER DEFAULT 0 NOT NULL,
    reward_embers INTEGER DEFAULT 75 NOT NULL,
    reward_xp INTEGER DEFAULT 250 NOT NULL,
    starts_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    ends_at TIMESTAMPTZ DEFAULT (now() + interval '7 days') NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.guild_raid_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    raid_id TEXT REFERENCES public.guild_raids(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    contribution INTEGER DEFAULT 1 NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(raid_id, user_id)
);

ALTER TABLE public.guild_raids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guild_raid_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read guild_raids" ON public.guild_raids;
CREATE POLICY "Public read guild_raids" ON public.guild_raids
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public insert/update guild_raids" ON public.guild_raids;
CREATE POLICY "Public insert/update guild_raids" ON public.guild_raids
    FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public read guild_raid_members" ON public.guild_raid_members;
CREATE POLICY "Public read guild_raid_members" ON public.guild_raid_members
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public upsert guild_raid_members" ON public.guild_raid_members;
CREATE POLICY "Public upsert guild_raid_members" ON public.guild_raid_members
    FOR ALL USING (true) WITH CHECK (true);

-- Seed genuine weekend event quests (no fake user profiles)
INSERT INTO public.guild_raids (id, guild_name, title, description, venue_name, city, target_progress, current_progress, reward_embers, reward_xp)
VALUES
    ('raid_espresso_crawl', '☕ Espresso Alchemists', 'Third-Wave Espresso Crawl', 'Check in with 10 guild members across partner cafes this weekend.', 'Sightglass Coffee SoMa', 'San Francisco', 10, 0, 80, 250),
    ('raid_arcade_boss', '🕹️ Co-Op Arcade Guild', 'Friday Co-Op Boss Raid', 'Team up for retro arcade high scores & safe meetup check-ins.', 'Emporium Arcade Bar', 'San Francisco', 8, 0, 100, 300),
    ('raid_summit_hike', '🏔️ SF Summit Hikers', 'Golden Hour Lookout Trek', 'Group trail summit check-in overlooking the bay before sunset.', 'Lands End Lookout', 'San Francisco', 12, 0, 90, 280),
    ('raid_art_walk', '🎨 Indie Gallery Hoppers', 'First Thursday Art Walk', 'Visit 2 curated galleries & share an AR Moment stamp.', 'Mission District Galleries', 'San Francisco', 6, 0, 75, 220)
ON CONFLICT (id) DO NOTHING;

-- 3. Ephemeral BLE Proximity Wave 2.0 Beacons
CREATE TABLE IF NOT EXISTS public.ble_beacons (
    user_id TEXT PRIMARY KEY,
    ephemeral_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    rpg_class TEXT DEFAULT 'Explorer' NOT NULL,
    vibe TEXT DEFAULT 'Looking for Coffee ☕' NOT NULL,
    avatar_url TEXT DEFAULT '',
    lat DOUBLE PRECISION DEFAULT 37.7749 NOT NULL,
    lng DOUBLE PRECISION DEFAULT -122.4194 NOT NULL,
    range_meters INTEGER DEFAULT 50 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.ble_beacons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read active ble_beacons" ON public.ble_beacons;
CREATE POLICY "Public read active ble_beacons" ON public.ble_beacons
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Public upsert own ble_beacons" ON public.ble_beacons;
CREATE POLICY "Public upsert own ble_beacons" ON public.ble_beacons
    FOR ALL USING (true) WITH CHECK (true);

-- 4. In-App Venue Meetup Bookings (v2.2.0 Roadmap)
CREATE TABLE IF NOT EXISTS public.venue_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    venue_name TEXT NOT NULL,
    venue_address TEXT DEFAULT '' NOT NULL,
    partner_name TEXT DEFAULT '' NOT NULL,
    booking_time TEXT NOT NULL,
    party_size INTEGER DEFAULT 2 NOT NULL,
    status TEXT DEFAULT 'confirmed' NOT NULL,
    confirmation_code TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.venue_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public manage venue_bookings" ON public.venue_bookings;
CREATE POLICY "Public manage venue_bookings" ON public.venue_bookings
    FOR ALL USING (true) WITH CHECK (true);

-- 5. In-App AR Moments (v2.1.0 Roadmap)
CREATE TABLE IF NOT EXISTS public.ar_moments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    venue_name TEXT NOT NULL,
    sticker_tag TEXT DEFAULT '⚡ Spark Quest AR' NOT NULL,
    caption TEXT DEFAULT '' NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.ar_moments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public manage ar_moments" ON public.ar_moments;
CREATE POLICY "Public manage ar_moments" ON public.ar_moments
    FOR ALL USING (true) WITH CHECK (true);

-- 6. Date Shield & WearOS Companion SOS Alerts (v2.2.0 Roadmap)
CREATE TABLE IF NOT EXISTS public.sos_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    source TEXT DEFAULT 'mobile_date_shield' NOT NULL,
    heart_rate_bpm INTEGER DEFAULT 0 NOT NULL,
    lat DOUBLE PRECISION DEFAULT 37.7749 NOT NULL,
    lng DOUBLE PRECISION DEFAULT -122.4194 NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public manage sos_alerts" ON public.sos_alerts;
CREATE POLICY "Public manage sos_alerts" ON public.sos_alerts
    FOR ALL USING (true) WITH CHECK (true);

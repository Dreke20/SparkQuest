-- =============================================================================
-- SPARKQUEST PHASE 7 TO 12: RICH PROFILES, GUILDS, GEOSPATIAL RPC & TELEMETRY
-- =============================================================================

-- 1. Rich Profile Columns on public.profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS prompts JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS relationship_intent TEXT DEFAULT '🛡️ Long-Term Co-Op Partner',
  ADD COLUMN IF NOT EXISTS pronouns TEXT DEFAULT 'they/them',
  ADD COLUMN IF NOT EXISTS vitals JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS anthem_title TEXT DEFAULT 'Midnight City',
  ADD COLUMN IF NOT EXISTS anthem_artist TEXT DEFAULT 'M83',
  ADD COLUMN IF NOT EXISTS is_free_tonight BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_standout BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION DEFAULT 37.7749,
  ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION DEFAULT -122.4194;

-- 2. Adventurer Interest Guilds (#42)
CREATE TABLE IF NOT EXISTS public.guilds (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  member_count INT DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.guilds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read guilds" ON public.guilds;
CREATE POLICY "Public read guilds" ON public.guilds FOR SELECT USING (true);

INSERT INTO public.guilds (id, name, description, member_count)
VALUES
  ('sf_hikers', '🏔️ SF Summit Hikers', 'Weekend Trail & Lands End Sunset Quests', 412),
  ('coop_arcade', '🕹️ Co-Op Arcade Guild', 'Friday Night Emporium Boss Battles', 628),
  ('espresso_alchemists', '☕ Espresso Alchemists', 'Third-Wave Cafe & Matcha Crawls', 519),
  ('indie_gallery', '🎨 Indie Gallery Hoppers', 'First Thursday Art Walks & Vinyl Nights', 284)
ON CONFLICT (id) DO NOTHING;

-- 3. Product Analytics & Funnel Telemetry (#50)
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL DEFAULT 'user_me',
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public insert analytics" ON public.analytics_events;
CREATE POLICY "Public insert analytics" ON public.analytics_events FOR INSERT WITH CHECK (true);

-- 4. Geospatial Proximity Discovery RPC (#48)
CREATE OR REPLACE FUNCTION public.nearby_profiles(
  user_lat DOUBLE PRECISION DEFAULT 37.7749,
  user_lng DOUBLE PRECISION DEFAULT -122.4194,
  radius_miles DOUBLE PRECISION DEFAULT 25.0
)
RETURNS SETOF public.profiles
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.profiles
  WHERE (
    3958.8 * acos(
      LEAST(1.0, GREATEST(-1.0,
        cos(radians(user_lat)) * cos(radians(COALESCE(lat, 37.7749))) *
        cos(radians(COALESCE(lng, -122.4194)) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(COALESCE(lat, 37.7749)))
      ))
    )
  ) <= radius_miles
  ORDER BY updated_at DESC
  LIMIT 50;
$$;


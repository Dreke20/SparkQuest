-- SparkQuest Supabase Schema

-- 1. Create the Users table
CREATE TABLE users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    embers INTEGER DEFAULT 325 NOT NULL,
    is_premium BOOLEAN DEFAULT false NOT NULL,
    inventory JSONB DEFAULT '{"boost": 2, "superlike": 5}'::jsonb NOT NULL,
    quest_progress JSONB DEFAULT '{"engage1": {"current": 7, "target": 10, "claimed": false}, "engage2": {"current": 1, "target": 3, "claimed": false}, "engage3": {"current": 1, "target": 1, "claimed": true}}'::jsonb NOT NULL
);

-- 2. Create the Messages table
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    partner_id TEXT NOT NULL, -- Stored as text to support bot IDs like 'maya', 'alex'
    text TEXT,
    type TEXT, -- e.g., 'sent' or 'received'
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create the Swipes table
CREATE TABLE swipes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    profile TEXT NOT NULL,
    direction TEXT NOT NULL, -- 'left', 'right', 'superlike'
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Set up Row Level Security (RLS)

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;

-- Users Policy: Users can only view and update their own profile
CREATE POLICY "Users can view own profile" 
    ON users FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON users FOR INSERT 
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON users FOR UPDATE 
    USING (auth.uid() = id);

-- Messages Policy: Users can only view and insert their own messages
CREATE POLICY "Users can view own messages" 
    ON messages FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own messages" 
    ON messages FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Swipes Policy: Users can only view and insert their own swipes
CREATE POLICY "Users can view own swipes" 
    ON swipes FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own swipes" 
    ON swipes FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- 5. Create Realtime Publications
-- Enable realtime updates for users and messages
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 6. Neon Night / Map Check-ins
CREATE TABLE map_checkins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    venue_id TEXT NOT NULL,
    lat NUMERIC,
    lng NUMERIC,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE map_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all check-ins (for heatmaps)" ON map_checkins FOR SELECT USING (true);
CREATE POLICY "Users can insert own check-ins" ON map_checkins FOR INSERT WITH CHECK (auth.uid() = user_id);
ALTER PUBLICATION supabase_realtime ADD TABLE map_checkins;

-- 7. Multiplayer Icebreaker Quests
CREATE TABLE active_quests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    quest_type TEXT NOT NULL,
    user1_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    user2_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    user1_ready BOOLEAN DEFAULT false,
    user2_ready BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending' -- 'pending', 'completed'
);

ALTER TABLE active_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their quests" ON active_quests FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can insert quests" ON active_quests FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can update their quests" ON active_quests FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);
ALTER PUBLICATION supabase_realtime ADD TABLE active_quests;

-- 8. Storage Bucket for Voice Prompts
INSERT INTO storage.buckets (id, name, public) 
VALUES ('voice_prompts', 'voice_prompts', true) 
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
CREATE POLICY "Voice prompts are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'voice_prompts');

CREATE POLICY "Users can upload their own voice prompts" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'voice_prompts' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

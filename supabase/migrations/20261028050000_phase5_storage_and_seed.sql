-- SparkQuest Phase 5 Cloud Migration: Storage Buckets, Stories, Call Signals & Live Cloud Seed Data
-- Project Ref: kqvjntbiagzywstijtsz

-- ==========================================
-- 1. SUPABASE STORAGE BUCKETS & POLICIES
-- ==========================================
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('stories', 'stories', true),
  ('voice-notes', 'voice-notes', true)
on conflict (id) do update set public = true;

drop policy if exists "Allow public read on SparkQuest buckets" on storage.objects;
create policy "Allow public read on SparkQuest buckets"
  on storage.objects for select
  using (bucket_id in ('avatars', 'stories', 'voice-notes'));

drop policy if exists "Allow public upload on SparkQuest buckets" on storage.objects;
create policy "Allow public upload on SparkQuest buckets"
  on storage.objects for insert
  with check (bucket_id in ('avatars', 'stories', 'voice-notes'));

drop policy if exists "Allow public update on SparkQuest buckets" on storage.objects;
create policy "Allow public update on SparkQuest buckets"
  on storage.objects for update
  using (bucket_id in ('avatars', 'stories', 'voice-notes'));

drop policy if exists "Allow public delete on SparkQuest buckets" on storage.objects;
create policy "Allow public delete on SparkQuest buckets"
  on storage.objects for delete
  using (bucket_id in ('avatars', 'stories', 'voice-notes'));

-- ==========================================
-- 2. STORIES & LIVE CALL SIGNALING TABLES
-- ==========================================
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  user_name text not null,
  avatar_url text default '',
  image_url text default '',
  caption text not null,
  vibe text default '⚡ Active Quest',
  created_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '24 hours')
);

create table if not exists public.call_signals (
  id uuid primary key default gen_random_uuid(),
  room_id text not null,
  caller_id text not null,
  caller_name text not null,
  caller_avatar text default '',
  callee_id text not null,
  call_type text default 'video', -- 'video' | 'voice'
  status text default 'ringing',  -- 'ringing' | 'accepted' | 'declined' | 'ended'
  created_at timestamptz default now()
);

alter table public.stories enable row level security;
alter table public.call_signals enable row level security;

drop policy if exists "Allow public access on stories" on public.stories;
create policy "Allow public access on stories" on public.stories for all using (true);

drop policy if exists "Allow public access on call_signals" on public.call_signals;
create policy "Allow public access on call_signals" on public.call_signals for all using (true);

-- ==========================================
-- 3. SEED LIVE STARTER PROFILES, STORIES & HOTSPOT CHECK-INS
-- ==========================================
insert into public.profiles (
  user_id, name, age, bio, avatar_url, city, tags, embers, level, xp, is_vip, is_verified, selected_frame, voice_prompt_title
)
values
  (
    'user_maya',
    'Maya Lin',
    25,
    'Architect by day, indie synth player by night. Let''s grab a matcha latte and rate SF''s best rooftop views.',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
    'San Francisco, CA',
    array['Architecture', 'Synthwave', 'Matcha', 'Vinyl'],
    420,
    5,
    780,
    true,
    true,
    'cyberpunk',
    'My Controversial Opinion: Pour-over coffee is overrated...'
  ),
  (
    'user_liam',
    'Liam Vance',
    27,
    'Trail runner & sourdough tinkerer. Looking for a co-op partner for weekend Marin Headlands hikes and street tacos.',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80',
    'San Francisco, CA',
    array['Trail Running', 'Sourdough', 'Bouldering', 'Tacos'],
    310,
    4,
    520,
    false,
    true,
    'phoenix',
    'Two truths & a lie: I''ve climbed Half Dome twice...'
  ),
  (
    'user_chloe',
    'Chloe Sterling',
    24,
    'UX designer obsessed with pottery, 90s arcade cabinets, and late-night ramen spots. Beat my Street Fighter score!',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80',
    'Oakland, CA',
    array['Pottery', 'Arcade', 'Ramen', 'Design'],
    590,
    7,
    1250,
    true,
    true,
    'galactic',
    'My ideal Sunday: Ceramic studio + Mission district walk'
  ),
  (
    'user_zoe',
    'Zoe Reyes',
    26,
    'Astrophotographer & botanical collector. Always down for golden hour at Dolores Park or trivia night.',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80',
    'San Francisco, CA',
    array['Photography', 'Plants', 'Trivia', 'Camping'],
    275,
    3,
    390,
    false,
    true,
    'cyberpunk',
    'Best travel story: Chasing the northern lights in Tromsø'
  ),
  (
    'user_kael',
    'Kaelen Mercer',
    28,
    'Robotics engineer building autonomous drones. Espresso snob, sci-fi reader, and sunset kayaker.',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80',
    'San Francisco, CA',
    array['Robotics', 'Espresso', 'Kayaking', 'Sci-Fi'],
    480,
    6,
    980,
    true,
    true,
    'phoenix',
    'Geekiest obsession: Custom mechanical keyboards'
  ),
  (
    'user_me',
    'Alex Explorer',
    26,
    'Exploring the city one Spark Quest at a time. Down for rooftop coffee, retro arcades, and spontaneous road trips.',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800&auto=format&fit=crop&q=80',
    'San Francisco, CA',
    array['Coffee', 'Hiking', 'Synthwave', 'Bouldering'],
    350,
    4,
    550,
    true,
    true,
    'cyberpunk',
    'My ideal first date: Neon Roasters + Co-Op Trivia!'
  )
on conflict (user_id) do update set
  name = excluded.name,
  bio = excluded.bio,
  avatar_url = excluded.avatar_url,
  tags = excluded.tags,
  is_verified = excluded.is_verified;

-- Seed 24h Stories (idempotent cleanup + insert)
delete from public.stories where user_id in ('user_maya', 'user_liam', 'user_chloe', 'user_zoe');
insert into public.stories (user_id, user_name, avatar_url, image_url, caption, vibe)
values
  (
    'user_maya',
    'Maya',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=900&auto=format&fit=crop&q=80',
    'Pour-over flight at Neon Roasters ☕✨ Who''s nearby for a quick trivia duel?',
    '☕ Coffee Quest'
  ),
  (
    'user_liam',
    'Liam',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=900&auto=format&fit=crop&q=80',
    'Crushing V5 routes at Dogpatch Boulders 🧗‍♂️ Need a belay partner!',
    '🧗‍♂️ Active Adventure'
  ),
  (
    'user_chloe',
    'Chloe',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=900&auto=format&fit=crop&q=80',
    'New high score on Galaga at Emporium Arcade 👾 Come challenge me!',
    '🕹️ Night Owl'
  ),
  (
    'user_zoe',
    'Zoe',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900&auto=format&fit=crop&q=80',
    'Golden hour over the bay 🌅 Best sunset in months.',
    '📸 Golden Hour'
  );

-- Seed Map Hotspot Check-ins
delete from public.map_checkins where user_id in ('user_maya', 'user_liam', 'user_chloe', 'user_zoe');
insert into public.map_checkins (user_id, venue_id, lat, lng)
values
  ('user_maya', 'neon_roasters', 37.7765, -122.4172),
  ('user_liam', 'boulder_den', 37.7598, -122.3886),
  ('user_chloe', 'arcade_bar', 37.7721, -122.4312),
  ('user_zoe', 'dolores_sunset', 37.7596, -122.4269);


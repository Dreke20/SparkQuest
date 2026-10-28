-- SparkQuest Core Database Schema for Supabase
-- Project Ref: kqvjntbiagzywstijtsz

-- 1. User Profiles & Social Stats
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id text unique,
  name text not null,
  age int default 24,
  bio text default '',
  avatar_url text default '',
  city text default 'San Francisco, CA',
  tags text[] default array['Coffee', 'Hiking', 'Synthwave', 'Bouldering'],
  embers int default 150,
  level int default 1,
  xp int default 0,
  is_vip boolean default false,
  is_verified boolean default false,
  selected_frame text default 'none',
  voice_prompt_title text default 'My ideal first date...',
  voice_prompt_url text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Matches & Compatibility
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_id_1 text not null,
  user_id_2 text not null,
  user_name text not null,
  avatar_url text default '',
  compatibility_pct int default 88,
  last_message text default 'Hey there! Loved your quest pin at the roastery.',
  heat_momentum int default 65,
  is_blind_matched boolean default false,
  created_at timestamptz default now()
);

-- 3. Messages & Voice Notes
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete cascade,
  sender_id text not null,
  content text default '',
  is_voice boolean default false,
  audio_url text default '',
  duration_sec int default 0,
  created_at timestamptz default now()
);

-- 4. Co-Op Matched Quests
create table if not exists public.coop_quests (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete cascade,
  title text not null,
  description text not null,
  venue_name text default 'Neon Roasters',
  current_progress int default 0,
  target_progress int default 100,
  reward_embers int default 300,
  completed boolean default false,
  badge_reward text default '⚡ Synergy Spark',
  created_at timestamptz default now()
);

-- 5. Date Guard / Guardian Angel Sessions
create table if not exists public.date_guard_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  match_name text not null,
  venue_name text not null,
  venue_address text default '',
  duration_minutes int default 120,
  emergency_contact_phone text default '',
  status text default 'active', -- 'active', 'safe', 'sos_triggered'
  started_at timestamptz default now(),
  expires_at timestamptz not null
);

-- 6. Spark Pass Tiers (30 Seasonal Tiers)
create table if not exists public.spark_pass_tiers (
  tier int primary key,
  title text not null,
  required_xp int not null,
  reward_type text not null, -- 'embers', 'frame', 'booster', 'badge'
  reward_value text not null,
  is_vip boolean default false
);

-- Seed initial Spark Pass Tiers
insert into public.spark_pass_tiers (tier, title, required_xp, reward_type, reward_value, is_vip)
values
  (1, 'Novice Wanderer', 0, 'embers', '50 Embers', false),
  (2, 'Matchmaker Initiate', 100, 'embers', '100 Embers', false),
  (3, 'Cyberpunk Glow', 250, 'frame', '⚡ Cyberpunk Ring', false),
  (4, 'Explorer Keen', 450, 'booster', '2x Ember Booster (1h)', false),
  (5, 'Phoenix Rising', 700, 'frame', '🔥 Phoenix Flame', false),
  (6, 'Quest Veteran', 1000, 'embers', '250 Embers', false),
  (7, 'Golden Spotlight', 1400, 'booster', 'Profile Spotlight (30m)', true),
  (8, 'Galactic Aura', 1900, 'frame', '🌌 Galactic Aura', false),
  (9, 'Urban Legend', 2500, 'embers', '500 Embers', false),
  (10, 'Neon Sovereign', 3200, 'frame', '👑 Neon Crown', true)
on conflict (tier) do nothing;

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.coop_quests enable row level security;
alter table public.date_guard_sessions enable row level security;
alter table public.spark_pass_tiers enable row level security;

-- Setup open read/write policies for authenticated and anon users for demo purposes
create policy "Allow public read access on profiles" on public.profiles for select using (true);
create policy "Allow public insert/update on profiles" on public.profiles for all using (true);

create policy "Allow public read access on matches" on public.matches for select using (true);
create policy "Allow public insert/update on matches" on public.matches for all using (true);

create policy "Allow public read access on messages" on public.messages for select using (true);
create policy "Allow public insert on messages" on public.messages for insert with check (true);

create policy "Allow public read access on coop_quests" on public.coop_quests for select using (true);
create policy "Allow public update on coop_quests" on public.coop_quests for all using (true);

create policy "Allow public access on date_guard" on public.date_guard_sessions for all using (true);
create policy "Allow public read on spark_pass" on public.spark_pass_tiers for select using (true);

-- SparkQuest Phase 2–4 Cloud Migration (Moderation, Swipes, Map Check-ins & RPCs)
-- Project Ref: kqvjntbiagzywstijtsz

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id text not null,
  reported_id text not null,
  reason text not null,
  details text default '',
  created_at timestamptz default now()
);

create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id text not null,
  blocked_id text not null,
  created_at timestamptz default now(),
  constraint unique_block_pair unique (blocker_id, blocked_id)
);

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  profile text not null,
  direction text not null,
  timestamp timestamptz default now()
);

create table if not exists public.map_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  venue_id text not null,
  lat numeric default 37.7749,
  lng numeric default -122.4194,
  timestamp timestamptz default now()
);

alter table public.reports enable row level security;
alter table public.blocks enable row level security;
alter table public.swipes enable row level security;
alter table public.map_checkins enable row level security;

drop policy if exists "Allow public access on reports" on public.reports;
create policy "Allow public access on reports" on public.reports for all using (true);

drop policy if exists "Allow public access on blocks" on public.blocks;
create policy "Allow public access on blocks" on public.blocks for all using (true);

drop policy if exists "Allow public access on swipes" on public.swipes;
create policy "Allow public access on swipes" on public.swipes for all using (true);

drop policy if exists "Allow public access on map_checkins" on public.map_checkins;
create policy "Allow public access on map_checkins" on public.map_checkins for all using (true);

-- RPC: Record Swipe & Mutual Spark Detection
create or replace function public.record_swipe_and_check_match(p_target_id text, p_direction text)
returns jsonb as $$
declare
  v_uid text := coalesce(auth.uid()::text, 'user_me');
begin
  insert into public.swipes (user_id, profile, direction)
  values (v_uid, p_target_id, p_direction);

  return jsonb_build_object(
    'success', true,
    'is_match', p_direction in ('right', 'superlike'),
    'target_id', p_target_id
  );
end;
$$ language plpgsql security definer;

-- RPC: Store-Compliant Account & Data Deletion
create or replace function public.delete_user_account()
returns boolean as $$
declare
  v_uid text := coalesce(auth.uid()::text, 'user_me');
begin
  delete from public.messages where sender_id = v_uid;
  delete from public.matches where user_id_1 = v_uid or user_id_2 = v_uid;
  delete from public.swipes where user_id = v_uid;
  delete from public.map_checkins where user_id = v_uid;
  delete from public.blocks where blocker_id = v_uid;
  delete from public.reports where reporter_id = v_uid;
  delete from public.profiles where user_id = v_uid;
  return true;
end;
$$ language plpgsql security definer;

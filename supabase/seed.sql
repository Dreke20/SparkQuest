-- SparkQuest Seed Data
-- Insert mock profiles
insert into public.profiles (user_id, name, age, bio, avatar_url, city, tags, embers, level, xp, is_vip, is_verified, selected_frame, voice_prompt_title, voice_prompt_url)
values
  ('user_me', 'Alex Mercer', 25, 'Urban explorer, pour-over enthusiast, and synthwave producer. Looking for quest partners.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80', 'San Francisco, CA', array['Coffee', 'Bouldering', 'Synthwave', 'Sci-Fi'], 350, 4, 450, true, true, 'cyber', 'My ideal first date...', 'https://actions.google.com/sounds/v1/water/rain_heavy.ogg'),
  ('user_elena', 'Elena Rostova', 24, 'Architectural photographer hunting hidden neon courtyards & vinyl shops.', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80', 'Mission District, SF', array['Photography', 'Vinyl', 'Espresso', 'Night Owl'], 220, 3, 310, false, true, 'flame', 'A secret superpower I wish I had...', ''),
  ('user_maya', 'Maya Lin', 26, 'Botanist by day, ambient DJ by twilight. Let''s find the secret rooftop garden.', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80', 'SoMa, SF', array['Plants', 'Ambient Music', 'Tea', 'Art Galleries'], 180, 2, 190, false, false, 'gold', 'The song that always changes my mood...', ''),
  ('user_leo', 'Leo Vance', 27, 'Tech founder turned ceramicist. Looking for someone to explore sourdough bakeries with.', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80', 'Hayes Valley, SF', array['Ceramics', 'Bakeries', 'Cycling', 'Indie Games'], 400, 5, 820, true, true, 'none', 'My most controversial pizza topping opinion...', '')
on conflict (user_id) do update set
  name = excluded.name,
  is_verified = excluded.is_verified,
  is_vip = excluded.is_vip;

-- Insert sample matches
insert into public.matches (id, user_id_1, user_id_2, user_name, avatar_url, compatibility_pct, last_message, heat_momentum)
values
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'user_me', 'user_elena', 'Elena Rostova', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80', 88, 'Loved your quest pin at the roastery! Have you tried their cold brew?', 88),
  ('b7c02b29-e85c-443b-8531-9fca2fce1202', 'user_me', 'user_maya', 'Maya Lin', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80', 94, 'Are you going to the ambient greenhouse set this Saturday?', 62)
on conflict (id) do nothing;

-- Insert sample messages
insert into public.messages (match_id, sender_id, content, is_voice, duration_sec)
values
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'user_elena', 'Hey! I saw you checked in at Neon Roasters yesterday.', false, 0),
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'user_me', 'Yes! The nitro tap was incredible. Did you solve their secret puzzle?', false, 0),
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'user_elena', 'I did! It unlocked the hidden courtyard seating. We should go together next time!', false, 0),
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'user_elena', 'Voice note (0:09): "Honestly the espresso tonic there changed my life haha"', true, 9)
on conflict do nothing;

-- Insert sample Co-Op Quest
insert into public.coop_quests (match_id, title, description, venue_name, current_progress, target_progress, reward_embers, badge_reward)
values
  ('b7c02b29-e85c-443b-8531-9fca2fce1201', 'Neon Espresso Expedition', 'Both visit Neon Roasters and order the secret quest drink within 48 hours.', 'Neon Roasters', 50, 100, 300, '☕ Double Shot Duo')
on conflict do nothing;

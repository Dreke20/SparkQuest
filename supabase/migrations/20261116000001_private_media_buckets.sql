-- Lock down private media buckets and require authenticated non-anonymous reads on lounge presence

DROP POLICY IF EXISTS "Members can view lounge attendees" ON public.voice_lounge_members;
CREATE POLICY "Authenticated view lounge attendees" ON public.voice_lounge_members
  FOR SELECT USING (public.is_authenticated_non_anon());

UPDATE storage.buckets
SET public = false
WHERE id IN ('stories', 'voice-notes');

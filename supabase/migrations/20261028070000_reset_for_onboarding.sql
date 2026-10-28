-- =============================================================================
-- SPARKQUEST: RESET USER DATABASE STATE FOR FRESH ONBOARDING TESTING
-- Project Ref: kqvjntbiagzywstijtsz
-- =============================================================================

-- 1. Clear all user interactions, swipes, matches, chat messages, reports, blocks & telemetry
TRUNCATE TABLE
  public.messages,
  public.coop_quests,
  public.matches,
  public.swipes,
  public.reports,
  public.blocks,
  public.date_guard_sessions,
  public.call_signals,
  public.analytics_events
RESTART IDENTITY CASCADE;

-- 2. Remove current test user profile ('user_me') while keeping starter discovery profiles
DELETE FROM public.profiles WHERE user_id = 'user_me';

-- 3. Reusable RPC for one-click onboarding/database reset from client or studio
CREATE OR REPLACE FUNCTION public.reset_onboarding_state()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  TRUNCATE TABLE
    public.messages,
    public.coop_quests,
    public.matches,
    public.swipes,
    public.reports,
    public.blocks,
    public.date_guard_sessions,
    public.call_signals,
    public.analytics_events
  RESTART IDENTITY CASCADE;

  DELETE FROM public.profiles WHERE user_id = 'user_me';
  RETURN true;
END;
$$;


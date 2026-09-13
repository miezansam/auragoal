-- ============================================================
-- Active Supabase Realtime sur les tables qui en ont besoin
-- (utilisées via .stream() côté Flutter).
-- ============================================================

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.goals;
alter publication supabase_realtime add table public.goal_steps;
alter publication supabase_realtime add table public.habits;
alter publication supabase_realtime add table public.habit_completions;
alter publication supabase_realtime add table public.journal_entries;
alter publication supabase_realtime add table public.focus_sessions;
alter publication supabase_realtime add table public.aura_conversations;
alter publication supabase_realtime add table public.aura_actions;

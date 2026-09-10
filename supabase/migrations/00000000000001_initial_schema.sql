-- ============================================================
-- AURAGOAL — Schéma initial
-- Basé sur le cahier des charges §18 (Modèle de données principal)
-- Row Level Security activé partout : un utilisateur ne peut
-- jamais lire/modifier les données d'un autre utilisateur.
-- ============================================================

-- ------------------------------------------------------------
-- Extension utile pour générer des UUID
-- ------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. PROFILES (étend auth.users géré par Supabase Auth)
-- ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  main_goal text,                         -- objectif principal (onboarding)
  interests text[] default '{}',          -- catégories d'intérêt
  available_time_per_day int,             -- minutes, renseigné à l'onboarding
  coaching_style text default 'balanced', -- style de coaching préféré
  level int not null default 1,
  xp int not null default 0,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  onboarding_completed boolean not null default false,
  journal_consent_for_aura boolean not null default false, -- consentement explicite §2/§6
  locale text default 'fr',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Un utilisateur voit et modifie uniquement son propre profil"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Crée automatiquement un profil à l'inscription
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- 2. GOALS (objectifs)
-- ------------------------------------------------------------
create type goal_status as enum ('active', 'completed', 'overdue', 'archived');
create type goal_priority as enum ('low', 'medium', 'high');

create table public.goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  category text,
  priority goal_priority not null default 'medium',
  status goal_status not null default 'active',
  due_date date,
  progress numeric(5,2) not null default 0, -- 0 à 100
  parent_goal_id uuid references public.goals(id) on delete cascade, -- pour sous-objectifs
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.goals enable row level security;

create policy "Un utilisateur gère uniquement ses propres objectifs"
  on public.goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 3. GOAL_STEPS (sous-objectifs, étapes, tâches)
-- ------------------------------------------------------------
create table public.goal_steps (
  id uuid primary key default uuid_generate_v4(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  is_completed boolean not null default false,
  order_index int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.goal_steps enable row level security;

create policy "Un utilisateur gère uniquement ses propres étapes"
  on public.goal_steps for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 4. HABITS (habitudes)
-- ------------------------------------------------------------
create type habit_frequency as enum ('daily', 'specific_days', 'weekly');

create table public.habits (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  goal_id uuid references public.goals(id) on delete set null,
  title text not null,
  frequency habit_frequency not null default 'daily',
  days_of_week int[] default '{}',  -- 0=dimanche ... 6=samedi, si specific_days
  current_streak int not null default 0,
  longest_streak int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.habits enable row level security;

create policy "Un utilisateur gère uniquement ses propres habitudes"
  on public.habits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 5. HABIT_COMPLETIONS (historique des check-ins)
-- ------------------------------------------------------------
create table public.habit_completions (
  id uuid primary key default uuid_generate_v4(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  completed_at date not null default current_date,
  created_at timestamptz not null default now(),
  unique (habit_id, completed_at) -- empêche un double check-in le même jour
);

alter table public.habit_completions enable row level security;

create policy "Un utilisateur gère uniquement ses propres check-ins"
  on public.habit_completions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 6. JOURNAL_ENTRIES (journal privé)
-- ------------------------------------------------------------
create table public.journal_entries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  mood text, -- optionnel
  entry_date date not null default current_date,
  created_at timestamptz not null default now()
);

alter table public.journal_entries enable row level security;

create policy "Le journal est strictement privé à son auteur"
  on public.journal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 7. FOCUS_SESSIONS (AURA Focus)
-- ------------------------------------------------------------
create table public.focus_sessions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  goal_id uuid references public.goals(id) on delete set null,
  title text,
  planned_duration_minutes int not null,
  actual_duration_minutes int,
  status text not null default 'planned', -- planned, in_progress, completed, cancelled
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.focus_sessions enable row level security;

create policy "Un utilisateur gère uniquement ses propres sessions Focus"
  on public.focus_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 8. AURA_CONVERSATIONS (contexte des échanges avec AURA)
-- ------------------------------------------------------------
create table public.aura_conversations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'aura')),
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.aura_conversations enable row level security;

create policy "Un utilisateur voit uniquement ses propres conversations AURA"
  on public.aura_conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 9. AURA_ACTIONS (propositions, confirmations, exécutions)
-- Flux obligatoire : AURA PROPOSE -> UTILISATEUR CONFIRME
--                    -> BACKEND VALIDE -> ACTION EXÉCUTÉE
-- ------------------------------------------------------------
create type aura_action_status as enum ('proposed', 'confirmed', 'executed', 'rejected', 'failed');

create table public.aura_actions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  action_type text not null, -- CREATE_GOAL, UPDATE_GOAL, CREATE_HABIT, etc.
  payload jsonb not null,     -- détails de l'action proposée
  reason text,                -- pourquoi AURA propose ceci
  status aura_action_status not null default 'proposed',
  error_message text,         -- si failed
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.aura_actions enable row level security;

create policy "Un utilisateur voit et confirme uniquement ses propres actions AURA"
  on public.aura_actions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 10. XP_EVENTS (ledger XP — traçabilité, anti-fraude)
-- ------------------------------------------------------------
create table public.xp_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount int not null,
  source_type text not null, -- 'habit_completion', 'goal_milestone', 'focus_session', ...
  source_id uuid,             -- id de l'élément source (habitude, objectif...)
  created_at timestamptz not null default now(),
  unique (source_type, source_id) -- empêche un double crédit pour le même événement
);

alter table public.xp_events enable row level security;

create policy "Un utilisateur voit uniquement son propre historique XP"
  on public.xp_events for select
  using (auth.uid() = user_id);

-- Note : l'insertion dans xp_events doit se faire via une fonction
-- serveur (service role), jamais directement par le client, pour
-- éviter qu'un utilisateur ne s'auto-crédite du XP.

-- ------------------------------------------------------------
-- 11. CHALLENGES
-- ------------------------------------------------------------
create table public.challenges (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  type text not null default 'individual', -- individual, collective
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.challenges enable row level security;

create policy "Les challenges sont visibles par tous les utilisateurs connectés"
  on public.challenges for select
  using (auth.role() = 'authenticated');

create table public.challenge_participants (
  id uuid primary key default uuid_generate_v4(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  progress numeric(5,2) not null default 0,
  joined_at timestamptz not null default now(),
  unique (challenge_id, user_id)
);

alter table public.challenge_participants enable row level security;

create policy "Un utilisateur gère uniquement sa propre participation"
  on public.challenge_participants for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 12. SUBSCRIPTIONS (abonnement — synchronisé depuis RevenueCat)
-- ------------------------------------------------------------
create type subscription_status as enum ('free', 'trial', 'active', 'expired', 'cancelled');

create table public.subscriptions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  status subscription_status not null default 'free',
  plan text,                    -- ex: 'premium_monthly', 'premium_annual'
  platform text,                -- 'ios' ou 'android'
  revenuecat_customer_id text,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy "Un utilisateur voit uniquement son propre abonnement"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- Note : les écritures sur subscriptions se font via un webhook
-- serveur (RevenueCat -> backend -> Supabase avec service role),
-- jamais directement par le client.

-- ------------------------------------------------------------
-- Index utiles pour les requêtes fréquentes
-- ------------------------------------------------------------
create index idx_goals_user_status on public.goals (user_id, status);
create index idx_habits_user_active on public.habits (user_id, is_active);
create index idx_habit_completions_habit on public.habit_completions (habit_id, completed_at);
create index idx_journal_user_date on public.journal_entries (user_id, entry_date);
create index idx_aura_actions_user_status on public.aura_actions (user_id, status);
create index idx_xp_events_user on public.xp_events (user_id, created_at);

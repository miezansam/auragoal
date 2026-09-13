-- ============================================================
-- Correction de type : source_id doit être text (pas uuid) pour
-- supporter des identifiants composites comme "habitId-2026-09-13",
-- nécessaires pour créditer le XP une fois par jour et par habitude.
-- ============================================================
alter table public.xp_events alter column source_id type text using source_id::text;

-- ============================================================
-- Fonctions serveur pour créditer du XP en toute sécurité.
-- Le client appelle ces fonctions via RPC — il n'a jamais
-- d'accès direct en écriture à xp_events ni à profiles.xp/level.
-- ============================================================

create or replace function public.credit_xp_for_habit_completion(p_habit_id uuid, p_completed_at date)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_amount int := 10;
  v_inserted int;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from habits where id = p_habit_id and user_id = v_user_id
  ) then
    raise exception 'Habit not found or not owned by user';
  end if;

  insert into xp_events (user_id, amount, source_type, source_id)
  values (v_user_id, v_amount, 'habit_completion', p_habit_id::text || '-' || p_completed_at::text)
  on conflict (source_type, source_id) do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted = 0 then
    -- Déjà crédité pour ce jour précis : on ne touche pas au profil.
    return;
  end if;

  update profiles
  set xp = xp + v_amount,
      level = greatest(1, floor(sqrt((xp + v_amount) / 50.0))::int + 1),
      updated_at = now()
  where id = v_user_id;
end;
$$;

grant execute on function public.credit_xp_for_habit_completion(uuid, date) to authenticated;

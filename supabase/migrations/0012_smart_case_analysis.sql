-- Smart case analysis history. Each lawyer can read/write only their own analyses.
create table if not exists public.case_analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  case_id text not null references public.cases(id) on delete cascade,
  analysis jsonb not null,
  model text,
  created_at timestamptz not null default now()
);
create index if not exists case_analyses_case_created_idx
  on public.case_analyses(user_id, case_id, created_at desc);
alter table public.case_analyses enable row level security;
drop policy if exists case_analyses_owner on public.case_analyses;
create policy case_analyses_owner on public.case_analyses
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
grant select, insert on public.case_analyses to authenticated;

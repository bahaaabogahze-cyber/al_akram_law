-- Sessions (hearings): add the fields the Sessions screen stores.
-- Safe to re-run. Run after 0001 / 0002.

alter table public.hearings add column if not exists client_name text;
alter table public.hearings add column if not exists case_number text;
alter table public.hearings add column if not exists status text not null default 'قادمة';
alter table public.hearings add column if not exists updated_at timestamptz not null default now();

create index if not exists hearings_case_idx on public.hearings(case_id);

-- RLS + grants already exist in 0001/0002 (hearings_owner, user_id = auth.uid()).

-- REFERENCE ONLY: this SQL was previously applied to the project. DO NOT RUN AGAIN.
-- 0013_ALAKRAM_ADMIN_COMPLETE.sql
-- AL AKRAM Admin Panel: additive setup for the existing profiles table.
-- Expected existing roles: profiles.role = 'admin' for the owner and 'user' for regular users.
-- Does NOT require migrations 0011 or 0012.
-- Does NOT modify or delete existing user records.
--
-- IMPORTANT:
-- 1) Run this file once in Supabase SQL Editor.
-- 2) It expects public.profiles(id uuid, role text) to exist.
-- 3) AI usage logs should be written by trusted Edge Functions using the
--    server-side service role, not directly by Flutter/browser clients.

begin;

-- ---------------------------------------------------------------------------
-- 1. Admin identity check
--    Uses the authenticated caller's existing profiles.role value.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.role = 'admin'
  );
$function$;

revoke all on function public.is_admin_user() from public;
grant execute on function public.is_admin_user() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Contract and legal-template management
-- ---------------------------------------------------------------------------
create table if not exists public.contract_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  body text not null,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists contract_templates_active_updated_idx
  on public.contract_templates (is_active, updated_at desc);

alter table public.contract_templates enable row level security;

drop policy if exists contract_templates_active_read on public.contract_templates;
create policy contract_templates_active_read
  on public.contract_templates
  for select
  to authenticated
  using (is_active = true);

drop policy if exists contract_templates_admin_all on public.contract_templates;
create policy contract_templates_admin_all
  on public.contract_templates
  for all
  to authenticated
  using ((select public.is_admin_user()))
  with check ((select public.is_admin_user()));

grant select on public.contract_templates to authenticated;
grant insert, update, delete on public.contract_templates to authenticated;

-- ---------------------------------------------------------------------------
-- 3. AI usage log
--    Only trusted server-side code (service_role) can insert/update/delete.
--    Admin users can read all rows; regular users cannot read other users' rows.
-- ---------------------------------------------------------------------------
create table if not exists public.ai_usage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  function_name text not null
    check (function_name in ('legal-assistant', 'analyze-case')),
  model text not null,
  input_tokens integer not null default 0 check (input_tokens >= 0),
  output_tokens integer not null default 0 check (output_tokens >= 0),
  estimated_cost_usd numeric(12,6)
    check (estimated_cost_usd is null or estimated_cost_usd >= 0),
  created_at timestamptz not null default now()
);

create index if not exists ai_usage_logs_created_idx
  on public.ai_usage_logs (created_at desc);

create index if not exists ai_usage_logs_user_created_idx
  on public.ai_usage_logs (user_id, created_at desc);

alter table public.ai_usage_logs enable row level security;

drop policy if exists ai_usage_logs_insert_own on public.ai_usage_logs;
drop policy if exists ai_usage_logs_read_own on public.ai_usage_logs;
drop policy if exists ai_usage_logs_admin_read on public.ai_usage_logs;

create policy ai_usage_logs_admin_read
  on public.ai_usage_logs
  for select
  to authenticated
  using ((select public.is_admin_user()));

revoke all on public.ai_usage_logs from anon, authenticated;
grant select on public.ai_usage_logs to authenticated;
grant all on public.ai_usage_logs to service_role;

-- ---------------------------------------------------------------------------
-- 4. Protect profile role changes.
--    A user cannot change their own role. Admin role changes must go through
--    admin_set_user_role(). Service role operations remain possible.
-- ---------------------------------------------------------------------------
create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.role is distinct from old.role then
    if coalesce(auth.role(), '') = 'service_role' then
      return new;
    end if;

    if coalesce(current_setting('app.admin_role_change', true), '') <> 'on'
       or not public.is_admin_user() then
      raise exception 'Changing profile role is restricted to project administrators';
    end if;
  end if;

  return new;
end;
$function$;

drop trigger if exists protect_profile_role_change on public.profiles;
create trigger protect_profile_role_change
before update of role on public.profiles
for each row
execute function public.prevent_self_role_change();

-- ---------------------------------------------------------------------------
-- 5. Guarded admin RPC for changing a user's role.
--    Supported values match this project's existing role names: admin/user.
--    Prevents self-role changes and prevents demoting the last administrator.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_user_role(
  target_user uuid,
  new_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  admin_count bigint;
begin
  if not public.is_admin_user() then
    raise exception 'admin access required';
  end if;

  if new_role not in ('admin', 'user') then
    raise exception 'unsupported role; use admin or user';
  end if;

  if target_user = (select auth.uid()) then
    raise exception 'self role changes are not allowed';
  end if;

  if not exists (select 1 from public.profiles p where p.id = target_user) then
    raise exception 'user not found';
  end if;

  if new_role = 'user' then
    select count(*) into admin_count
    from public.profiles p
    where p.role = 'admin';

    if (select p.role from public.profiles p where p.id = target_user) = 'admin'
       and admin_count <= 1 then
      raise exception 'cannot demote the last administrator';
    end if;
  end if;

  perform set_config('app.admin_role_change', 'on', true);

  update public.profiles
  set role = new_role
  where id = target_user;

  perform set_config('app.admin_role_change', 'off', true);
end;
$function$;

revoke all on function public.admin_set_user_role(uuid, text) from public, anon;
grant execute on function public.admin_set_user_role(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Refresh PostgREST schema cache.
-- ---------------------------------------------------------------------------
notify pgrst, 'reload schema';

commit;

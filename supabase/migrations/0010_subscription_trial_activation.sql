-- 0010_subscription_trial_activation.sql
-- Phase 1: server-side trial, subscriptions and activation codes.
-- This migration is additive. It does not delete or rewrite existing data.

begin;

-- =========================================================
-- Account entitlement fields
-- =========================================================

alter table public.profiles
  add column if not exists trial_started_at timestamptz,
  add column if not exists trial_ends_at timestamptz,
  add column if not exists subscription_status text not null default 'trial',
  add column if not exists subscription_started_at timestamptz,
  add column if not exists subscription_ends_at timestamptz,
  add column if not exists subscription_type text,
  add column if not exists updated_by_entitlement_at timestamptz;

alter table public.profiles
  drop constraint if exists profiles_subscription_status_check;

alter table public.profiles
  add constraint profiles_subscription_status_check
  check (subscription_status in ('trial','paid','permanent','expired','suspended'));

alter table public.profiles
  drop constraint if exists profiles_subscription_type_check;

alter table public.profiles
  add constraint profiles_subscription_type_check
  check (subscription_type is null or subscription_type in ('monthly','yearly','permanent','trial_extension'));

-- Existing accounts receive a server timestamped 3-month trial only when
-- they do not already have entitlement information. No client supplied date
-- is trusted here.
update public.profiles
set trial_started_at = coalesce(trial_started_at, created_at),
    trial_ends_at = coalesce(trial_ends_at, created_at + interval '3 months'),
    subscription_status = case
      when subscription_status is null or subscription_status = '' then 'trial'
      else subscription_status
    end
where trial_started_at is null or trial_ends_at is null;

alter table public.profiles
  alter column trial_started_at set default now(),
  alter column trial_ends_at set default (now() + interval '3 months');

-- =========================================================
-- Activation codes
-- =========================================================

create table if not exists public.activation_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  type text not null check (type in ('permanent','yearly','trial_extension')),
  expires_at timestamptz,
  max_uses integer not null default 1 check (max_uses > 0),
  used_count integer not null default 0 check (used_count >= 0 and used_count <= max_uses),
  duration_months integer,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  disabled_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists activation_codes_code_idx on public.activation_codes(code);
create index if not exists activation_codes_type_idx on public.activation_codes(type);

-- Every newly created Auth user gets the trial from the database clock.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(
    id,email,full_name,phone,specialty,bar_number,
    trial_started_at,trial_ends_at,subscription_status
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name','المحامي'),
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'specialty',
    new.raw_user_meta_data->>'bar_number',
    now(),
    now() + interval '3 months',
    'trial'
  )
  on conflict (id) do update set
    email=excluded.email,
    full_name=excluded.full_name,
    phone=excluded.phone,
    specialty=excluded.specialty,
    bar_number=excluded.bar_number,
    updated_at=now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- =========================================================
-- Server-side entitlement helpers
-- =========================================================

create or replace function public.refresh_subscription_status()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  p public.profiles;
  resulting_status text;
begin
  select * into p from public.profiles where id = auth.uid();
  if p.id is null then
    return 'missing';
  end if;

  if p.subscription_status = 'suspended' then
    return 'suspended';
  end if;

  if p.subscription_status = 'permanent' then
    return 'permanent';
  end if;

  if p.subscription_status = 'paid' and
     (p.subscription_ends_at is null or p.subscription_ends_at > now()) then
    return 'paid';
  end if;

  if p.subscription_status in ('trial','expired') and
     p.trial_ends_at is not null and p.trial_ends_at > now() then
    resulting_status := 'trial';
  else
    resulting_status := 'expired';
  end if;

  update public.profiles
  set subscription_status = resulting_status,
      updated_by_entitlement_at = now(),
      updated_at = now()
  where id = auth.uid();

  return resulting_status;
end;
$$;

create or replace function public.account_has_paid_access()
returns boolean
language sql
security definer
volatile
set search_path = public
as $$
  select public.refresh_subscription_status() in ('trial','paid','permanent');
$$;

create or replace function public.get_subscription_state()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  p public.profiles;
  s text;
begin
  s := public.refresh_subscription_status();
  select * into p from public.profiles where id = auth.uid();
  if p.id is null then
    return jsonb_build_object('status','missing','can_use_paid_features',false);
  end if;

  return jsonb_build_object(
    'status', s,
    'trial_started_at', p.trial_started_at,
    'trial_ends_at', p.trial_ends_at,
    'subscription_started_at', p.subscription_started_at,
    'subscription_ends_at', p.subscription_ends_at,
    'subscription_type', p.subscription_type,
    'can_use_paid_features', s in ('trial','paid','permanent')
  );
end;
$$;

-- =========================================================
-- Atomic activation-code redemption
-- =========================================================

create or replace function public.redeem_activation_code(input_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  c public.activation_codes;
  normalized_code text;
  current_status text;
  new_end timestamptz;
begin
  if auth.uid() is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  normalized_code := upper(regexp_replace(trim(coalesce(input_code,'')), '\\s+', '', 'g'));
  if normalized_code = '' then
    raise exception 'رمز التفعيل فارغ';
  end if;

  -- Row lock prevents two simultaneous requests from consuming the same slot.
  select * into c
  from public.activation_codes
  where code = normalized_code
    and disabled_at is null
    and (expires_at is null or expires_at > now())
    and used_count < max_uses
  for update;

  if c.id is null then
    raise exception 'رمز التفعيل غير صالح أو منتهي أو مستنفد';
  end if;

  current_status := public.refresh_subscription_status();

  if c.type = 'permanent' then
    update public.profiles
    set subscription_status = 'permanent',
        subscription_type = 'permanent',
        subscription_started_at = coalesce(subscription_started_at, now()),
        subscription_ends_at = null,
        updated_by_entitlement_at = now(),
        updated_at = now()
    where id = auth.uid();
  elsif c.type = 'yearly' then
    new_end := greatest(coalesce((select subscription_ends_at from public.profiles where id=auth.uid()), now()), now()) + interval '12 months';
    update public.profiles
    set subscription_status = 'paid',
        subscription_type = 'yearly',
        subscription_started_at = coalesce(subscription_started_at, now()),
        subscription_ends_at = new_end,
        updated_by_entitlement_at = now(),
        updated_at = now()
    where id = auth.uid();
  elsif c.type = 'trial_extension' then
    new_end := greatest(coalesce((select trial_ends_at from public.profiles where id=auth.uid()), now()), now())
      + make_interval(months => coalesce(c.duration_months, 3));
    update public.profiles
    set trial_ends_at = new_end,
        subscription_status = 'trial',
        subscription_type = 'trial_extension',
        updated_by_entitlement_at = now(),
        updated_at = now()
    where id = auth.uid();
  end if;

  update public.activation_codes
  set used_count = used_count + 1,
      updated_at = now()
  where id = c.id;

  return jsonb_build_object(
    'success', true,
    'type', c.type,
    'remaining_uses', c.max_uses - c.used_count - 1
  );
end;
$$;

-- =========================================================
-- RLS: activation codes are never readable by normal clients.
-- Admin management is server-side/admin-session only.
-- =========================================================

alter table public.activation_codes enable row level security;
revoke all on public.activation_codes from anon, authenticated;

-- Existing personal data becomes available only while the account is entitled.
-- Profiles remain readable by the owner so the subscription screen can render.

-- Do not grant activation_codes access to the APK. Redemption uses the RPC above.
revoke all on function public.redeem_activation_code(text) from public, anon;
grant execute on function public.redeem_activation_code(text) to authenticated;

revoke all on function public.get_subscription_state() from public, anon;
grant execute on function public.get_subscription_state() to authenticated;

revoke all on function public.refresh_subscription_status() from public, anon;
grant execute on function public.refresh_subscription_status() to authenticated;

-- Replace only the existing owner policies; this is additive hardening.
drop policy if exists clients_owner on public.clients;
create policy clients_owner on public.clients for all to authenticated
using (user_id=auth.uid() and public.account_has_paid_access())
with check (user_id=auth.uid() and public.account_has_paid_access());

drop policy if exists cases_owner on public.cases;
create policy cases_owner on public.cases for all to authenticated
using (user_id=auth.uid() and public.account_has_paid_access())
with check (user_id=auth.uid() and public.account_has_paid_access());

drop policy if exists hearings_owner on public.hearings;
create policy hearings_owner on public.hearings for all to authenticated
using (user_id=auth.uid() and public.account_has_paid_access())
with check (user_id=auth.uid() and public.account_has_paid_access());

drop policy if exists documents_owner on public.documents;
create policy documents_owner on public.documents for all to authenticated
using (user_id=auth.uid() and public.account_has_paid_access())
with check (user_id=auth.uid() and public.account_has_paid_access());

drop policy if exists tasks_owner on public.tasks;
create policy tasks_owner on public.tasks for all to authenticated
using (user_id=auth.uid() and public.account_has_paid_access())
with check (user_id=auth.uid() and public.account_has_paid_access());

-- Notifications can still be read after expiry, allowing account messages to show.
drop policy if exists notifications_owner on public.notifications;
create policy notifications_owner on public.notifications for all to authenticated
using (user_id=auth.uid()) with check (user_id=auth.uid());

notify pgrst, 'reload schema';
commit;

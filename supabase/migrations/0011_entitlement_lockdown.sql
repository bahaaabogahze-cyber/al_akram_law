-- 0011_entitlement_lockdown.sql
-- Run AFTER 0010. Additive; does not delete data.
-- Fixes: (1) users could edit their own trial/subscription/role columns,
--        (2) whitespace normalisation bug in redeem_activation_code,
--        (3) RLS helper wrote to the table on every row check.

begin;

-- 0) Make sure the profile columns the app and the signup trigger use exist.
alter table public.profiles
  add column if not exists email text,
  add column if not exists full_name text not null default 'المحامي',
  add column if not exists phone text,
  add column if not exists specialty text,
  add column if not exists bar_number text,
  add column if not exists avatar_path text,
  add column if not exists updated_at timestamptz not null default now();

-- 1) Column-level privileges on profiles: the app may only touch these.
revoke insert, update on public.profiles from authenticated;
grant insert (id, email, full_name, phone, specialty, bar_number, avatar_path, updated_at)
  on public.profiles to authenticated;
grant update (email, full_name, phone, specialty, bar_number, avatar_path, updated_at)
  on public.profiles to authenticated;

-- 2) Read-only entitlement check for RLS (no UPDATE inside policies).
create or replace function public.account_has_paid_access()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select case
      when p.subscription_status = 'suspended' then false
      when p.subscription_status = 'permanent' then true
      when p.subscription_status = 'paid'
           and (p.subscription_ends_at is null or p.subscription_ends_at > now()) then true
      when p.trial_ends_at is not null and p.trial_ends_at > now()
           and p.subscription_status in ('trial','expired') then true
      else false
    end
    from public.profiles p where p.id = auth.uid()
  ), false);
$$;

revoke all on function public.account_has_paid_access() from public, anon;
grant execute on function public.account_has_paid_access() to authenticated;

-- 3) Fix code normalisation ('\s+' instead of '\\s+').
create or replace function public.redeem_activation_code(input_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  c public.activation_codes;
  normalized_code text;
  new_end timestamptz;
begin
  if auth.uid() is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  normalized_code := upper(regexp_replace(coalesce(input_code,''), '\s+', '', 'g'));
  if normalized_code = '' then
    raise exception 'رمز التفعيل فارغ';
  end if;

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

  if c.type = 'permanent' then
    update public.profiles
    set subscription_status = 'permanent', subscription_type = 'permanent',
        subscription_started_at = coalesce(subscription_started_at, now()),
        subscription_ends_at = null,
        updated_by_entitlement_at = now(), updated_at = now()
    where id = auth.uid();
  elsif c.type = 'yearly' then
    new_end := greatest(coalesce((select subscription_ends_at from public.profiles where id = auth.uid()), now()), now())
               + interval '12 months';
    update public.profiles
    set subscription_status = 'paid', subscription_type = 'yearly',
        subscription_started_at = coalesce(subscription_started_at, now()),
        subscription_ends_at = new_end,
        updated_by_entitlement_at = now(), updated_at = now()
    where id = auth.uid();
  elsif c.type = 'trial_extension' then
    new_end := greatest(coalesce((select trial_ends_at from public.profiles where id = auth.uid()), now()), now())
               + make_interval(months => coalesce(c.duration_months, 3));
    update public.profiles
    set trial_ends_at = new_end, subscription_status = 'trial',
        subscription_type = 'trial_extension',
        updated_by_entitlement_at = now(), updated_at = now()
    where id = auth.uid();
  end if;

  update public.activation_codes
  set used_count = used_count + 1, updated_at = now()
  where id = c.id;

  return jsonb_build_object('success', true, 'type', c.type,
                            'remaining_uses', c.max_uses - c.used_count - 1);
end;
$$;

revoke all on function public.redeem_activation_code(text) from public, anon;
grant execute on function public.redeem_activation_code(text) to authenticated;

notify pgrst, 'reload schema';
commit;

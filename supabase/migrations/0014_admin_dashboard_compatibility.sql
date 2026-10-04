-- 0014_admin_dashboard_compatibility.sql
-- Additive compatibility for the existing AL AKRAM schema and the already-applied
-- 0013_ALAKRAM_ADMIN_COMPLETE.sql. Do NOT re-run or replace the previous 0013.
-- Existing role vocabulary is admin/user. No existing records are deleted.
begin;

-- Let administrators list profiles while preserving each user's own profile policy.
drop policy if exists profiles_admin_select on public.profiles;
create policy profiles_admin_select on public.profiles
  for select to authenticated using ((select public.is_admin_user()));

-- Dashboard subscription actions run through this SECURITY DEFINER RPC because
-- migration 0011 intentionally restricts client-side entitlement column updates.
create or replace function public.admin_set_subscription(target_user uuid, plan text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if not public.is_admin_user() then
    raise exception 'admin access required';
  end if;
  if target_user is null then
    raise exception 'target user is required';
  end if;

  if plan = 'monthly' then
    update public.profiles
      set subscription_status = 'paid', subscription_type = 'monthly',
          subscription_started_at = now(), subscription_ends_at = now() + interval '1 month',
          updated_by_entitlement_at = now(), updated_at = now()
      where id = target_user;
  elsif plan = 'yearly' then
    update public.profiles
      set subscription_status = 'paid', subscription_type = 'yearly',
          subscription_started_at = now(), subscription_ends_at = now() + interval '1 year',
          updated_by_entitlement_at = now(), updated_at = now()
      where id = target_user;
  elsif plan = 'permanent' then
    update public.profiles
      set subscription_status = 'permanent', subscription_type = 'permanent',
          subscription_started_at = now(), subscription_ends_at = null,
          updated_by_entitlement_at = now(), updated_at = now()
      where id = target_user;
  elsif plan = 'suspended' then
    update public.profiles
      set subscription_status = 'suspended',
          updated_by_entitlement_at = now(), updated_at = now()
      where id = target_user;
  else
    raise exception 'unsupported subscription plan';
  end if;
  if not found then raise exception 'user not found'; end if;
end;
$function$;
revoke all on function public.admin_set_subscription(uuid, text) from public, anon;
grant execute on function public.admin_set_subscription(uuid, text) to authenticated;

-- The dashboard manages activation codes and legal content. Keep the policies
-- administrator-only; existing authenticated read policies remain in place.
alter table public.activation_codes enable row level security;
drop policy if exists activation_codes_admin_all on public.activation_codes;
create policy activation_codes_admin_all on public.activation_codes
  for all to authenticated using ((select public.is_admin_user()))
  with check ((select public.is_admin_user()));
grant select, insert, update, delete on public.activation_codes to authenticated;

alter table public.legal_sources enable row level security;
alter table public.legal_articles enable row level security;
drop policy if exists legal_sources_admin_manage on public.legal_sources;
create policy legal_sources_admin_manage on public.legal_sources
  for all to authenticated using ((select public.is_admin_user()))
  with check ((select public.is_admin_user()));
drop policy if exists legal_articles_admin_manage on public.legal_articles;
create policy legal_articles_admin_manage on public.legal_articles
  for all to authenticated using ((select public.is_admin_user()))
  with check ((select public.is_admin_user()));
grant select, insert, update, delete on public.legal_sources, public.legal_articles to authenticated;

notify pgrst, 'reload schema';
commit;

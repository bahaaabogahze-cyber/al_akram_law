-- Home/Auth/Profile hardening for existing Supabase projects.
alter table public.notifications add column if not exists related_type text;
alter table public.notifications add column if not exists related_id text;
create index if not exists notifications_user_read_idx
  on public.notifications(user_id, read, created_at desc);

-- Keep profile email synchronized with Auth email when the auth email changes.
create or replace function public.handle_auth_user_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set email = new.email,
      updated_at = now()
  where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
after update of email on auth.users
for each row execute procedure public.handle_auth_user_update();

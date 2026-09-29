-- 0009_security_and_legal_search_hardening.sql
-- Run AFTER 0005_legal_library_rpc.sql

-- =========================================================
-- Permissions
-- =========================================================

revoke all on public.profiles,
  public.clients,
  public.cases,
  public.hearings,
  public.documents,
  public.notifications,
  public.tasks
from anon;

revoke all on public.legal_sources, public.legal_articles
from public, anon;

grant select on public.legal_sources, public.legal_articles
to authenticated;


-- =========================================================
-- Legal library RPC permissions
-- IMPORTANT:
-- 0005 creates search_legal_articles with 4 arguments
-- and browse_legal_articles with 3 arguments.
-- =========================================================

revoke all on function public.search_legal_articles(
  text,
  text,
  integer,
  integer
) from public, anon;

grant execute on function public.search_legal_articles(
  text,
  text,
  integer,
  integer
) to authenticated;

revoke all on function public.browse_legal_articles(
  text,
  integer,
  integer
) from public, anon;

grant execute on function public.browse_legal_articles(
  text,
  integer,
  integer
) to authenticated;


-- =========================================================
-- Search performance indexes
-- =========================================================

create index if not exists legal_articles_title_trgm_idx
  on public.legal_articles
  using gin (title gin_trgm_ops);

create index if not exists legal_articles_article_number_trgm_idx
  on public.legal_articles
  using gin (article_number gin_trgm_ops);

create index if not exists legal_articles_source_current_idx
  on public.legal_articles (source_id, article_number, id)
  where is_current = true;

create index if not exists legal_sources_title_trgm_idx
  on public.legal_sources
  using gin (title gin_trgm_ops);

create index if not exists legal_sources_current_title_idx
  on public.legal_sources (is_current, title);


-- =========================================================
-- Prevent linking another user's client to a case
-- =========================================================

create or replace function public.enforce_case_client_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin
  if new.client_id is not null then

    select user_id
    into owner_id
    from public.clients
    where id = new.client_id;

    if owner_id is null
       or owner_id <> new.user_id then
      raise exception
        'client_id does not belong to the current user';
    end if;

  end if;

  return new;
end;
$$;


drop trigger if exists cases_client_owner_guard
on public.cases;

create trigger cases_client_owner_guard
before insert or update of client_id, user_id
on public.cases
for each row
execute function public.enforce_case_client_owner();


-- =========================================================
-- Prevent linking another user's case to hearings/documents/tasks
-- =========================================================

create or replace function public.enforce_case_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin

  if new.case_id is not null then

    select user_id
    into owner_id
    from public.cases
    where id = new.case_id;

    if owner_id is null
       or owner_id <> new.user_id then
      raise exception
        'case_id does not belong to the current user';
    end if;

  end if;

  return new;
end;
$$;


drop trigger if exists hearings_case_owner_guard
on public.hearings;

create trigger hearings_case_owner_guard
before insert or update of case_id, user_id
on public.hearings
for each row
execute function public.enforce_case_owner();


drop trigger if exists documents_case_owner_guard
on public.documents;

create trigger documents_case_owner_guard
before insert or update of case_id, user_id
on public.documents
for each row
execute function public.enforce_case_owner();


drop trigger if exists tasks_case_owner_guard
on public.tasks;

create trigger tasks_case_owner_guard
before insert or update of case_id, user_id
on public.tasks
for each row
execute function public.enforce_case_owner();


-- =========================================================
-- Enable RLS
-- =========================================================

alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.cases enable row level security;
alter table public.hearings enable row level security;
alter table public.documents enable row level security;
alter table public.notifications enable row level security;
alter table public.tasks enable row level security;
alter table public.legal_sources enable row level security;
alter table public.legal_articles enable row level security;


-- =========================================================
-- Profiles
-- =========================================================

drop policy if exists profiles_self
on public.profiles;

create policy profiles_self
on public.profiles
for all
to authenticated
using (id = auth.uid())
with check (id = auth.uid());


-- =========================================================
-- Clients
-- =========================================================

drop policy if exists clients_owner
on public.clients;

create policy clients_owner
on public.clients
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Cases
-- =========================================================

drop policy if exists cases_owner
on public.cases;

create policy cases_owner
on public.cases
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Hearings
-- =========================================================

drop policy if exists hearings_owner
on public.hearings;

create policy hearings_owner
on public.hearings
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Documents
-- =========================================================

drop policy if exists documents_owner
on public.documents;

create policy documents_owner
on public.documents
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Notifications
-- =========================================================

drop policy if exists notifications_owner
on public.notifications;

create policy notifications_owner
on public.notifications
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Tasks
-- =========================================================

drop policy if exists tasks_owner
on public.tasks;

create policy tasks_owner
on public.tasks
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


-- =========================================================
-- Legal sources
-- =========================================================

drop policy if exists legal_sources_read
on public.legal_sources;

create policy legal_sources_read
on public.legal_sources
for select
to authenticated
using (true);


-- =========================================================
-- Legal articles
-- =========================================================

drop policy if exists legal_articles_read
on public.legal_articles;

create policy legal_articles_read
on public.legal_articles
for select
to authenticated
using (true);


-- =========================================================
-- Private document storage
-- =========================================================

drop policy if exists documents_storage_read
on storage.objects;

create policy documents_storage_read
on storage.objects
for select
to authenticated
using (
  bucket_id = 'legal-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);


drop policy if exists documents_storage_insert
on storage.objects;

create policy documents_storage_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'legal-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);


drop policy if exists documents_storage_update
on storage.objects;

create policy documents_storage_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'legal-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'legal-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);


drop policy if exists documents_storage_delete
on storage.objects;

create policy documents_storage_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'legal-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);


-- =========================================================
-- Make document bucket private
-- =========================================================

update storage.buckets
set public = false
where id = 'legal-documents';


-- =========================================================
-- Reload PostgREST schema
-- =========================================================

notify pgrst, 'reload schema';
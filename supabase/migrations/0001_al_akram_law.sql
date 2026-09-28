-- الأكرم للمحاماة - production schema
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default 'المحامي',
  phone text,
  specialty text,
  bar_number text,
  avatar_path text,
  role text not null default 'lawyer' check (role in ('lawyer','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null, national_id text, phone text, email text, address text, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.cases (
  id text primary key, user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, case_number text, client_name text, client_id uuid references public.clients(id) on delete set null,
  court text, opponent text, summary text, notes text, case_type text, status text default 'جارية',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.hearings (
  id text primary key, user_id uuid not null references auth.users(id) on delete cascade,
  case_id text references public.cases(id) on delete cascade, title text not null, court text,
  hearing_at timestamptz, notes text, created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id text primary key, user_id uuid not null references auth.users(id) on delete cascade,
  case_id text references public.cases(id) on delete cascade, title text not null default 'مستند قانوني',
  notes text, tags text, storage_path text, mime_type text, ocr_text text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, body text, read boolean not null default false, created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  case_id text references public.cases(id) on delete cascade, title text not null, description text,
  due_at timestamptz, priority text default 'normal', completed boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.legal_sources (
  id uuid primary key default gen_random_uuid(), title text not null, source_type text not null,
  issuing_authority text, official_reference text, publication_date date, effective_from date,
  effective_to date, source_url text, version_label text, is_current boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.legal_articles (
  id uuid primary key default gen_random_uuid(), source_id uuid not null references public.legal_sources(id) on delete cascade,
  article_number text not null, title text, content text not null, keywords text[], section text,
  effective_from date, effective_to date, is_current boolean not null default true,
  search_vector tsvector generated always as (to_tsvector('simple', coalesce(article_number,'') || ' ' || coalesce(title,'') || ' ' || coalesce(content,'') || ' ' || coalesce(array_to_string(keywords,' '),''))) stored,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(source_id, article_number)
);

create index if not exists legal_articles_search_idx on public.legal_articles using gin(search_vector);
create index if not exists legal_articles_content_trgm_idx on public.legal_articles using gin(content gin_trgm_ops);
create index if not exists cases_user_idx on public.cases(user_id, updated_at desc);
create index if not exists documents_user_idx on public.documents(user_id, created_at desc);
create index if not exists hearings_user_idx on public.hearings(user_id, hearing_at);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,email,full_name,phone,specialty,bar_number)
  values (new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name','المحامي'),new.raw_user_meta_data->>'phone',new.raw_user_meta_data->>'specialty',new.raw_user_meta_data->>'bar_number')
  on conflict (id) do update set email=excluded.email, full_name=excluded.full_name, phone=excluded.phone, specialty=excluded.specialty, bar_number=excluded.bar_number, updated_at=now();
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.search_legal_articles(q text, category text default null, max_results int default 30)
returns table(id uuid, source_id uuid, source_title text, article_number text, title text, content text, keywords text[], relevance real)
language sql stable security invoker as $$
  select a.id,a.source_id,s.title,a.article_number,a.title,a.content,a.keywords,
    greatest(ts_rank(a.search_vector, plainto_tsquery('simple', q)), similarity(a.content,q))::real as relevance
  from public.legal_articles a join public.legal_sources s on s.id=a.source_id
  where a.is_current=true and (category is null or s.title=category)
    and (q is null or q='' or a.search_vector @@ plainto_tsquery('simple',q) or a.content % q or a.title % q or a.article_number % q)
  order by relevance desc, a.article_number
  limit greatest(1, least(max_results,100));
$$;

-- RLS: every exposed table is protected; lawyers can only access their own records.
do $$ declare t text; begin
  foreach t in array array['profiles','clients','cases','hearings','documents','notifications','tasks'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;

create policy profiles_self on public.profiles for all to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy clients_owner on public.clients for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy cases_owner on public.cases for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy hearings_owner on public.hearings for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy documents_owner on public.documents for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy notifications_owner on public.notifications for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy tasks_owner on public.tasks for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

alter table public.legal_sources enable row level security;
alter table public.legal_articles enable row level security;
create policy legal_sources_read on public.legal_sources for select to authenticated using (true);
create policy legal_articles_read on public.legal_articles for select to authenticated using (true);

-- Private bucket for client documents. Files are never public.
insert into storage.buckets (id,name,public) values ('legal-documents','legal-documents',false) on conflict (id) do update set public=false;
create policy documents_storage_read on storage.objects for select to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy documents_storage_insert on storage.objects for insert to authenticated with check (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy documents_storage_update on storage.objects for update to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy documents_storage_delete on storage.objects for delete to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);

-- Admin-only ingestion is intentionally server-side. Never expose a service_role key in the app.

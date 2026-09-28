-- Production hardening for the Syrian lawyers platform.
-- Run after 0001_al_akram_law.sql.

-- Explicit Data API privileges; RLS remains the authorization boundary.
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.clients to authenticated;
grant select, insert, update, delete on public.cases to authenticated;
grant select, insert, update, delete on public.hearings to authenticated;
grant select, insert, update, delete on public.documents to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant select on public.legal_sources to authenticated;
grant select on public.legal_articles to authenticated;
grant execute on function public.search_legal_articles(text,text,integer) to authenticated;

-- Keep rerunning migrations safe.
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles for all to authenticated using (id=auth.uid()) with check (id=auth.uid());
drop policy if exists clients_owner on public.clients;
create policy clients_owner on public.clients for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists cases_owner on public.cases;
create policy cases_owner on public.cases for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists hearings_owner on public.hearings;
create policy hearings_owner on public.hearings for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists documents_owner on public.documents;
create policy documents_owner on public.documents for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists notifications_owner on public.notifications;
create policy notifications_owner on public.notifications for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists tasks_owner on public.tasks;
create policy tasks_owner on public.tasks for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists legal_sources_read on public.legal_sources;
create policy legal_sources_read on public.legal_sources for select to authenticated using (true);
drop policy if exists legal_articles_read on public.legal_articles;
create policy legal_articles_read on public.legal_articles for select to authenticated using (true);

drop policy if exists documents_storage_read on storage.objects;
create policy documents_storage_read on storage.objects for select to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists documents_storage_insert on storage.objects;
create policy documents_storage_insert on storage.objects for insert to authenticated with check (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists documents_storage_update on storage.objects;
create policy documents_storage_update on storage.objects for update to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists documents_storage_delete on storage.objects;
create policy documents_storage_delete on storage.objects for delete to authenticated using (bucket_id='legal-documents' and (storage.foldername(name))[1]=auth.uid()::text);

insert into storage.buckets (id,name,public) values ('legal-documents','legal-documents',false)
on conflict (id) do update set public=false;

-- Link in-app notifications to tasks and hearings.
alter table public.notifications add column if not exists related_type text;
alter table public.notifications add column if not exists related_id text;
create index if not exists notifications_related_idx on public.notifications(user_id, related_type, related_id);

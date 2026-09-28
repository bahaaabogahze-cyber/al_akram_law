-- Remote legal library/search API used by the Flutter app.
-- The app only receives data through authenticated, read-only RPC calls.

drop function if exists public.search_legal_articles(text,text,integer);
create or replace function public.search_legal_articles(q text, category text default null, max_results int default 30)
returns table(
  id uuid,
  source_id uuid,
  source_title text,
  source_type text,
  official_reference text,
  source_url text,
  version_label text,
  article_number text,
  title text,
  content text,
  keywords text[],
  penalty_type text,
  penalty_duration text,
  fine_amount text,
  course_name text,
  legal_source text,
  source_category text,
  relevance real
)
language sql stable security invoker as $$
  select a.id,a.source_id,s.title,s.source_type,s.official_reference,s.source_url,s.version_label,
    a.article_number,a.title,a.content,a.keywords,a.penalty_type,a.penalty_duration,a.fine_amount,
    a.course_name,a.legal_source,a.source_category,
    greatest(
      ts_rank(a.search_vector, plainto_tsquery('simple', coalesce(q,''))),
      similarity(coalesce(a.content,''),coalesce(q,''))
    )::real as relevance
  from public.legal_articles a
  join public.legal_sources s on s.id=a.source_id
  where a.is_current=true
    and (category is null or s.title=category)
    and (
      q is null or q='' or
      a.search_vector @@ plainto_tsquery('simple',q) or
      coalesce(a.content,'') % q or coalesce(a.title,'') % q or
      coalesce(a.article_number,'') % q
    )
  order by relevance desc, a.article_number, a.id
  limit greatest(1, least(coalesce(max_results,30),100));
$$;

drop function if exists public.browse_legal_articles(text,integer,integer);
create or replace function public.browse_legal_articles(category text default null, page_size int default 50, page_offset int default 0)
returns table(
  id uuid,
  source_id uuid,
  source_title text,
  source_type text,
  official_reference text,
  source_url text,
  version_label text,
  article_number text,
  title text,
  content text,
  keywords text[],
  penalty_type text,
  penalty_duration text,
  fine_amount text,
  course_name text,
  legal_source text,
  source_category text
)
language sql stable security invoker as $$
  select a.id,a.source_id,s.title,s.source_type,s.official_reference,s.source_url,s.version_label,
    a.article_number,a.title,a.content,a.keywords,a.penalty_type,a.penalty_duration,a.fine_amount,
    a.course_name,a.legal_source,a.source_category
  from public.legal_articles a
  join public.legal_sources s on s.id=a.source_id
  where a.is_current=true and (category is null or s.title=category)
  order by s.title, a.article_number, a.id
  limit greatest(1, least(coalesce(page_size,50),100))
  offset greatest(0, page_offset);
$$;

grant execute on function public.search_legal_articles(text,text,integer) to authenticated;
grant execute on function public.browse_legal_articles(text,integer,integer) to authenticated;
notify pgrst, 'reload schema';

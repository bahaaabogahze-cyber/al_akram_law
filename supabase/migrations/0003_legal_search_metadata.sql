-- Richer legal-search response for the Syrian lawyers platform.
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
  relevance real
)
language sql stable security invoker as $$
  select a.id,a.source_id,s.title,s.source_type,s.official_reference,s.source_url,s.version_label,
    a.article_number,a.title,a.content,a.keywords,
    greatest(ts_rank(a.search_vector, plainto_tsquery('simple', q)), similarity(a.content,q))::real as relevance
  from public.legal_articles a
  join public.legal_sources s on s.id=a.source_id
  where a.is_current=true
    and (category is null or s.title=category)
    and (q is null or q='' or a.search_vector @@ plainto_tsquery('simple',q)
         or a.content % q or coalesce(a.title,'') % q or a.article_number % q)
  order by relevance desc, a.article_number
  limit greatest(1, least(max_results,100));
$$;

grant execute on function public.search_legal_articles(text,text,integer) to authenticated;

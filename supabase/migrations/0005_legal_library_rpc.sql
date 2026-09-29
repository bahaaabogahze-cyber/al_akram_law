-- ============================================================
-- 0005 - Optimized and paginated legal library RPCs
-- ============================================================

drop function if exists public.search_legal_articles(text,text,integer);
drop function if exists public.search_legal_articles(text,text,integer,integer);

create or replace function public.search_legal_articles(
  q text,
  category text default null,
  max_results int default 30,
  page_offset int default 0
)
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
language sql
stable
security invoker
set search_path = public
as $$
  with params as (
    select
      nullif(trim(q), '') as query_text,
      nullif(trim(category), '') as category_text,
      greatest(1, least(coalesce(max_results, 30), 50)) as page_size,
      greatest(0, coalesce(page_offset, 0)) as page_offset
  ),
  scored as (
    select
      a.*,
      s.title as source_title,
      s.source_type,
      s.official_reference,
      s.source_url,
      s.version_label,
      greatest(
        ts_rank_cd(
          a.search_vector,
          plainto_tsquery('simple', p.query_text)
        ),
        similarity(coalesce(a.content, ''), p.query_text),
        similarity(coalesce(a.title, ''), p.query_text),
        similarity(coalesce(a.article_number, ''), p.query_text)
      )::real as score
    from public.legal_articles a
    join public.legal_sources s
      on s.id = a.source_id
    cross join params p
    where a.is_current = true
      and s.is_current = true
      and (
        p.category_text is null
        or s.title = p.category_text
      )
      and (
        p.query_text is null
        or a.search_vector @@ plainto_tsquery(
          'simple',
          p.query_text
        )
        or coalesce(a.content, '') % p.query_text
        or coalesce(a.title, '') % p.query_text
        or coalesce(a.article_number, '') % p.query_text
      )
  )
  select
    id,
    source_id,
    source_title,
    source_type,
    official_reference,
    source_url,
    version_label,
    article_number,
    title,
    content,
    keywords,
    penalty_type,
    penalty_duration,
    fine_amount,
    course_name,
    legal_source,
    source_category,
    score
  from scored
  order by score desc,
           source_title,
           article_number,
           id
  limit (
    select page_size
    from params
  )
  offset (
    select page_offset
    from params
  );
$$;


create or replace function public.browse_legal_articles(
  category text default null,
  page_size int default 50,
  page_offset int default 0
)
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
language sql
stable
security invoker
set search_path = public
as $$
  select
    a.id,
    a.source_id,
    s.title,
    s.source_type,
    s.official_reference,
    s.source_url,
    s.version_label,
    a.article_number,
    a.title,
    a.content,
    a.keywords,
    a.penalty_type,
    a.penalty_duration,
    a.fine_amount,
    a.course_name,
    a.legal_source,
    a.source_category
  from public.legal_articles a
  join public.legal_sources s
    on s.id = a.source_id
  where a.is_current = true
    and s.is_current = true
    and (
      nullif(trim(category), '') is null
      or s.title = category
    )
  order by
    s.title,
    a.article_number,
    a.id
  limit greatest(
    1,
    least(coalesce(page_size, 50), 50)
  )
  offset greatest(
    0,
    coalesce(page_offset, 0)
  );
$$;


notify pgrst, 'reload schema';
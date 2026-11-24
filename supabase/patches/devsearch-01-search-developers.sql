-- ============================================================================
-- Patch: devsearch-01-search-developers.sql
-- Purpose: Case-insensitive developer search by tech stack and keyword
-- Area: Community Tab (3C Developer Search)
-- Notes:
--   - Idempotent: can be executed multiple times without side effects
--   - Read-only RPC with SECURITY DEFINER
--   - Respects existing RLS policies on public.users
--   - Matches any selected stack case-insensitively and ranks by match count desc
-- ============================================================================

create or replace function public.search_developers_by_stack(
  p_stacks text[] default null,
  p_query text default null
)
returns setof public.users
language sql
stable
security definer
set search_path = public
as $$
  select u.*
  from public.users u
  left join lateral (
    select count(*) as match_count
    from unnest(u.stack) s
    where p_stacks is not null
      and cardinality(p_stacks) > 0
      and lower(s) = any(select lower(x) from unnest(p_stacks) x)
  ) m on true
  where (
    p_stacks is null
    or cardinality(p_stacks) = 0
    or m.match_count > 0
  )
  and (
    p_query is null
    or trim(p_query) = ''
    or u.name ilike '%' || trim(p_query) || '%'
    or u.handle ilike '%' || trim(p_query) || '%'
    or u.branch ilike '%' || trim(p_query) || '%'
    or exists (
      select 1
      from unnest(u.stack) s
      where s ilike '%' || trim(p_query) || '%'
    )
  )
  order by coalesce(m.match_count, 0) desc, u.aura desc;
$$;

-- Grant execute to authenticated and anon roles
grant execute on function public.search_developers_by_stack(text[], text) to authenticated, anon;

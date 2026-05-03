-- Premium and Free Weekly Challenge Questions Table
-- This schema supports the ChallengeService and WeeklyPremiumChallengeScreen

-- 1. Create free_questions table
create table if not exists public.free_questions (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  difficulty text not null default 'Medium',
  tags text[] default '{}'::text[],
  topic text not null,
  hint text,
  solution text,
  week integer not null,
  is_premium boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. Create premium_questions table
create table if not exists public.premium_questions (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  difficulty text not null default 'Medium',
  tags text[] default '{}'::text[],
  topic text not null,
  hint text,
  solution text,
  career_goal text not null, -- References CareerGoal id (e.g., 'fullstack', 'backend')
  week integer not null,
  is_premium boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Enable RLS
alter table public.free_questions enable row level security;
alter table public.premium_questions enable row level security;

-- Policies for free_questions
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'free_questions' and policyname = 'Allow select for all authenticated users') then
    create policy "Allow select for all authenticated users" on public.free_questions for select to authenticated using (true);
  end if;
end
$$;

-- Policies for premium_questions
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'premium_questions' and policyname = 'Allow select for premium users') then
    create policy "Allow select for premium users" on public.premium_questions for select to authenticated 
    using (
      exists (
        select 1 from public.users 
        where id = auth.uid() and is_premium = true
      )
    );
  end if;
end
$$;

-- SEED DATA for Week 17 (Approx current week)
-- You can change the 'week' value to match the current week number

-- Seed for Full Stack
insert into public.premium_questions (title, description, difficulty, tags, topic, hint, solution, career_goal, week)
values (
  'Optimizing Next.js Hydration',
  'Explain the common causes of hydration mismatch in Next.js and how to resolve them when using third-party browser-only libraries.',
  'Hard',
  array['Next.js', 'React', 'SSR'],
  'Frontend Hydration',
  'Think about when the code runs on the server vs client.',
  'Hydration mismatch occurs when the server-rendered HTML differs from the first client-side render. To fix browser-only libraries, use useEffect or dynamic imports with { ssr: false }.',
  'fullstack',
  17
);

-- Seed for Backend
insert into public.premium_questions (title, description, difficulty, tags, topic, hint, solution, career_goal, week)
values (
  'Designing Idempotent APIs',
  'How would you design a POST /orders endpoint to be idempotent in a distributed system where network retries are common?',
  'Hard',
  array['API Design', 'Distributed Systems', 'Idempotency'],
  'System Design',
  'Idempotency keys are your friend.',
  'Use a client-generated Idempotency-Key header. Store this key in a database (like Redis) with the response. If the same key is received again, return the cached response.',
  'backend',
  17
);

-- Seed for Mobile
insert into public.premium_questions (title, description, difficulty, tags, topic, hint, solution, career_goal, week)
values (
  'Flutter Isolates vs Compute',
  'When should you use a long-lived Isolate over the compute() function in Flutter for background processing?',
  'Medium',
  array['Flutter', 'Dart', 'Concurrency'],
  'Performance',
  'compute() spawns and kills a new isolate every time.',
  'Use compute() for one-off heavy tasks like JSON parsing. Use a long-lived Isolate for continuous streams of data or tasks that require persistent state across multiple operations.',
  'mobile',
  17
);

insert into public.missions (
  title,
  type,
  tech_stack,
  question,
  options,
  correct_answer,
  link,
  points_reward,
  publish_date,
  is_active
)
select *
from (
  values
    (
      'Flutter Debug Sprint',
      'coding',
      'flutter',
      'Fix one real UI or state bug in your current Flutter project and submit a short note or repo link.',
      null,
      null,
      'https://docs.flutter.dev/testing/errors',
      20,
      timezone('utc'::text, now())::date,
      true
    ),
    (
      'JavaScript Array Check',
      'mcq',
      'javascript',
      'Which method creates a new array with all elements that pass a test function?',
      '["map", "filter", "reduce", "find"]'::jsonb,
      'filter',
      null,
      15,
      timezone('utc'::text, now())::date,
      true
    ),
    (
      'SQL Keyword Recall',
      'oneword',
      'backend',
      'What SQL keyword is used to combine rows from two tables based on a related column?',
      null,
      'join',
      null,
      10,
      timezone('utc'::text, now())::date,
      true
    ),
    (
      'General Builder Reflection',
      'oneword',
      'general',
      'One word only: what data structure uses FIFO ordering?',
      null,
      'queue',
      null,
      10,
      timezone('utc'::text, now())::date,
      true
    )
) as seed_data(
  title,
  type,
  tech_stack,
  question,
  options,
  correct_answer,
  link,
  points_reward,
  publish_date,
  is_active
)
where not exists (
  select 1
  from public.missions existing
  where existing.publish_date = seed_data.publish_date
    and lower(existing.tech_stack) = lower(seed_data.tech_stack)
    and existing.is_active = true
);

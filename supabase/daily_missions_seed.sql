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
      'Flutter State Update Quiz',
      'mcq',
      'flutter',
      'In Flutter, which method should you call to rebuild a StatefulWidget after changing local state?',
      '["setState", "dispose", "initState", "buildContext"]'::jsonb,
      'setState',
      null,
      20,
      timezone('Asia/Kolkata'::text, now())::date,
      true
    ),
    (
      'JavaScript Array Filter Check',
      'mcq',
      'javascript',
      'Which method creates a new array with all elements that pass a test function?',
      '["map", "filter", "reduce", "find"]'::jsonb,
      'filter',
      null,
      20,
      timezone('Asia/Kolkata'::text, now())::date,
      true
    ),
    (
      'SQL Query Join Quiz',
      'mcq',
      'backend',
      'Which SQL clause is used to combine rows from two tables using a related column?',
      '["GROUP BY", "ORDER BY", "JOIN", "LIMIT"]'::jsonb,
      'JOIN',
      null,
      20,
      timezone('Asia/Kolkata'::text, now())::date,
      true
    ),
    (
      'General DSA Queue Check',
      'mcq',
      'general',
      'Which data structure follows FIFO ordering?',
      '["Stack", "Queue", "Tree", "Graph"]'::jsonb,
      'Queue',
      null,
      20,
      timezone('Asia/Kolkata'::text, now())::date,
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

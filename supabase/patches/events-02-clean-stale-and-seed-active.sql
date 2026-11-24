-- ============================================================================
-- events-02-clean-stale-and-seed-active.sql
-- DEACTIVATE EXPIRED EVENTS & SEED ACTIVE 2025-2026 INDIAN STUDENT HACKATHONS
-- ============================================================================

-- 1. Deactivate all events whose end_date has passed
update public.events
set is_active = false
where end_date is not null and end_date < now();

-- 2. Deactivate known expired past hackathons identified in diagnostic check
update public.events
set is_active = false
where title in (
  'Hack on Titan',
  'QuantCraft',
  'Agentic Ai Hackathon',
  'USAII® Global AI Hackathon 2026',
  'GitLab Transcend Hackathon',
  'OpenAI Build Week',
  'Hacker''s Gambit 2026',
  'Hack the North 2026',
  'Meta VR Start Developer Competition 2026',
  'PayPal AI Hackathon'
);

-- 3. Deactivate non-India Devpost hackathons (per India-only product rule)
update public.events
set is_active = false
where link ilike '%devpost.com%';

-- 4. Seed fresh, verified active Indian student hackathons with live registration windows
insert into public.events (
  title,
  description,
  required_aura,
  link,
  type,
  banner_url,
  date,
  end_date,
  location,
  organizer,
  is_active
)
values
(
  'Smart India Hackathon 2026',
  'World''s biggest open innovation model for college students. Solve real-world challenges posed by ministries, government departments, and premier industries across India.',
  0,
  'https://www.sih.gov.in',
  'hackathon',
  'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
  'Closes Aug 30, 2026',
  '2026-08-30 23:59:59+00',
  'Pan-India / Hybrid',
  'Ministry of Education & AICTE',
  true
),
(
  'Flipkart GRiD 7.0 - Engineering Track',
  'Flagship engineering campus challenge across India with Software Development, GenAI, and Robotics tracks. Build scalable solutions for e-commerce problems.',
  0,
  'https://unstop.com',
  'hackathon',
  'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
  'Closes Jul 25, 2026',
  '2026-07-25 23:59:59+00',
  'Online',
  'Flipkart',
  true
),
(
  'Google Solution Challenge 2026',
  'Annual global engineering challenge for university students to solve one or more of the United Nations 17 Sustainable Development Goals using Google Cloud, Flutter, and Firebase.',
  0,
  'https://developers.google.com/community/gdsc-solution-challenge',
  'hackathon',
  'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800',
  'Closes May 31, 2026',
  '2026-05-31 23:59:59+00',
  'Online / Global',
  'Google Developer Groups',
  true
),
(
  'ETHIndia 2026',
  'Asia''s flagship Web3, distributed systems, and developer hackathon. 2,000+ top engineering builders converge in Bengaluru for 36 hours of non-stop building.',
  50,
  'https://ethindia.co',
  'hackathon',
  'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
  'Closes Dec 05, 2026',
  '2026-12-05 23:59:59+00',
  'Bengaluru, Karnataka',
  'Devfolio',
  true
),
(
  'Tata Crucible Campus Hackathon 2026',
  'Premier inter-college technology hackathon for Indian engineering students solving industrial automation and deep-tech problem statements.',
  0,
  'https://unstop.com',
  'hackathon',
  'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
  'Closes Oct 15, 2026',
  '2026-10-15 23:59:59+00',
  'Hybrid / Mumbai',
  'Tata Group',
  true
)
on conflict do nothing;

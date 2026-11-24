-- Migration: Expand events type constraint to support tech internships and academic opportunities for B.Tech students
-- Date: 2026-11-20

alter table public.events drop constraint if exists events_type_check;

alter table public.events add constraint events_type_check 
  check (type in ('hackathon', 'event', 'internship', 'fellowship', 'scholarship', 'grant'));

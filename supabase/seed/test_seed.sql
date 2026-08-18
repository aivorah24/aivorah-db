-- Test/QA environment seed (aivorah-test).
-- Run: node scripts/seed.js test
--
-- Test mirrors production schema exactly and is the target for the e2e suite
-- (aivorah-e2e-tests). Keep this seed STABLE — tests assert against these ids.
--
-- Test isolation rule: every mutating e2e test gets its own dedicated account so
-- tests can run in parallel with zero shared mutable state. Add a new account
-- below rather than reusing an existing one for a new mutating test.

-- @include _common_seed.sql

-- ============ DEDICATED E2E ACCOUNTS ============
-- One account per mutating test. Never share these across tests.
-- Naming: e2e.<area>.<n>@example.invalid
insert into public.users (id, name, email, role, grade, school, curriculum, school_id, section, onboarding_complete, status, admission_number) values
  ('00003333-0000-4000-8000-000000000001', 'E2E Onboarding 1',  'e2e.onboarding.1@example.invalid',  'student', null, null,                      null,   null,                                   null, false, 'active', null),
  ('00003333-0000-4000-8000-000000000002', 'E2E Assignments 1', 'e2e.assignments.1@example.invalid', 'student', '4',  'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', 'A',  true,  'active', 'E2E-0002'),
  ('00003333-0000-4000-8000-000000000003', 'E2E Challenges 1',  'e2e.challenges.1@example.invalid',  'student', '4',  'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', 'A',  true,  'active', 'E2E-0003'),
  ('00003333-0000-4000-8000-000000000004', 'E2E Habits 1',      'e2e.habits.1@example.invalid',      'student', '5',  'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', 'B',  true,  'active', 'E2E-0004'),
  ('00003333-0000-4000-8000-000000000005', 'E2E Schedule 1',    'e2e.schedule.1@example.invalid',    'student', '5',  'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', 'B',  true,  'active', 'E2E-0005'),
  ('00003333-0000-4000-8000-000000000006', 'E2E Coach 1',       'e2e.coach.1@example.invalid',       'student', '3',  'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', 'A',  true,  'active', 'E2E-0006'),
  ('00003333-0000-4000-8000-000000000007', 'E2E Teacher 1',     'e2e.teacher.1@example.invalid',     'teacher', null, 'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', null, true,  'active', null),
  ('00003333-0000-4000-8000-000000000008', 'E2E Parent 1',      'e2e.parent.1@example.invalid',      'parent',  null, 'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', null, true,  'active', null)
on conflict (id) do nothing;

-- The e2e teacher owns the e2e students, so teacher-flow tests have a roster.
insert into public.teacher_student (teacher_id, student_id, subject) values
  ('00003333-0000-4000-8000-000000000007', '00003333-0000-4000-8000-000000000002', 'Maths'),
  ('00003333-0000-4000-8000-000000000007', '00003333-0000-4000-8000-000000000003', 'Maths'),
  ('00003333-0000-4000-8000-000000000007', '00003333-0000-4000-8000-000000000004', 'Maths')
on conflict do nothing;

insert into public.parent_student (parent_id, student_id) values
  ('00003333-0000-4000-8000-000000000008', '00003333-0000-4000-8000-000000000005')
on conflict do nothing;

insert into public.student_stats (student_id, xp_points, level, study_time_minutes, current_streak, last_active_date) values
  ('00003333-0000-4000-8000-000000000002', 0, 1, 0, 0, current_date),
  ('00003333-0000-4000-8000-000000000003', 0, 1, 0, 0, current_date),
  ('00003333-0000-4000-8000-000000000004', 0, 1, 0, 0, current_date),
  ('00003333-0000-4000-8000-000000000005', 0, 1, 0, 0, current_date),
  ('00003333-0000-4000-8000-000000000006', 0, 1, 0, 0, current_date)
on conflict (student_id) do nothing;

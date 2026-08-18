-- Shared synthetic seed for NON-PRODUCTION environments only.
-- Contains no real user data. Safe to run repeatedly (idempotent).
--
-- NEVER run this against aivorah-prod.
--
-- Fixed UUIDs are deliberate: e2e tests and manual QA reference them directly.
-- Convention for seeded ids: 0000xxxx-0000-4000-8000-0000000000NN

do $$
begin
  if current_setting('aivorah.allow_seed', true) is distinct from 'yes' then
    raise exception 'Refusing to seed: set "aivorah.allow_seed" to ''yes'' first. This guard exists so seeds can never run against production.';
  end if;
end $$;

-- ============ SCHOOLS ============
insert into public.schools (id, name, curriculum, academic_year, contact_email) values
  ('00001111-0000-4000-8000-000000000001', 'Seed Test School (CBSE)',  'CBSE',   '2026-2027', 'seed-cbse@example.invalid'),
  ('00001111-0000-4000-8000-000000000002', 'Seed Test School (IB PYP)','IB PYP', '2026-2027', 'seed-ib@example.invalid')
on conflict (id) do nothing;

-- ============ USERS ============
-- Roles are constrained by users_role_check:
--   student | parent | teacher | school_admin | super_admin
-- Emails use the reserved .invalid TLD so nothing can ever be delivered.
insert into public.users (id, name, email, role, grade, school, curriculum, school_id, section, onboarding_complete, status, admission_number) values
  -- admin
  ('00002222-0000-4000-8000-000000000001', 'Seed Admin',    'seed.admin@example.invalid',    'school_admin', null, 'Seed Test School (CBSE)', 'CBSE', '00001111-0000-4000-8000-000000000001', null, true, 'active', null),
  -- teachers
  ('00002222-0000-4000-8000-000000000002', 'Seed Teacher A','seed.teacher.a@example.invalid','teacher', null, 'Seed Test School (CBSE)',   'CBSE',   '00001111-0000-4000-8000-000000000001', null, true, 'active', null),
  ('00002222-0000-4000-8000-000000000003', 'Seed Teacher B','seed.teacher.b@example.invalid','teacher', null, 'Seed Test School (IB PYP)', 'IB PYP', '00001111-0000-4000-8000-000000000002', null, true, 'active', null),
  -- parents
  ('00002222-0000-4000-8000-000000000004', 'Seed Parent A', 'seed.parent.a@example.invalid', 'parent',  null, 'Seed Test School (CBSE)',   'CBSE',   '00001111-0000-4000-8000-000000000001', null, true, 'active', null),
  ('00002222-0000-4000-8000-000000000005', 'Seed Parent B', 'seed.parent.b@example.invalid', 'parent',  null, 'Seed Test School (IB PYP)', 'IB PYP', '00001111-0000-4000-8000-000000000002', null, true, 'active', null),
  -- students (CBSE 3-6 and IB PYP 3-5, matching supported curricula)
  ('00002222-0000-4000-8000-000000000006', 'Seed Student 1','seed.student.1@example.invalid','student', '3', 'Seed Test School (CBSE)',   'CBSE',   '00001111-0000-4000-8000-000000000001', 'A', true, 'active', 'SEED-0001'),
  ('00002222-0000-4000-8000-000000000007', 'Seed Student 2','seed.student.2@example.invalid','student', '4', 'Seed Test School (CBSE)',   'CBSE',   '00001111-0000-4000-8000-000000000001', 'A', true, 'active', 'SEED-0002'),
  ('00002222-0000-4000-8000-000000000008', 'Seed Student 3','seed.student.3@example.invalid','student', '5', 'Seed Test School (CBSE)',   'CBSE',   '00001111-0000-4000-8000-000000000001', 'B', true, 'active', 'SEED-0003'),
  ('00002222-0000-4000-8000-000000000009', 'Seed Student 4','seed.student.4@example.invalid','student', '4', 'Seed Test School (IB PYP)', 'IB PYP', '00001111-0000-4000-8000-000000000002', 'A', true, 'active', 'SEED-0004'),
  -- a student mid-onboarding, for onboarding-flow tests
  ('00002222-0000-4000-8000-000000000010', 'Seed Student 5','seed.student.5@example.invalid','student', null, null,                        null,     null,                                   null, false, 'active', null)
on conflict (id) do nothing;

-- ============ RELATIONSHIPS ============
insert into public.parent_student (parent_id, student_id) values
  ('00002222-0000-4000-8000-000000000004', '00002222-0000-4000-8000-000000000006'),
  ('00002222-0000-4000-8000-000000000004', '00002222-0000-4000-8000-000000000007'), -- parent with 2 children (child-switcher tests)
  ('00002222-0000-4000-8000-000000000005', '00002222-0000-4000-8000-000000000009')
on conflict do nothing;

insert into public.teacher_student (teacher_id, student_id, subject) values
  ('00002222-0000-4000-8000-000000000002', '00002222-0000-4000-8000-000000000006', 'Maths'),
  ('00002222-0000-4000-8000-000000000002', '00002222-0000-4000-8000-000000000007', 'Maths'),
  ('00002222-0000-4000-8000-000000000002', '00002222-0000-4000-8000-000000000008', 'Maths'),
  ('00002222-0000-4000-8000-000000000003', '00002222-0000-4000-8000-000000000009', 'Maths')
on conflict do nothing;

-- ============ STUDENT STATS ============
-- A spread of progress states: fresh, mid-progress, streak-holder.
insert into public.student_stats (student_id, xp_points, level, study_time_minutes, topics_explored, challenges_completed, assignments_done, current_streak, last_active_date) values
  ('00002222-0000-4000-8000-000000000006',    0, 1,   0,  0, 0, 0, 0, current_date),
  ('00002222-0000-4000-8000-000000000007',  450, 3, 320,  8, 2, 5, 4, current_date),
  ('00002222-0000-4000-8000-000000000008', 1200, 6, 940, 21, 7, 14, 12, current_date),
  ('00002222-0000-4000-8000-000000000009',  180, 2, 110,  3, 1, 2, 1, current_date)
on conflict (student_id) do nothing;

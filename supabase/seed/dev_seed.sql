-- Dev environment seed (aivorah-dev).
-- Run: node scripts/seed.js dev
--
-- Dev is a scratch environment. Data here is disposable — wipe and reseed freely.
-- Loads the shared synthetic dataset, plus dev-only conveniences.

-- @include _common_seed.sql

-- ============ DEV-ONLY ============
-- Preference rows so the app doesn't hit first-run branches during local dev.
insert into public.user_preferences (user_email, data) values
  ('seed.student.1@example.invalid', '{"theme":"dark","voiceEnabled":true}'::jsonb),
  ('seed.student.2@example.invalid', '{"theme":"light","voiceEnabled":false}'::jsonb),
  ('seed.teacher.a@example.invalid', '{"theme":"auto"}'::jsonb)
on conflict (user_email) do nothing;

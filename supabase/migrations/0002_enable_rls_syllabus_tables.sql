-- Enables RLS on 5 tables Supabase's Advisor flagged as publicly accessible
-- (rls_disabled_in_public, critical) on 2026-08-17. These tables were added
-- by the syllabus-ingestion pipeline after supabase_rls_fix.sql was last run
-- in ai-mentor, so they were never covered by it.
--
-- Safe: every service authenticates with SUPABASE_SERVICE_KEY, which bypasses
-- RLS regardless. This only removes public/anon access — the same pattern
-- already applied to the other 48 tables in this schema (RLS on, no policies,
-- service_role-only).

alter table public.curriculum_sources enable row level security;
alter table public.syllabus_chapters enable row level security;
alter table public.syllabus_extraction_jobs enable row level security;
alter table public.syllabus_topics enable row level security;
alter table public.topic_resources enable row level security;

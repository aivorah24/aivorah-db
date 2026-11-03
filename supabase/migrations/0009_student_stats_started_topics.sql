-- B002 fix: persist in-progress ("started but not completed") topics
-- server-side. Previously startedTopics lived only in frontend local state
-- and was wiped on every hydration (refresh/re-login) because the backend
-- never stored or echoed it back. Additive, matches completed_topics' shape.
alter table "public"."student_stats" add column if not exists "started_topics" text[] default '{}'::text[];

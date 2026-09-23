-- Shared cross-teacher cache for AI-generated learning-path topic content
-- (aivorah-learning-paths-service). Lets N teachers uploading the same
-- curriculum/grade/subject/topic generate it once instead of N times.
-- cache_key is computed in app code from curriculum|grade|subject|normalized
-- topic title|normalized sorted subtopics|PIPELINE_VERSION (unit title is
-- deliberately excluded). payload holds the full finished topic result
-- (content incl. blocks/listenParts/practiceQuiz/book, groundingSource,
-- quality, status) for status='ready' topics only.
create table if not exists "public"."topic_generation_cache" (
  "id" uuid default gen_random_uuid() primary key,
  "cache_key" text not null unique,
  "curriculum" text not null,
  "grade" text not null,
  "subject" text not null,
  "topic" text not null,
  "pipeline_version" integer not null,
  "payload" jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create index if not exists topic_generation_cache_lookup_idx
  on public.topic_generation_cache using btree (curriculum, grade, subject, topic);

alter table "public"."topic_generation_cache" enable row level security;

grant select, insert, update, delete on table "public"."topic_generation_cache" to "service_role";

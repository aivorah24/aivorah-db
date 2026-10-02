-- Read Aloud (aivorah-learning-paths-service /read-aloud). Additive only.
-- Replaces the monolith's per-email JSON files on local disk, which were lost on every redeploy.

create table if not exists "public"."read_aloud_levels" (
  "student_id" uuid primary key references public.users(id) on delete cascade,
  "lexile"     integer not null check (lexile between 100 and 900),
  -- Last 50 level changes: [{ date, lexile, source: 'calibration'|'auto'|'manual', errors? }]
  "history"    jsonb not null default '[]'::jsonb,
  "updated_at" timestamptz not null default now()
);

create table if not exists "public"."read_aloud_sessions" (
  "id"               uuid primary key default gen_random_uuid(),
  "student_id"       uuid not null references public.users(id) on delete cascade,
  "topic"            text not null default 'Unknown',
  "grade"            text not null default 'Grade 3',
  "accuracy"         integer not null,
  "wcpm"             integer not null,
  "level"            text not null,
  "total_words"      integer not null,
  "duration_seconds" integer not null,
  "stars_earned"     integer not null default 0,
  "lexile"           integer,
  "created_at"       timestamptz not null default now()
);

create index if not exists read_aloud_sessions_student_idx on public.read_aloud_sessions using btree (student_id, created_at desc);

alter table "public"."read_aloud_levels" enable row level security;
alter table "public"."read_aloud_sessions" enable row level security;

grant select, insert, update, delete on table "public"."read_aloud_levels" to "service_role";
grant select, insert, update, delete on table "public"."read_aloud_sessions" to "service_role";

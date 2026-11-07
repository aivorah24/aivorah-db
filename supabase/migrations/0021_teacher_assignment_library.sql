-- A teacher's private assignment library (aivorah-assignments-service).
-- Every assignment a teacher creates is also kept here, so they can assign it
-- again later (e.g. to a student who joins the class) even after the original
-- assignment is deleted. Only the owning teacher sees their items; the service
-- reads and writes with the service role, so anon/authenticated get no access.
-- One row per distinct content: assigning the same thing again (to more
-- students, or from the library) bumps times_assigned instead of duplicating.

create table if not exists "public"."teacher_assignment_library" (
  "id" uuid primary key default gen_random_uuid(),
  "teacher_id" uuid not null references "public"."users"(id) on delete cascade,
  "title" text not null,
  "type" text,
  "subject" text,
  "chapter" text,
  "grade" text,
  "curriculum" text,
  "content" jsonb not null default '{}'::jsonb,
  "content_hash" text not null,
  "source_assignment_id" uuid,
  "times_assigned" integer not null default 1,
  "created_at" timestamptz not null default now(),
  "last_assigned_at" timestamptz not null default now(),
  unique ("teacher_id", "content_hash")
);

create index if not exists teacher_assignment_library_teacher_idx
  on "public"."teacher_assignment_library" (teacher_id, last_assigned_at desc);

alter table "public"."teacher_assignment_library" enable row level security;
revoke all on "public"."teacher_assignment_library" from anon, authenticated;

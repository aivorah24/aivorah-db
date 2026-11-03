-- A teacher's changes to a standard subject Learning Path (outline + per-topic lesson content) for their students.
create table if not exists "public"."teacher_subject_edits" (
  "id" uuid default gen_random_uuid() primary key,
  "teacher_id" uuid not null references public.users(id),
  "curriculum" text not null,
  "grade" text not null,
  "subject" text not null,
  "draft" jsonb not null default '{}'::jsonb,
  "published" jsonb,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  unique ("teacher_id", "curriculum", "grade", "subject")
);

create index if not exists teacher_subject_edits_scope_idx on public.teacher_subject_edits using btree (curriculum, grade, subject);

alter table "public"."teacher_subject_edits" enable row level security;

grant select, insert, update, delete on table "public"."teacher_subject_edits" to "service_role";

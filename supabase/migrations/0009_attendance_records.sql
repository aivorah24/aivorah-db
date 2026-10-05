-- Attendance (aivorah-attendance-service). Additive only.
-- Replaces the monolith's server/data/attendance.json on local disk, which was lost on every redeploy
-- and recorded no school, class or teacher.

create table if not exists "public"."attendance_records" (
  "id"              uuid primary key default gen_random_uuid(),
  "school_id"       uuid,
  "student_id"      uuid not null references public.users(id) on delete cascade,
  "date"            date not null,
  "status"          text not null check (status in ('present', 'absent', 'late')),
  "grade"           text,
  "section"         text,
  "marked_by"       uuid,
  "marked_by_email" text,
  "created_at"      timestamptz not null default now(),
  "updated_at"      timestamptz not null default now(),
  constraint attendance_records_student_date_key unique (student_id, date)
);

create index if not exists attendance_records_class_date_idx
  on public.attendance_records using btree (school_id, grade, section, date);

alter table "public"."attendance_records" enable row level security;

grant select, insert, update, delete on table "public"."attendance_records" to "service_role";

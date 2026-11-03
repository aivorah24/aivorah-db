create table if not exists "public"."teacher_curricula" (
  "id" uuid default gen_random_uuid() primary key,
  "teacher_id" uuid not null references public.users(id),
  "file_name" text not null,
  "mime_type" text not null,
  "file_url" text not null,
  "cloudinary_public_id" text not null,
  "status" text not null default 'uploaded',
  "error" text,
  "extracted_structure" jsonb,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create index if not exists teacher_curricula_teacher_id_idx on public.teacher_curricula using btree (teacher_id);

create table if not exists "public"."teacher_learning_paths" (
  "id" uuid default gen_random_uuid() primary key,
  "curriculum_id" uuid not null references public.teacher_curricula(id) on delete cascade,
  "teacher_id" uuid not null references public.users(id),
  "version" integer not null default 1,
  "status" text not null default 'draft',
  "content" jsonb not null default '{}'::jsonb,
  "published_content" jsonb,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create index if not exists teacher_learning_paths_teacher_id_idx on public.teacher_learning_paths using btree (teacher_id);
create index if not exists teacher_learning_paths_curriculum_id_idx on public.teacher_learning_paths using btree (curriculum_id);
create index if not exists teacher_learning_paths_status_idx on public.teacher_learning_paths using btree (status);

alter table "public"."teacher_curricula" enable row level security;
alter table "public"."teacher_learning_paths" enable row level security;

grant select, insert, update, delete on table "public"."teacher_curricula" to "service_role";
grant select, insert, update, delete on table "public"."teacher_learning_paths" to "service_role";

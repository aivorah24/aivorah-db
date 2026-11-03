-- POC pipeline (aivorah-learning-paths-service): grounded, Gemini-generated lesson
-- content for chapters/subtopics with missing, "Coming Soon", or poor-quality
-- content. Separate from unit_content_sections/topic_ai_enrichment deliberately —
-- those tables' rows carry no citation/evidence trail; this one always does.
-- Nothing reads this table yet. Learn/Listen/AI Tutor are untouched until a
-- later, separate consumption change.
create table if not exists "public"."curriculum_generated_lessons" (
  "id" uuid default gen_random_uuid() primary key,
  "curriculum" text not null,
  "grade" text not null,
  "subject" text not null,
  "pdf_file" text not null,
  "chapter_no" integer,
  "chapter_title" text,
  "subtopic" text not null,

  -- Provenance: best-effort pointer (point IDs are not stable across
  -- re-ingestion) plus a frozen snapshot of the text actually used, so a
  -- citation stays auditable even if Qdrant is later re-ingested.
  "source_chunk_ids" jsonb not null default '[]'::jsonb,
  "source_image_ids" jsonb not null default '[]'::jsonb,
  "source_chunk_snapshot" jsonb not null default '[]'::jsonb,

  "generated_content" jsonb,
  "validation_status" text not null default 'pending' check (
    validation_status in ('pending', 'insufficient_evidence', 'validated', 'flagged', 'rejected', 'skipped')
  ),
  "validation_result" jsonb,

  "schema_version" text,
  "prompt_version" text,
  "pipeline_version" text,
  "model" text,

  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,

  unique ("curriculum", "grade", "subject", "pdf_file", "subtopic", "prompt_version")
);

create index if not exists curriculum_generated_lessons_scope_idx
  on public.curriculum_generated_lessons using btree (curriculum, grade, subject, chapter_no);

create index if not exists curriculum_generated_lessons_status_idx
  on public.curriculum_generated_lessons using btree (validation_status);

alter table "public"."curriculum_generated_lessons" enable row level security;

grant select, insert, update, delete on table "public"."curriculum_generated_lessons" to "service_role";

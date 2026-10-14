-- Official CISCE (ICSE / ISC / Primary / Preschool) curriculum, ingested from
-- cisce.org by aivorah-learning-paths-service (scripts/cisce-ingest.cjs).
--
-- Kept in its own cisce_* namespace so official data never mixes with:
--   * CBSE/NCERT, IB or Cambridge rows in syllabus_chapters/syllabus_topics
--   * the existing AI-generated ICSE outline (syllabus_chapters where
--     curriculum = 'ICSE', grade 'Class I'..'Class X'), written by the
--     monolith's scripts/ingest-icse-cambridge-all.js. Those rows are NOT
--     modified here; icse_supplementary_content only reads them so reports
--     can label them SUPPLEMENTARY_ONLY.
--
-- Additive only: new tables + one view. RLS on with no policies, so only the
-- service role reads or writes (same pattern as 0002).
-- Idempotent: safe to re-run.

-- 1. Source registry — every URL we know about, live or dead. Holds metadata
--    and links only; a PDF is stored in Cloudinary (authenticated delivery)
--    only after explicit approval, recorded in storage_approved_by.
create table if not exists public.cisce_sources (
  id                  text primary key,
  url                 text not null unique,
  kind                text not null check (kind in (
                        'INDEX_PAGE', 'YEAR_PAGE', 'PUBLICATION_PAGE',
                        'SYLLABUS_PDF', 'REGULATIONS_PDF', 'AMENDMENT_CIRCULAR',
                        'FRAMEWORK_PDF', 'NOTICE_PDF', 'OTHER_PDF')),
  programme           text not null check (programme in (
                        'ICSE', 'ISC', 'PRIMARY', 'UPPER_PRIMARY', 'PRESCHOOL', 'CISCE')),
  exam_year           integer,
  version             text,
  is_primary_version  boolean not null default false,
  subject             text,
  title               text,
  grades              text[] not null default '{}',
  link_status         text not null default 'UNVERIFIED' check (link_status in (
                        'UNVERIFIED', 'VERIFIED', 'DEAD', 'UNREACHABLE', 'INVALID_PDF', 'AWAITING_SOURCE')),
  http_status         integer,
  final_url           text,
  content_type        text,
  sha256              text,
  bytes               bigint,
  page_count          integer,
  checked_at          timestamptz,
  checked_from        text,
  discovered_from     text,
  licence             text not null default 'CISCE_COPYRIGHT_METADATA_ONLY',
  storage             text not null default 'NONE' check (storage in ('NONE', 'CLOUDINARY_PRIVATE')),
  storage_public_id   text,
  storage_approved_by text,
  notes               text,
  metadata            jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint cisce_sources_storage_needs_approval
    check (storage = 'NONE' or storage_approved_by is not null)
);
create index if not exists cisce_sources_programme_year_idx on public.cisce_sources (programme, exam_year);
create index if not exists cisce_sources_link_status_idx on public.cisce_sources (link_status);

-- 2. One row per extracted PDF version (a source whose sha256 changes gets a
--    new row; the old extraction stays as history).
create table if not exists public.cisce_extractions (
  source_id     text not null references public.cisce_sources (id) on delete cascade,
  sha256        text not null,
  page_count    integer not null,
  text_pages    integer not null default 0,
  ocr_pages     integer not null default 0,
  empty_pages   integer not null default 0,
  warnings      text[] not null default '{}',
  extracted_at  timestamptz not null default now(),
  primary key (source_id, sha256)
);

-- 3. Canonical curriculum tree. ids are deterministic (uuid derived from
--    version + source + grade + subject + path) so re-runs upsert in place.
create table if not exists public.cisce_curriculum_nodes (
  id                 uuid primary key,
  curriculum_id      text not null default 'cisce' check (curriculum_id = 'cisce'),
  version            text not null,
  exam_year          integer,
  programme          text not null,
  source_id          text not null references public.cisce_sources (id) on delete restrict,
  source_sha256      text not null,
  grade_label        text not null,
  grade_number       integer check (grade_number between 0 and 12),
  subject            text not null,
  level              text not null check (level in ('UNIT', 'TOPIC', 'SUBTOPIC', 'FRAMEWORK_SECTION')),
  parent_id          uuid references public.cisce_curriculum_nodes (id) on delete cascade,
  ordinal            integer not null,
  number_label       text,
  path               text not null,
  title              text not null,
  body               text,
  page_from          integer,
  page_to            integer,
  provenance_status  text not null check (provenance_status in ('VERIFIED_OFFICIAL', 'OFFICIAL_PARTIAL')),
  approved           boolean not null default false,
  approved_by        text,
  approved_at        timestamptz,
  content_hash       text not null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint cisce_nodes_approval_has_approver check (not approved or approved_by is not null)
);
create index if not exists cisce_nodes_scope_idx
  on public.cisce_curriculum_nodes (version, grade_label, subject);
create index if not exists cisce_nodes_parent_idx on public.cisce_curriculum_nodes (parent_id);
create index if not exists cisce_nodes_source_idx on public.cisce_curriculum_nodes (source_id);

-- 4. Ingestion runs and the coverage matrix each run produced.
create table if not exists public.cisce_ingestion_runs (
  run_id       text primary key,
  started_at   timestamptz not null default now(),
  finished_at  timestamptz,
  stages       text[] not null default '{}',
  dry_run      boolean not null default false,
  args         jsonb not null default '{}'::jsonb,
  summary      jsonb not null default '{}'::jsonb
);

create table if not exists public.cisce_coverage (
  run_id        text not null references public.cisce_ingestion_runs (run_id) on delete cascade,
  grade_label   text not null,
  subject       text not null,
  status        text not null check (status in (
                  'VERIFIED_OFFICIAL', 'OFFICIAL_PARTIAL', 'SUPPLEMENTARY_ONLY',
                  'AWAITING_SOURCE', 'EXTRACTION_FAILED')),
  source_ids    text[] not null default '{}',
  unit_count    integer not null default 0,
  topic_count   integer not null default 0,
  notes         text,
  generated_at  timestamptz not null default now(),
  primary key (run_id, grade_label, subject)
);

-- 5. Read-only label over the existing AI-generated ICSE outline. A view,
--    not a column or a copy, so those rows are never written to.
create or replace view public.icse_supplementary_content as
select c.id as chapter_id, c.grade, c.subject, c.unit_no, c.title,
       'SUPPLEMENTARY_ONLY'::text as provenance_status,
       'ai_generated_monolith_ingest'::text as origin
from public.syllabus_chapters c
where upper(btrim(c.curriculum)) = 'ICSE' and c.school_id is null;

alter table public.cisce_sources          enable row level security;
alter table public.cisce_extractions      enable row level security;
alter table public.cisce_curriculum_nodes enable row level security;
alter table public.cisce_ingestion_runs   enable row level security;
alter table public.cisce_coverage         enable row level security;
revoke all on public.icse_supplementary_content from anon, authenticated;

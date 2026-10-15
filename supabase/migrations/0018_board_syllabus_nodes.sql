-- Official syllabus outlines for boards other than CISCE (Cambridge now, IB
-- next), written by aivorah-learning-paths-service scripts/cambridge-ingest.cjs.
-- Outline only: chapter and topic titles from the board's public syllabus
-- documents. The source PDFs are never stored here.
--
-- Additive only. RLS on with no policies, so only the service role reads or
-- writes (same pattern as 0002 / 0017). Idempotent: safe to re-run.

create table if not exists public.board_syllabus_nodes (
  id            uuid primary key,
  board         text not null check (board in ('CAMBRIDGE', 'IB')),
  stage         text not null,           -- 'IGCSE', 'AS & A Level', 'DP', ...
  grade_from    integer not null check (grade_from between 0 and 12),
  grade_to      integer not null check (grade_to between grade_from and 12),
  subject       text not null,
  code          text,                     -- board syllabus code, e.g. 0625
  version       text not null,            -- e.g. 0625-2026-2028
  year_from     integer,                  -- first / last exam year the syllabus covers
  year_to       integer,
  source_url    text,
  level         text not null check (level in ('UNIT', 'TOPIC')),
  parent_id     uuid references public.board_syllabus_nodes (id) on delete cascade,
  ordinal       integer not null,
  number_label  text,
  title         text not null,
  created_at    timestamptz not null default now()
);
create index if not exists board_syllabus_scope_idx
  on public.board_syllabus_nodes (board, grade_from, grade_to, subject);
create index if not exists board_syllabus_parent_idx on public.board_syllabus_nodes (parent_id);

alter table public.board_syllabus_nodes enable row level security;

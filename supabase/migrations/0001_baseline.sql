-- Aivorah baseline schema, extracted from production
-- source project: jwlepxmclbkrmfzrumch
-- generated: 2026-08-18T11:56:10.769Z

-- ============ EXTENSIONS ============
create extension if not exists "pg_stat_statements" with schema extensions;
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "supabase_vault" with schema vault;
create extension if not exists "uuid-ossp" with schema extensions;

-- ============ ENUM TYPES ============
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'curriculum_source_status') then
    create type "public"."curriculum_source_status" as enum ('REGISTERED', 'INGESTED', 'REJECTED');
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'curriculum_source_type') then
    create type "public"."curriculum_source_type" as enum ('OFFICIAL_SYLLABUS', 'LICENSED_TEXTBOOK', 'OER', 'AI_GENERATED');
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'resource_source_tier') then
    create type "public"."resource_source_tier" as enum ('OFFICIAL_BOOK', 'LICENSED_CONTENT', 'MAPPED_OER', 'ORIGINAL_AI', 'PLACEHOLDER');
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'resource_status') then
    create type "public"."resource_status" as enum ('READY', 'COMING_SOON', 'UNDER_REVIEW', 'NOT_AVAILABLE');
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'resource_type') then
    create type "public"."resource_type" as enum ('AI_EXPLANATION', 'IMAGES', 'AUDIO', 'PRACTICE', 'FLASHCARDS', 'WORKSHEETS', 'BOOK_REFERENCE', 'OER_MAPPING');
  end if;
end $$;

-- ============ SEQUENCES ============
create sequence if not exists "public"."challenge_questions_id_seq";

-- ============ TABLES ============
create table if not exists "public"."analytics_events" (
  "id" text not null,
  "event_type" text not null,
  "timestamp" timestamp with time zone default now(),
  "user_email" text,
  "role" text default ''::text,
  "source" text default ''::text,
  "page" text default ''::text,
  "path" text default ''::text,
  "status" text default ''::text,
  "latency_ms" integer,
  "model" text default ''::text,
  "topic" text default ''::text,
  "subject" text default ''::text,
  "grade" text default ''::text,
  "score" numeric,
  "comment" text default ''::text,
  "meta" jsonb default '{}'::jsonb
);
create table if not exists "public"."announcement_attachments" (
  "id" uuid default gen_random_uuid() not null,
  "announcement_id" uuid not null,
  "url" text not null,
  "file_name" text not null,
  "file_type" text not null,
  "file_size" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."announcement_targets" (
  "id" uuid default gen_random_uuid() not null,
  "announcement_id" uuid not null,
  "school_id" uuid,
  "role" text,
  "created_at" timestamp with time zone default now() not null,
  "teacher_id" uuid
);
create table if not exists "public"."announcement_user_state" (
  "announcement_id" uuid not null,
  "user_id" uuid not null,
  "seen_at" timestamp with time zone,
  "dismissed_at" timestamp with time zone,
  "dismissed_version" integer
);
create table if not exists "public"."announcements" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "body" text not null,
  "severity" text default 'info'::text not null,
  "display_type" text default 'banner'::text not null,
  "status" text default 'draft'::text not null,
  "starts_at" timestamp with time zone,
  "expires_at" timestamp with time zone,
  "is_dismissible" boolean default true not null,
  "content_version" integer default 1 not null,
  "created_by" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."assignment_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "assignment_id" uuid not null,
  "student_id" uuid not null,
  "status" text default 'completed'::text not null,
  "score" integer,
  "ai_feedback" text,
  "submission_text" text,
  "completed_at" timestamp with time zone default now(),
  "created_at" timestamp with time zone default now()
);
create table if not exists "public"."assignments" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "subject" text,
  "chapter" text,
  "due_date" date,
  "type" text,
  "note" text,
  "student_id" uuid,
  "created_by_id" uuid,
  "created_by_role" text,
  "status" text default 'pending'::text,
  "score" integer,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone default now(),
  "grade" text,
  "curriculum" text,
  "questions" jsonb default '[]'::jsonb,
  "submission_text" text,
  "submission_file_url" text,
  "ai_feedback" text,
  "ai_score" integer,
  "document_url" text,
  "document_urls" text[] default '{}'::text[],
  "success_criteria" text[] default '{}'::text[],
  "task_steps" jsonb default '[]'::jsonb,
  "quiz_questions" jsonb default '[]'::jsonb,
  "central_idea" text,
  "lines_of_inquiry" text[] default '{}'::text[],
  "learner_profile" text,
  "atl_skill" text,
  "key_concept" text,
  "interactive_quiz" jsonb,
  "interactive_quiz_html" text,
  "school" text,
  "created_by_name" text
);
create table if not exists "public"."branding_logos" (
  "kind" text not null,
  "name" text not null,
  "logo_url" text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."challenge_assignments" (
  "id" text not null,
  "challenge_id" text not null,
  "student_id" uuid not null,
  "assigned_by_id" text,
  "assigned_by_role" text,
  "due_date" date,
  "status" text default 'assigned'::text not null,
  "score" integer,
  "xp_awarded" integer,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."challenge_questions" (
  "id" bigint default nextval('challenge_questions_id_seq'::regclass) not null,
  "challenge_id" text not null,
  "question" text not null,
  "options" jsonb,
  "correct" integer,
  "explanation" text,
  "sort_order" integer default 0,
  "question_type" text default 'mcq'::text not null,
  "accept_answers" jsonb
);
create table if not exists "public"."challenges" (
  "id" text not null,
  "title" text not null,
  "description" text,
  "grade" text not null,
  "curriculum" text default 'IB PYP'::text not null,
  "subject" text,
  "topic" text,
  "difficulty" text default 'Medium'::text,
  "xp_reward" integer default 500,
  "question_count" integer default 10,
  "time_limit_minutes" integer default 20,
  "type" text default 'school_challenge'::text,
  "category" text default 'School Challenge'::text,
  "is_published" boolean default true,
  "created_by" uuid,
  "created_at" timestamp with time zone default now(),
  "updated_at" timestamp with time zone default now(),
  "thumbnail_url" text
);
create table if not exists "public"."chat_channel_members" (
  "id" uuid default gen_random_uuid() not null,
  "channel_id" uuid not null,
  "user_email" text not null,
  "role_label" text,
  "is_manager" boolean default false not null,
  "joined_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_channel_messages" (
  "id" uuid default gen_random_uuid() not null,
  "channel_id" uuid not null,
  "sender_email" text not null,
  "body" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_channel_reads" (
  "channel_id" uuid not null,
  "user_email" text not null,
  "last_read_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_channels" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "name" text not null,
  "category" text default 'class'::text not null,
  "grade" text,
  "section" text,
  "posting" text default 'members'::text not null,
  "icon_label" text,
  "created_by" text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."class_portfolio_attachments" (
  "id" uuid default gen_random_uuid() not null,
  "post_id" uuid not null,
  "url" text not null,
  "file_type" text not null,
  "file_name" text,
  "file_size" integer,
  "position" integer default 0 not null
);
create table if not exists "public"."class_portfolio_comments" (
  "id" uuid default gen_random_uuid() not null,
  "post_id" uuid not null,
  "user_id" uuid not null,
  "body" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."class_portfolio_folders" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "grade" text not null,
  "section" text default ''::text not null,
  "name" text not null,
  "color" text default '#0d9488'::text not null,
  "created_by" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."class_portfolio_likes" (
  "post_id" uuid not null,
  "user_id" uuid not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."class_portfolio_posts" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "grade" text not null,
  "section" text default ''::text not null,
  "caption" text default ''::text not null,
  "status" text default 'draft'::text not null,
  "created_by" text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "folder_id" uuid
);
create table if not exists "public"."class_portfolio_tags" (
  "id" uuid default gen_random_uuid() not null,
  "post_id" uuid not null,
  "student_id" uuid not null
);
create table if not exists "public"."class_timetables" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "grade" text not null,
  "section" text default ''::text not null,
  "title" text,
  "period_defs" jsonb default '[]'::jsonb not null,
  "updated_by" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."curriculum_sources" (
  "id" uuid default gen_random_uuid() not null,
  "curriculum" text not null,
  "grade" text not null,
  "subject" text,
  "source_type" curriculum_source_type not null,
  "title" text not null,
  "file_hash" text,
  "url" text,
  "license" text,
  "status" curriculum_source_status default 'REGISTERED'::curriculum_source_status not null,
  "registered_by" text,
  "registered_at" timestamp with time zone default now() not null,
  "ingested_at" timestamp with time zone
);
create table if not exists "public"."demo_requests" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "email" text not null,
  "school" text,
  "role" text,
  "team_size" text,
  "preferred_times" text,
  "message" text,
  "status" text default 'pending'::text not null,
  "confirm_token" text not null,
  "scheduled_at" timestamp with time zone,
  "duration_minutes" integer default 30,
  "meet_link" text,
  "calendar_event_id" text,
  "created_at" timestamp with time zone default now() not null,
  "confirmed_at" timestamp with time zone,
  "requested_slot" timestamp with time zone
);
create table if not exists "public"."habits_checkins" (
  "id" text default (gen_random_uuid())::text not null,
  "user_email" text not null,
  "habit_id" text not null,
  "date" text not null,
  "checked_at" timestamp with time zone default now()
);
create table if not exists "public"."import_runs" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "type" text not null,
  "file_name" text not null,
  "run_by_email" text not null,
  "imported_count" integer default 0 not null,
  "skipped_count" integer default 0 not null,
  "status" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."llm_logs" (
  "id" uuid default gen_random_uuid() not null,
  "created_at" timestamp with time zone default now(),
  "provider" text,
  "model" text,
  "route" text,
  "student_email" text,
  "grade" text,
  "subject" text,
  "topic" text,
  "prompt_tokens" integer,
  "completion_tokens" integer,
  "total_tokens" integer,
  "estimated_cost_usd" numeric(10,6),
  "response_time_ms" integer,
  "feedback" smallint,
  "streamed" boolean default false
);
create table if not exists "public"."message_reactions" (
  "id" uuid default gen_random_uuid() not null,
  "message_id" uuid not null,
  "user_email" text not null,
  "emoji" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."messages" (
  "id" uuid default gen_random_uuid() not null,
  "sender_email" text not null,
  "sender_name" text not null,
  "sender_role" text not null,
  "recipient_email" text not null,
  "recipient_name" text not null,
  "student_id" uuid,
  "student_name" text,
  "content" text not null,
  "created_at" timestamp with time zone default now(),
  "read_at" timestamp with time zone,
  "is_edited" boolean default false,
  "reply_to_id" uuid
);
create table if not exists "public"."otp_codes" (
  "email" text not null,
  "purpose" text not null,
  "otp" text not null,
  "recovery_email" text,
  "expires_at" timestamp with time zone not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."parent_children" (
  "id" uuid default gen_random_uuid() not null,
  "parent_email" text not null,
  "child_id" uuid not null,
  "added_at" timestamp with time zone default now()
);
create table if not exists "public"."parent_daily_tasks" (
  "id" uuid default gen_random_uuid() not null,
  "parent_email" text not null,
  "child_id" uuid not null,
  "label" text not null,
  "icon" text default 'check-circle'::text,
  "coins" integer default 5,
  "created_at" timestamp with time zone default now()
);
create table if not exists "public"."parent_student" (
  "parent_id" uuid not null,
  "student_id" uuid not null
);
create table if not exists "public"."resource_files" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "folder_id" uuid,
  "title" text not null,
  "file_url" text not null,
  "file_type" text,
  "file_size" bigint default 0,
  "scope" text default 'school'::text not null,
  "uploaded_by" text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."resource_folders" (
  "id" uuid default gen_random_uuid() not null,
  "school_id" uuid not null,
  "parent_folder_id" uuid,
  "name" text not null,
  "scope" text default 'school'::text not null,
  "created_by" text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."schedule_events" (
  "id" text not null,
  "title" text not null,
  "event_date" text not null,
  "start_time" text not null,
  "end_time" text default ''::text,
  "type" text default 'study'::text,
  "note" text default ''::text,
  "student_id" text not null,
  "created_by" text,
  "tag" text,
  "assignment_id" text,
  "created_at" timestamp with time zone default now(),
  "created_by_id" text
);
create table if not exists "public"."school_access_requests" (
  "id" uuid default gen_random_uuid() not null,
  "user_email" text not null,
  "school_id" uuid not null,
  "grade" text,
  "section" text,
  "status" text default 'pending'::text not null,
  "reviewed_by" text,
  "created_at" timestamp with time zone default now() not null,
  "reviewed_at" timestamp with time zone
);
create table if not exists "public"."schools" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "created_at" timestamp with time zone default now() not null,
  "curriculum" text,
  "academic_structure" jsonb,
  "academic_year" text,
  "contact_email" text
);
create table if not exists "public"."short_links" (
  "code" text not null,
  "url" text not null,
  "created_at" timestamp with time zone default now(),
  "expires_at" timestamp with time zone
);
create table if not exists "public"."student_daily_log" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid,
  "log_date" date not null,
  "study_minutes" integer default 0,
  "xp_earned" integer default 0,
  "topics_completed" integer default 0
);
create table if not exists "public"."student_preferences" (
  "user_email" text not null,
  "theme" text default 'dark'::text,
  "total_coins" integer default 0,
  "streak" integer default 0,
  "last_checkin_date" text default ''::text,
  "journal_text" text default ''::text,
  "updated_at" timestamp with time zone default now()
);
create table if not exists "public"."student_stats" (
  "student_id" uuid not null,
  "xp_points" integer default 0,
  "level" integer default 1,
  "study_time_minutes" integer default 0,
  "topics_explored" integer default 0,
  "challenges_completed" integer default 0,
  "assignments_done" integer default 0,
  "current_streak" integer default 0,
  "last_active_date" date,
  "today_study_minutes" integer default 0,
  "today_xp" integer default 0,
  "completed_topics" text[] default '{}'::text[],
  "last_lesson" text,
  "updated_at" timestamp with time zone default now(),
  "learning_path_minutes" integer default 0 not null,
  "assignment_time_minutes" integer default 0 not null,
  "challenge_time_minutes" integer default 0 not null
);
create table if not exists "public"."student_subject_time" (
  "student_id" uuid not null,
  "subject" text not null,
  "minutes" integer default 0 not null,
  "updated_at" timestamp with time zone default now() not null,
  "today_minutes" integer default 0 not null,
  "today_date" date
);
create table if not exists "public"."syllabus_chapters" (
  "id" uuid default gen_random_uuid() not null,
  "grade" text not null,
  "subject" text not null,
  "curriculum" text default 'CBSE'::text not null,
  "school_id" uuid,
  "unit_no" integer not null,
  "title" text not null,
  "created_at" timestamp with time zone default now()
);
create table if not exists "public"."syllabus_extraction_jobs" (
  "id" uuid default gen_random_uuid() not null,
  "file_hash" text not null,
  "grade" text not null,
  "subject" text not null,
  "curriculum" text default 'CBSE'::text not null,
  "status" text default 'complete'::text not null,
  "canonical" jsonb not null,
  "overall_confidence" integer,
  "error" text,
  "created_at" timestamp with time zone default now()
);
create table if not exists "public"."syllabus_topics" (
  "id" uuid default gen_random_uuid() not null,
  "chapter_id" uuid,
  "topic_order" integer default 0 not null,
  "name" text not null,
  "kind" text default 'Story'::text,
  "page" text,
  "intro" text,
  "body" jsonb default '[]'::jsonb,
  "vocab" jsonb default '[]'::jsonb,
  "activity" text,
  "figure_url" text,
  "created_at" timestamp with time zone default now(),
  "key_concepts" text[],
  "summary" text,
  "reflection_question" text,
  "content_origin" text default 'official_textbook'::text
);
create table if not exists "public"."teacher_student" (
  "teacher_id" uuid not null,
  "student_id" uuid not null,
  "subject" text not null
);
create table if not exists "public"."teacher_students" (
  "id" uuid default gen_random_uuid() not null,
  "teacher_id" uuid not null,
  "student_id" uuid not null,
  "section" text,
  "added_at" timestamp with time zone default now()
);
create table if not exists "public"."timetable_slots" (
  "id" uuid default gen_random_uuid() not null,
  "timetable_id" uuid not null,
  "day_of_week" text not null,
  "period_code" text not null,
  "subject_name" text,
  "room_name" text,
  "teacher_id" uuid,
  "material_url" text,
  "material_name" text,
  "updated_by" text,
  "updated_at" timestamp with time zone default now() not null,
  "color" text
);
create table if not exists "public"."topic_attempts" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "topic" text not null,
  "subject" text not null,
  "grade" text not null,
  "curriculum" text default ''::text,
  "attempt_number" integer default 1 not null,
  "total_questions" integer not null,
  "correct_answers" integer not null,
  "score" numeric(5,2) not null,
  "passed" boolean default false not null,
  "time_spent_seconds" integer default 0,
  "per_question_results" jsonb default '[]'::jsonb,
  "created_at" timestamp with time zone default now()
);
create table if not exists "public"."topic_resources" (
  "id" uuid default gen_random_uuid() not null,
  "topic_id" uuid not null,
  "resource_type" resource_type not null,
  "status" resource_status default 'NOT_AVAILABLE'::resource_status not null,
  "source_tier" resource_source_tier,
  "source" text,
  "qdrant_point_ids" text[],
  "static_payload" jsonb,
  "attribution" text,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."upload_jobs" (
  "id" text not null,
  "type" text not null,
  "status" text default 'pending'::text not null,
  "payload" jsonb default '{}'::jsonb not null,
  "result" jsonb,
  "error" text,
  "locked_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."user_preferences" (
  "user_email" text not null,
  "data" jsonb default '{}'::jsonb,
  "updated_at" timestamp with time zone default now()
);
create table if not exists "public"."users" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "email" text not null,
  "role" text,
  "grade" text,
  "school" text,
  "created_at" timestamp with time zone default now(),
  "curriculum" text,
  "location" text,
  "onboarding_complete" boolean default false,
  "photo_url" text,
  "phone" text,
  "section" text,
  "school_id" uuid,
  "status" text default 'active'::text not null,
  "admission_number" text,
  "last_active_at" timestamp with time zone,
  "admin_notes" text
);
create table if not exists "public"."videos" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "topic" text,
  "grade" text,
  "url" text,
  "embed_url" text,
  "description" text,
  "source" text,
  "created_at" timestamp with time zone default now()
);

-- ============ CONSTRAINTS ============
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'analytics_events' and con.conname = 'analytics_events_pkey') then
    alter table "public"."analytics_events" add constraint "analytics_events_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_attachments' and con.conname = 'announcement_attachments_pkey') then
    alter table "public"."announcement_attachments" add constraint "announcement_attachments_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_targets' and con.conname = 'announcement_targets_pkey') then
    alter table "public"."announcement_targets" add constraint "announcement_targets_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_user_state' and con.conname = 'announcement_user_state_pkey') then
    alter table "public"."announcement_user_state" add constraint "announcement_user_state_pkey" PRIMARY KEY (announcement_id, user_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcements' and con.conname = 'announcements_pkey') then
    alter table "public"."announcements" add constraint "announcements_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignment_submissions' and con.conname = 'assignment_submissions_pkey') then
    alter table "public"."assignment_submissions" add constraint "assignment_submissions_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_pkey') then
    alter table "public"."assignments" add constraint "assignments_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'branding_logos' and con.conname = 'branding_logos_pkey') then
    alter table "public"."branding_logos" add constraint "branding_logos_pkey" PRIMARY KEY (kind, name);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_assignments' and con.conname = 'challenge_assignments_pkey') then
    alter table "public"."challenge_assignments" add constraint "challenge_assignments_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_questions' and con.conname = 'challenge_questions_pkey') then
    alter table "public"."challenge_questions" add constraint "challenge_questions_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenges' and con.conname = 'challenges_pkey') then
    alter table "public"."challenges" add constraint "challenges_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_members' and con.conname = 'chat_channel_members_pkey') then
    alter table "public"."chat_channel_members" add constraint "chat_channel_members_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_messages' and con.conname = 'chat_channel_messages_pkey') then
    alter table "public"."chat_channel_messages" add constraint "chat_channel_messages_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_reads' and con.conname = 'chat_channel_reads_pkey') then
    alter table "public"."chat_channel_reads" add constraint "chat_channel_reads_pkey" PRIMARY KEY (channel_id, user_email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channels' and con.conname = 'chat_channels_pkey') then
    alter table "public"."chat_channels" add constraint "chat_channels_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_attachments' and con.conname = 'class_portfolio_attachments_pkey') then
    alter table "public"."class_portfolio_attachments" add constraint "class_portfolio_attachments_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_comments' and con.conname = 'class_portfolio_comments_pkey') then
    alter table "public"."class_portfolio_comments" add constraint "class_portfolio_comments_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_folders' and con.conname = 'class_portfolio_folders_pkey') then
    alter table "public"."class_portfolio_folders" add constraint "class_portfolio_folders_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_likes' and con.conname = 'class_portfolio_likes_pkey') then
    alter table "public"."class_portfolio_likes" add constraint "class_portfolio_likes_pkey" PRIMARY KEY (post_id, user_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_posts' and con.conname = 'class_portfolio_posts_pkey') then
    alter table "public"."class_portfolio_posts" add constraint "class_portfolio_posts_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_tags' and con.conname = 'class_portfolio_tags_pkey') then
    alter table "public"."class_portfolio_tags" add constraint "class_portfolio_tags_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_timetables' and con.conname = 'class_timetables_pkey') then
    alter table "public"."class_timetables" add constraint "class_timetables_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'curriculum_sources' and con.conname = 'curriculum_sources_pkey') then
    alter table "public"."curriculum_sources" add constraint "curriculum_sources_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'demo_requests' and con.conname = 'demo_requests_pkey') then
    alter table "public"."demo_requests" add constraint "demo_requests_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'habits_checkins' and con.conname = 'habits_checkins_pkey') then
    alter table "public"."habits_checkins" add constraint "habits_checkins_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'import_runs' and con.conname = 'import_runs_pkey') then
    alter table "public"."import_runs" add constraint "import_runs_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'llm_logs' and con.conname = 'llm_logs_pkey') then
    alter table "public"."llm_logs" add constraint "llm_logs_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'message_reactions' and con.conname = 'message_reactions_pkey') then
    alter table "public"."message_reactions" add constraint "message_reactions_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'messages' and con.conname = 'messages_pkey') then
    alter table "public"."messages" add constraint "messages_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'otp_codes' and con.conname = 'otp_codes_pkey') then
    alter table "public"."otp_codes" add constraint "otp_codes_pkey" PRIMARY KEY (email, purpose);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_children' and con.conname = 'parent_children_pkey') then
    alter table "public"."parent_children" add constraint "parent_children_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_daily_tasks' and con.conname = 'parent_daily_tasks_pkey') then
    alter table "public"."parent_daily_tasks" add constraint "parent_daily_tasks_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_student' and con.conname = 'parent_student_pkey') then
    alter table "public"."parent_student" add constraint "parent_student_pkey" PRIMARY KEY (parent_id, student_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_files' and con.conname = 'resource_files_pkey') then
    alter table "public"."resource_files" add constraint "resource_files_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_folders' and con.conname = 'resource_folders_pkey') then
    alter table "public"."resource_folders" add constraint "resource_folders_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'schedule_events' and con.conname = 'schedule_events_pkey') then
    alter table "public"."schedule_events" add constraint "schedule_events_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'school_access_requests' and con.conname = 'school_access_requests_pkey') then
    alter table "public"."school_access_requests" add constraint "school_access_requests_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'schools' and con.conname = 'schools_pkey') then
    alter table "public"."schools" add constraint "schools_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'short_links' and con.conname = 'short_links_pkey') then
    alter table "public"."short_links" add constraint "short_links_pkey" PRIMARY KEY (code);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_daily_log' and con.conname = 'student_daily_log_pkey') then
    alter table "public"."student_daily_log" add constraint "student_daily_log_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_preferences' and con.conname = 'student_preferences_pkey') then
    alter table "public"."student_preferences" add constraint "student_preferences_pkey" PRIMARY KEY (user_email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_stats' and con.conname = 'student_stats_pkey') then
    alter table "public"."student_stats" add constraint "student_stats_pkey" PRIMARY KEY (student_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_subject_time' and con.conname = 'student_subject_time_pkey') then
    alter table "public"."student_subject_time" add constraint "student_subject_time_pkey" PRIMARY KEY (student_id, subject);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'syllabus_chapters' and con.conname = 'syllabus_chapters_pkey') then
    alter table "public"."syllabus_chapters" add constraint "syllabus_chapters_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'syllabus_extraction_jobs' and con.conname = 'syllabus_extraction_jobs_pkey') then
    alter table "public"."syllabus_extraction_jobs" add constraint "syllabus_extraction_jobs_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'syllabus_topics' and con.conname = 'syllabus_topics_pkey') then
    alter table "public"."syllabus_topics" add constraint "syllabus_topics_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_student' and con.conname = 'teacher_student_pkey') then
    alter table "public"."teacher_student" add constraint "teacher_student_pkey" PRIMARY KEY (teacher_id, student_id, subject);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_students' and con.conname = 'teacher_students_pkey') then
    alter table "public"."teacher_students" add constraint "teacher_students_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'timetable_slots' and con.conname = 'timetable_slots_pkey') then
    alter table "public"."timetable_slots" add constraint "timetable_slots_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'topic_attempts' and con.conname = 'topic_attempts_pkey') then
    alter table "public"."topic_attempts" add constraint "topic_attempts_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'topic_resources' and con.conname = 'topic_resources_pkey') then
    alter table "public"."topic_resources" add constraint "topic_resources_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'upload_jobs' and con.conname = 'upload_jobs_pkey') then
    alter table "public"."upload_jobs" add constraint "upload_jobs_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'user_preferences' and con.conname = 'user_preferences_pkey') then
    alter table "public"."user_preferences" add constraint "user_preferences_pkey" PRIMARY KEY (user_email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'users' and con.conname = 'users_pkey') then
    alter table "public"."users" add constraint "users_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'videos' and con.conname = 'videos_pkey') then
    alter table "public"."videos" add constraint "videos_pkey" PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignment_submissions' and con.conname = 'assignment_submissions_assignment_id_student_id_key') then
    alter table "public"."assignment_submissions" add constraint "assignment_submissions_assignment_id_student_id_key" UNIQUE (assignment_id, student_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_members' and con.conname = 'chat_channel_members_channel_id_user_email_key') then
    alter table "public"."chat_channel_members" add constraint "chat_channel_members_channel_id_user_email_key" UNIQUE (channel_id, user_email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_folders' and con.conname = 'class_portfolio_folders_school_id_grade_section_name_key') then
    alter table "public"."class_portfolio_folders" add constraint "class_portfolio_folders_school_id_grade_section_name_key" UNIQUE (school_id, grade, section, name);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_timetables' and con.conname = 'class_timetables_school_id_grade_section_key') then
    alter table "public"."class_timetables" add constraint "class_timetables_school_id_grade_section_key" UNIQUE (school_id, grade, section);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'demo_requests' and con.conname = 'demo_requests_confirm_token_key') then
    alter table "public"."demo_requests" add constraint "demo_requests_confirm_token_key" UNIQUE (confirm_token);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'habits_checkins' and con.conname = 'habits_checkins_user_email_habit_id_date_key') then
    alter table "public"."habits_checkins" add constraint "habits_checkins_user_email_habit_id_date_key" UNIQUE (user_email, habit_id, date);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'message_reactions' and con.conname = 'message_reactions_message_id_user_email_key') then
    alter table "public"."message_reactions" add constraint "message_reactions_message_id_user_email_key" UNIQUE (message_id, user_email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_children' and con.conname = 'parent_children_parent_email_child_id_key') then
    alter table "public"."parent_children" add constraint "parent_children_parent_email_child_id_key" UNIQUE (parent_email, child_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'school_access_requests' and con.conname = 'school_access_requests_user_email_school_id_status_key') then
    alter table "public"."school_access_requests" add constraint "school_access_requests_user_email_school_id_status_key" UNIQUE (user_email, school_id, status);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_daily_log' and con.conname = 'student_daily_log_student_id_log_date_key') then
    alter table "public"."student_daily_log" add constraint "student_daily_log_student_id_log_date_key" UNIQUE (student_id, log_date);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_students' and con.conname = 'teacher_students_teacher_id_student_id_key') then
    alter table "public"."teacher_students" add constraint "teacher_students_teacher_id_student_id_key" UNIQUE (teacher_id, student_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'timetable_slots' and con.conname = 'timetable_slots_timetable_id_day_of_week_period_code_key') then
    alter table "public"."timetable_slots" add constraint "timetable_slots_timetable_id_day_of_week_period_code_key" UNIQUE (timetable_id, day_of_week, period_code);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'topic_resources' and con.conname = 'topic_resources_topic_id_resource_type_key') then
    alter table "public"."topic_resources" add constraint "topic_resources_topic_id_resource_type_key" UNIQUE (topic_id, resource_type);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'users' and con.conname = 'users_email_key') then
    alter table "public"."users" add constraint "users_email_key" UNIQUE (email);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_targets' and con.conname = 'announcement_targets_role_check') then
    alter table "public"."announcement_targets" add constraint "announcement_targets_role_check" CHECK ((role = ANY (ARRAY['student'::text, 'parent'::text, 'teacher'::text, 'school_admin'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcements' and con.conname = 'announcements_status_check') then
    alter table "public"."announcements" add constraint "announcements_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'published'::text, 'archived'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcements' and con.conname = 'announcements_severity_check') then
    alter table "public"."announcements" add constraint "announcements_severity_check" CHECK ((severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcements' and con.conname = 'announcements_display_type_check') then
    alter table "public"."announcements" add constraint "announcements_display_type_check" CHECK ((display_type = ANY (ARRAY['banner'::text, 'inbox'::text, 'both'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_status_check') then
    alter table "public"."assignments" add constraint "assignments_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_created_by_role_check') then
    alter table "public"."assignments" add constraint "assignments_created_by_role_check" CHECK ((created_by_role = ANY (ARRAY['teacher'::text, 'parent'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_type_check') then
    alter table "public"."assignments" add constraint "assignments_type_check" CHECK ((type = ANY (ARRAY['assignment'::text, 'quiz'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_assignments' and con.conname = 'challenge_assignments_status_check') then
    alter table "public"."challenge_assignments" add constraint "challenge_assignments_status_check" CHECK ((status = ANY (ARRAY['assigned'::text, 'completed'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_assignments' and con.conname = 'challenge_assignments_assigned_by_role_check') then
    alter table "public"."challenge_assignments" add constraint "challenge_assignments_assigned_by_role_check" CHECK ((assigned_by_role = ANY (ARRAY['teacher'::text, 'parent'::text, 'student'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_questions' and con.conname = 'challenge_questions_question_type_check') then
    alter table "public"."challenge_questions" add constraint "challenge_questions_question_type_check" CHECK ((question_type = ANY (ARRAY['mcq'::text, 'fill_blank'::text, 'open_ended'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenges' and con.conname = 'challenges_difficulty_check') then
    alter table "public"."challenges" add constraint "challenges_difficulty_check" CHECK ((difficulty = ANY (ARRAY['Easy'::text, 'Medium'::text, 'Hard'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_attachments' and con.conname = 'class_portfolio_attachments_file_type_check') then
    alter table "public"."class_portfolio_attachments" add constraint "class_portfolio_attachments_file_type_check" CHECK ((file_type = ANY (ARRAY['image'::text, 'video'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_posts' and con.conname = 'class_portfolio_posts_status_check') then
    alter table "public"."class_portfolio_posts" add constraint "class_portfolio_posts_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'import_runs' and con.conname = 'import_runs_type_check') then
    alter table "public"."import_runs" add constraint "import_runs_type_check" CHECK ((type = ANY (ARRAY['students'::text, 'teachers'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'messages' and con.conname = 'messages_sender_role_check') then
    alter table "public"."messages" add constraint "messages_sender_role_check" CHECK ((sender_role = ANY (ARRAY['teacher'::text, 'parent'::text, 'school_admin'::text, 'super_admin'::text, 'student'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'syllabus_topics' and con.conname = 'syllabus_topics_content_origin_check') then
    alter table "public"."syllabus_topics" add constraint "syllabus_topics_content_origin_check" CHECK ((content_origin = ANY (ARRAY['official_textbook'::text, 'licensed'::text, 'oer'::text, 'ai_generated'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'users' and con.conname = 'users_role_check') then
    alter table "public"."users" add constraint "users_role_check" CHECK ((role = ANY (ARRAY['student'::text, 'parent'::text, 'teacher'::text, 'school_admin'::text, 'super_admin'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'users' and con.conname = 'users_status_check') then
    alter table "public"."users" add constraint "users_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_attachments' and con.conname = 'announcement_attachments_announcement_id_fkey') then
    alter table "public"."announcement_attachments" add constraint "announcement_attachments_announcement_id_fkey" FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_targets' and con.conname = 'announcement_targets_announcement_id_fkey') then
    alter table "public"."announcement_targets" add constraint "announcement_targets_announcement_id_fkey" FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_targets' and con.conname = 'announcement_targets_school_id_fkey') then
    alter table "public"."announcement_targets" add constraint "announcement_targets_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_targets' and con.conname = 'announcement_targets_teacher_id_fkey') then
    alter table "public"."announcement_targets" add constraint "announcement_targets_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES users(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_user_state' and con.conname = 'announcement_user_state_announcement_id_fkey') then
    alter table "public"."announcement_user_state" add constraint "announcement_user_state_announcement_id_fkey" FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'announcement_user_state' and con.conname = 'announcement_user_state_user_id_fkey') then
    alter table "public"."announcement_user_state" add constraint "announcement_user_state_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignment_submissions' and con.conname = 'assignment_submissions_assignment_id_fkey') then
    alter table "public"."assignment_submissions" add constraint "assignment_submissions_assignment_id_fkey" FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignment_submissions' and con.conname = 'assignment_submissions_student_id_fkey') then
    alter table "public"."assignment_submissions" add constraint "assignment_submissions_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_created_by_id_fkey') then
    alter table "public"."assignments" add constraint "assignments_created_by_id_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'assignments' and con.conname = 'assignments_student_id_fkey') then
    alter table "public"."assignments" add constraint "assignments_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_assignments' and con.conname = 'challenge_assignments_student_id_fkey') then
    alter table "public"."challenge_assignments" add constraint "challenge_assignments_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenge_questions' and con.conname = 'challenge_questions_challenge_id_fkey') then
    alter table "public"."challenge_questions" add constraint "challenge_questions_challenge_id_fkey" FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'challenges' and con.conname = 'challenges_created_by_fkey') then
    alter table "public"."challenges" add constraint "challenges_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_members' and con.conname = 'chat_channel_members_channel_id_fkey') then
    alter table "public"."chat_channel_members" add constraint "chat_channel_members_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES chat_channels(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_messages' and con.conname = 'chat_channel_messages_channel_id_fkey') then
    alter table "public"."chat_channel_messages" add constraint "chat_channel_messages_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES chat_channels(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channel_reads' and con.conname = 'chat_channel_reads_channel_id_fkey') then
    alter table "public"."chat_channel_reads" add constraint "chat_channel_reads_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES chat_channels(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'chat_channels' and con.conname = 'chat_channels_school_id_fkey') then
    alter table "public"."chat_channels" add constraint "chat_channels_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_attachments' and con.conname = 'class_portfolio_attachments_post_id_fkey') then
    alter table "public"."class_portfolio_attachments" add constraint "class_portfolio_attachments_post_id_fkey" FOREIGN KEY (post_id) REFERENCES class_portfolio_posts(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_comments' and con.conname = 'class_portfolio_comments_user_id_fkey') then
    alter table "public"."class_portfolio_comments" add constraint "class_portfolio_comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_comments' and con.conname = 'class_portfolio_comments_post_id_fkey') then
    alter table "public"."class_portfolio_comments" add constraint "class_portfolio_comments_post_id_fkey" FOREIGN KEY (post_id) REFERENCES class_portfolio_posts(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_folders' and con.conname = 'class_portfolio_folders_school_id_fkey') then
    alter table "public"."class_portfolio_folders" add constraint "class_portfolio_folders_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_likes' and con.conname = 'class_portfolio_likes_post_id_fkey') then
    alter table "public"."class_portfolio_likes" add constraint "class_portfolio_likes_post_id_fkey" FOREIGN KEY (post_id) REFERENCES class_portfolio_posts(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_likes' and con.conname = 'class_portfolio_likes_user_id_fkey') then
    alter table "public"."class_portfolio_likes" add constraint "class_portfolio_likes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_posts' and con.conname = 'class_portfolio_posts_school_id_fkey') then
    alter table "public"."class_portfolio_posts" add constraint "class_portfolio_posts_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_posts' and con.conname = 'class_portfolio_posts_folder_id_fkey') then
    alter table "public"."class_portfolio_posts" add constraint "class_portfolio_posts_folder_id_fkey" FOREIGN KEY (folder_id) REFERENCES class_portfolio_folders(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_tags' and con.conname = 'class_portfolio_tags_student_id_fkey') then
    alter table "public"."class_portfolio_tags" add constraint "class_portfolio_tags_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_portfolio_tags' and con.conname = 'class_portfolio_tags_post_id_fkey') then
    alter table "public"."class_portfolio_tags" add constraint "class_portfolio_tags_post_id_fkey" FOREIGN KEY (post_id) REFERENCES class_portfolio_posts(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'class_timetables' and con.conname = 'class_timetables_school_id_fkey') then
    alter table "public"."class_timetables" add constraint "class_timetables_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'import_runs' and con.conname = 'import_runs_school_id_fkey') then
    alter table "public"."import_runs" add constraint "import_runs_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'message_reactions' and con.conname = 'message_reactions_message_id_fkey') then
    alter table "public"."message_reactions" add constraint "message_reactions_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'messages' and con.conname = 'messages_reply_to_id_fkey') then
    alter table "public"."messages" add constraint "messages_reply_to_id_fkey" FOREIGN KEY (reply_to_id) REFERENCES messages(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'messages' and con.conname = 'messages_student_id_fkey') then
    alter table "public"."messages" add constraint "messages_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_children' and con.conname = 'parent_children_child_id_fkey') then
    alter table "public"."parent_children" add constraint "parent_children_child_id_fkey" FOREIGN KEY (child_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_daily_tasks' and con.conname = 'parent_daily_tasks_child_id_fkey') then
    alter table "public"."parent_daily_tasks" add constraint "parent_daily_tasks_child_id_fkey" FOREIGN KEY (child_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_student' and con.conname = 'parent_student_student_id_fkey') then
    alter table "public"."parent_student" add constraint "parent_student_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'parent_student' and con.conname = 'parent_student_parent_id_fkey') then
    alter table "public"."parent_student" add constraint "parent_student_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_files' and con.conname = 'resource_files_school_id_fkey') then
    alter table "public"."resource_files" add constraint "resource_files_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_files' and con.conname = 'resource_files_folder_id_fkey') then
    alter table "public"."resource_files" add constraint "resource_files_folder_id_fkey" FOREIGN KEY (folder_id) REFERENCES resource_folders(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_folders' and con.conname = 'resource_folders_school_id_fkey') then
    alter table "public"."resource_folders" add constraint "resource_folders_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'resource_folders' and con.conname = 'resource_folders_parent_folder_id_fkey') then
    alter table "public"."resource_folders" add constraint "resource_folders_parent_folder_id_fkey" FOREIGN KEY (parent_folder_id) REFERENCES resource_folders(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'school_access_requests' and con.conname = 'school_access_requests_school_id_fkey') then
    alter table "public"."school_access_requests" add constraint "school_access_requests_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_daily_log' and con.conname = 'student_daily_log_student_id_fkey') then
    alter table "public"."student_daily_log" add constraint "student_daily_log_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'student_stats' and con.conname = 'student_stats_student_id_fkey') then
    alter table "public"."student_stats" add constraint "student_stats_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'syllabus_topics' and con.conname = 'syllabus_topics_chapter_id_fkey') then
    alter table "public"."syllabus_topics" add constraint "syllabus_topics_chapter_id_fkey" FOREIGN KEY (chapter_id) REFERENCES syllabus_chapters(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_student' and con.conname = 'teacher_student_student_id_fkey') then
    alter table "public"."teacher_student" add constraint "teacher_student_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_student' and con.conname = 'teacher_student_teacher_id_fkey') then
    alter table "public"."teacher_student" add constraint "teacher_student_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_students' and con.conname = 'teacher_students_student_id_fkey') then
    alter table "public"."teacher_students" add constraint "teacher_students_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'teacher_students' and con.conname = 'teacher_students_teacher_id_fkey') then
    alter table "public"."teacher_students" add constraint "teacher_students_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'timetable_slots' and con.conname = 'timetable_slots_teacher_id_fkey') then
    alter table "public"."timetable_slots" add constraint "timetable_slots_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'timetable_slots' and con.conname = 'timetable_slots_timetable_id_fkey') then
    alter table "public"."timetable_slots" add constraint "timetable_slots_timetable_id_fkey" FOREIGN KEY (timetable_id) REFERENCES class_timetables(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'topic_attempts' and con.conname = 'topic_attempts_student_id_fkey') then
    alter table "public"."topic_attempts" add constraint "topic_attempts_student_id_fkey" FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'topic_resources' and con.conname = 'topic_resources_topic_id_fkey') then
    alter table "public"."topic_resources" add constraint "topic_resources_topic_id_fkey" FOREIGN KEY (topic_id) REFERENCES syllabus_topics(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint con
                 join pg_class r on r.oid = con.conrelid
                 join pg_namespace n on n.oid = r.relnamespace
                 where n.nspname = 'public' and r.relname = 'users' and con.conname = 'users_school_id_fkey') then
    alter table "public"."users" add constraint "users_school_id_fkey" FOREIGN KEY (school_id) REFERENCES schools(id);
  end if;
end $$;

-- ============ INDEXES ============
CREATE INDEX IF NOT EXISTS announcement_attachments_announcement_idx ON public.announcement_attachments USING btree (announcement_id);
CREATE INDEX IF NOT EXISTS announcement_targets_announcement_idx ON public.announcement_targets USING btree (announcement_id);
CREATE INDEX IF NOT EXISTS announcement_targets_school_role_idx ON public.announcement_targets USING btree (school_id, role);
CREATE INDEX IF NOT EXISTS announcement_targets_teacher_idx ON public.announcement_targets USING btree (teacher_id);
CREATE INDEX IF NOT EXISTS announcement_user_state_user_idx ON public.announcement_user_state USING btree (user_id, announcement_id);
CREATE INDEX IF NOT EXISTS announcements_status_window_idx ON public.announcements USING btree (status, starts_at, expires_at);
CREATE INDEX IF NOT EXISTS chat_members_user_idx ON public.chat_channel_members USING btree (user_email);
CREATE INDEX IF NOT EXISTS chat_messages_channel_idx ON public.chat_channel_messages USING btree (channel_id, created_at);
CREATE INDEX IF NOT EXISTS class_portfolio_attachments_post_idx ON public.class_portfolio_attachments USING btree (post_id);
CREATE INDEX IF NOT EXISTS class_portfolio_comments_post_idx ON public.class_portfolio_comments USING btree (post_id, created_at);
CREATE INDEX IF NOT EXISTS class_portfolio_posts_class_idx ON public.class_portfolio_posts USING btree (school_id, grade, section, status);
CREATE INDEX IF NOT EXISTS class_portfolio_tags_post_idx ON public.class_portfolio_tags USING btree (post_id);
CREATE INDEX IF NOT EXISTS class_portfolio_tags_student_idx ON public.class_portfolio_tags USING btree (student_id);
CREATE INDEX IF NOT EXISTS demo_requests_status_idx ON public.demo_requests USING btree (status);
CREATE INDEX IF NOT EXISTS demo_requests_token_idx ON public.demo_requests USING btree (confirm_token);
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON public.analytics_events USING btree (event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON public.analytics_events USING btree ("timestamp" DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_user_email ON public.analytics_events USING btree (user_email);
CREATE INDEX IF NOT EXISTS idx_asgn_sub_assignment ON public.assignment_submissions USING btree (assignment_id);
CREATE INDEX IF NOT EXISTS idx_asgn_sub_student ON public.assignment_submissions USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_assignments_created_by_id ON public.assignments USING btree (created_by_id);
CREATE INDEX IF NOT EXISTS idx_assignments_student_id ON public.assignments USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_challenge_assignments_challenge ON public.challenge_assignments USING btree (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_assignments_student ON public.challenge_assignments USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_challenge_questions_challenge_id ON public.challenge_questions USING btree (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenges_created_by ON public.challenges USING btree (created_by);
CREATE INDEX IF NOT EXISTS idx_challenges_grade ON public.challenges USING btree (grade);
CREATE INDEX IF NOT EXISTS idx_challenges_type ON public.challenges USING btree (type);
CREATE INDEX IF NOT EXISTS idx_curriculum_sources_scope ON public.curriculum_sources USING btree (curriculum, grade, subject);
CREATE UNIQUE INDEX IF NOT EXISTS idx_extraction_job_cache ON public.syllabus_extraction_jobs USING btree (file_hash, grade, subject, curriculum);
CREATE INDEX IF NOT EXISTS idx_habits_checkins_email ON public.habits_checkins USING btree (user_email);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON public.message_reactions USING btree (message_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON public.messages USING btree (recipient_email);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON public.messages USING btree (reply_to_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages USING btree (sender_email);
CREATE INDEX IF NOT EXISTS idx_messages_student_id ON public.messages USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_parent_children_child_id ON public.parent_children USING btree (child_id);
CREATE INDEX IF NOT EXISTS idx_parent_children_email ON public.parent_children USING btree (parent_email);
CREATE INDEX IF NOT EXISTS idx_parent_daily_tasks_child_id ON public.parent_daily_tasks USING btree (child_id);
CREATE INDEX IF NOT EXISTS idx_parent_student_student_id ON public.parent_student USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_syllabus_chapters_lookup ON public.syllabus_chapters USING btree (grade, subject, curriculum, school_id);
CREATE INDEX IF NOT EXISTS idx_syllabus_topics_chapter ON public.syllabus_topics USING btree (chapter_id);
CREATE INDEX IF NOT EXISTS idx_teacher_student_student_id ON public.teacher_student USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_teacher_students_student ON public.teacher_students USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_teacher_students_teacher ON public.teacher_students USING btree (teacher_id);
CREATE INDEX IF NOT EXISTS idx_topic_attempts_created ON public.topic_attempts USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_topic_attempts_student ON public.topic_attempts USING btree (student_id);
CREATE INDEX IF NOT EXISTS idx_topic_attempts_student_topic ON public.topic_attempts USING btree (student_id, topic);
CREATE INDEX IF NOT EXISTS idx_topic_resources_status ON public.topic_resources USING btree (status);
CREATE INDEX IF NOT EXISTS idx_topic_resources_topic ON public.topic_resources USING btree (topic_id);
CREATE INDEX IF NOT EXISTS import_runs_school_id_idx ON public.import_runs USING btree (school_id, created_at DESC);
CREATE INDEX IF NOT EXISTS llm_logs_created_at_idx ON public.llm_logs USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS llm_logs_route_idx ON public.llm_logs USING btree (route);
CREATE INDEX IF NOT EXISTS llm_logs_student_email_idx ON public.llm_logs USING btree (student_email);
CREATE INDEX IF NOT EXISTS otp_codes_expires_idx ON public.otp_codes USING btree (expires_at);
CREATE INDEX IF NOT EXISTS resource_files_folder_idx ON public.resource_files USING btree (school_id, folder_id);
CREATE INDEX IF NOT EXISTS resource_folders_school_idx ON public.resource_folders USING btree (school_id, parent_folder_id);
CREATE INDEX IF NOT EXISTS sar_school_status_idx ON public.school_access_requests USING btree (school_id, status);
CREATE INDEX IF NOT EXISTS sar_user_idx ON public.school_access_requests USING btree (user_email);
CREATE UNIQUE INDEX IF NOT EXISTS schools_name_lower_idx ON public.schools USING btree (lower(TRIM(BOTH FROM name)));
CREATE INDEX IF NOT EXISTS timetable_slots_tt_idx ON public.timetable_slots USING btree (timetable_id);
CREATE INDEX IF NOT EXISTS upload_jobs_status_idx ON public.upload_jobs USING btree (status, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS users_admission_number_idx ON public.users USING btree (admission_number) WHERE (admission_number IS NOT NULL);
CREATE INDEX IF NOT EXISTS users_school_id_idx ON public.users USING btree (school_id);

-- ============ FUNCTIONS ============
CREATE OR REPLACE FUNCTION public.increment_student_study_time(p_student_id uuid, p_minutes integer, p_source text, p_today date)
 RETURNS student_stats
 LANGUAGE plpgsql
AS $function$
DECLARE
  result student_stats;
BEGIN
  INSERT INTO student_stats (student_id, study_time_minutes, today_study_minutes, learning_path_minutes, assignment_time_minutes, challenge_time_minutes, last_active_date, updated_at)
  VALUES (
    p_student_id, p_minutes, p_minutes,
    CASE WHEN p_source = 'learningPath' THEN p_minutes ELSE 0 END,
    CASE WHEN p_source = 'assignment' THEN p_minutes ELSE 0 END,
    CASE WHEN p_source = 'challenge' THEN p_minutes ELSE 0 END,
    p_today, now()
  )
  ON CONFLICT (student_id) DO UPDATE SET
    study_time_minutes = COALESCE(student_stats.study_time_minutes, 0) + p_minutes,
    today_study_minutes = CASE
      WHEN student_stats.last_active_date = p_today THEN COALESCE(student_stats.today_study_minutes, 0) + p_minutes
      ELSE p_minutes
    END,
    learning_path_minutes = COALESCE(student_stats.learning_path_minutes, 0) + (CASE WHEN p_source = 'learningPath' THEN p_minutes ELSE 0 END),
    assignment_time_minutes = COALESCE(student_stats.assignment_time_minutes, 0) + (CASE WHEN p_source = 'assignment' THEN p_minutes ELSE 0 END),
    challenge_time_minutes = COALESCE(student_stats.challenge_time_minutes, 0) + (CASE WHEN p_source = 'challenge' THEN p_minutes ELSE 0 END),
    last_active_date = p_today,
    updated_at = now()
  RETURNING * INTO result;
  RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.increment_student_subject_time(p_student_id uuid, p_subject text, p_minutes integer, p_today date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO student_subject_time (student_id, subject, minutes, today_minutes, today_date, updated_at)
  VALUES (p_student_id, p_subject, p_minutes, p_minutes, p_today, now())
  ON CONFLICT (student_id, subject) DO UPDATE SET
    minutes = student_subject_time.minutes + p_minutes,
    today_minutes = CASE
      WHEN student_subject_time.today_date = p_today THEN student_subject_time.today_minutes + p_minutes
      ELSE p_minutes
    END,
    today_date = p_today,
    updated_at = now();
END;
$function$
;


-- ============ ROW LEVEL SECURITY ============
alter table "public"."analytics_events" enable row level security;
alter table "public"."announcement_attachments" enable row level security;
alter table "public"."announcement_targets" enable row level security;
alter table "public"."announcement_user_state" enable row level security;
alter table "public"."announcements" enable row level security;
alter table "public"."assignment_submissions" enable row level security;
alter table "public"."assignments" enable row level security;
alter table "public"."branding_logos" enable row level security;
alter table "public"."challenge_assignments" enable row level security;
alter table "public"."challenge_questions" enable row level security;
alter table "public"."challenges" enable row level security;
alter table "public"."chat_channel_members" enable row level security;
alter table "public"."chat_channel_messages" enable row level security;
alter table "public"."chat_channel_reads" enable row level security;
alter table "public"."chat_channels" enable row level security;
alter table "public"."class_portfolio_attachments" enable row level security;
alter table "public"."class_portfolio_comments" enable row level security;
alter table "public"."class_portfolio_folders" enable row level security;
alter table "public"."class_portfolio_likes" enable row level security;
alter table "public"."class_portfolio_posts" enable row level security;
alter table "public"."class_portfolio_tags" enable row level security;
alter table "public"."class_timetables" enable row level security;
alter table "public"."demo_requests" enable row level security;
alter table "public"."habits_checkins" enable row level security;
alter table "public"."import_runs" enable row level security;
alter table "public"."llm_logs" enable row level security;
alter table "public"."message_reactions" enable row level security;
alter table "public"."messages" enable row level security;
alter table "public"."otp_codes" enable row level security;
alter table "public"."parent_children" enable row level security;
alter table "public"."parent_daily_tasks" enable row level security;
alter table "public"."parent_student" enable row level security;
alter table "public"."resource_files" enable row level security;
alter table "public"."resource_folders" enable row level security;
alter table "public"."schedule_events" enable row level security;
alter table "public"."school_access_requests" enable row level security;
alter table "public"."schools" enable row level security;
alter table "public"."short_links" enable row level security;
alter table "public"."student_daily_log" enable row level security;
alter table "public"."student_preferences" enable row level security;
alter table "public"."student_stats" enable row level security;
alter table "public"."student_subject_time" enable row level security;
alter table "public"."teacher_student" enable row level security;
alter table "public"."teacher_students" enable row level security;
alter table "public"."timetable_slots" enable row level security;
alter table "public"."topic_attempts" enable row level security;
alter table "public"."upload_jobs" enable row level security;
alter table "public"."user_preferences" enable row level security;
alter table "public"."users" enable row level security;
alter table "public"."videos" enable row level security;

-- ============ POLICIES ============
do $$ begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'challenge_questions' and policyname = 'challenge_questions_all_superadmin') then
    create policy "challenge_questions_all_superadmin" on "public"."challenge_questions" as permissive for all to "public" using ((EXISTS ( SELECT 1
   FROM users u
  WHERE (((u.id)::text = (auth.uid())::text) AND (u.role = 'super_admin'::text)))));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'challenge_questions' and policyname = 'challenge_questions_select') then
    create policy "challenge_questions_select" on "public"."challenge_questions" as permissive for select to "public" using ((EXISTS ( SELECT 1
   FROM challenges c
  WHERE ((c.id = challenge_questions.challenge_id) AND (c.is_published = true)))));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'challenges' and policyname = 'challenges_all_superadmin') then
    create policy "challenges_all_superadmin" on "public"."challenges" as permissive for all to "public" using ((EXISTS ( SELECT 1
   FROM users u
  WHERE (((u.id)::text = (auth.uid())::text) AND (u.role = 'super_admin'::text)))));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'challenges' and policyname = 'challenges_select') then
    create policy "challenges_select" on "public"."challenges" as permissive for select to "public" using ((is_published = true));
  end if;
end $$;

-- ============ GRANTS ============
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."analytics_events" to "anon";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."analytics_events" to "authenticated";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."analytics_events" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."announcement_attachments" to "anon";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."announcement_attachments" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."announcement_attachments" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."announcement_targets" to "anon";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."announcement_targets" to "authenticated";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."announcement_targets" to "service_role";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."announcement_user_state" to "anon";
grant SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."announcement_user_state" to "authenticated";
grant SELECT, INSERT, DELETE, TRUNCATE, REFERENCES, TRIGGER, UPDATE on table "public"."announcement_user_state" to "service_role";
grant INSERT, TRIGGER, SELECT, REFERENCES, TRUNCATE, DELETE, UPDATE on table "public"."announcements" to "anon";
grant SELECT, REFERENCES, INSERT, TRIGGER, TRUNCATE, DELETE, UPDATE on table "public"."announcements" to "authenticated";
grant SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT on table "public"."announcements" to "service_role";
grant SELECT, TRIGGER, UPDATE, DELETE, TRUNCATE, REFERENCES, INSERT on table "public"."assignment_submissions" to "anon";
grant REFERENCES, TRIGGER, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."assignment_submissions" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."assignment_submissions" to "service_role";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."assignments" to "anon";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."assignments" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."assignments" to "service_role";
grant UPDATE, INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, SELECT on table "public"."branding_logos" to "anon";
grant SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT on table "public"."branding_logos" to "authenticated";
grant SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."branding_logos" to "service_role";
grant UPDATE, INSERT, SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE on table "public"."challenge_assignments" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."challenge_assignments" to "authenticated";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."challenge_assignments" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."challenge_questions" to "anon";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."challenge_questions" to "authenticated";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."challenge_questions" to "service_role";
grant SELECT, REFERENCES, TRUNCATE, DELETE, UPDATE, TRIGGER, INSERT on table "public"."challenges" to "anon";
grant TRUNCATE, INSERT, UPDATE, DELETE, SELECT, REFERENCES, TRIGGER on table "public"."challenges" to "authenticated";
grant SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT on table "public"."challenges" to "service_role";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."chat_channel_members" to "anon";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."chat_channel_members" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."chat_channel_members" to "service_role";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."chat_channel_messages" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."chat_channel_messages" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."chat_channel_messages" to "service_role";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."chat_channel_reads" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."chat_channel_reads" to "authenticated";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."chat_channel_reads" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."chat_channels" to "anon";
grant INSERT, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, TRIGGER on table "public"."chat_channels" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."chat_channels" to "service_role";
grant TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, INSERT on table "public"."class_portfolio_attachments" to "anon";
grant REFERENCES, TRIGGER, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."class_portfolio_attachments" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."class_portfolio_attachments" to "service_role";
grant SELECT, INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE on table "public"."class_portfolio_comments" to "anon";
grant DELETE, INSERT, SELECT, UPDATE, TRUNCATE, REFERENCES, TRIGGER on table "public"."class_portfolio_comments" to "authenticated";
grant INSERT, TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."class_portfolio_comments" to "service_role";
grant SELECT, INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE on table "public"."class_portfolio_folders" to "anon";
grant UPDATE, INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, SELECT on table "public"."class_portfolio_folders" to "authenticated";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."class_portfolio_folders" to "service_role";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."class_portfolio_likes" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."class_portfolio_likes" to "authenticated";
grant SELECT, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT, TRIGGER on table "public"."class_portfolio_likes" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."class_portfolio_posts" to "anon";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."class_portfolio_posts" to "authenticated";
grant SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT on table "public"."class_portfolio_posts" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."class_portfolio_tags" to "anon";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."class_portfolio_tags" to "authenticated";
grant TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, INSERT on table "public"."class_portfolio_tags" to "service_role";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."class_timetables" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."class_timetables" to "authenticated";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."class_timetables" to "service_role";
grant REFERENCES, TRIGGER, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."curriculum_sources" to "anon";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."curriculum_sources" to "authenticated";
grant INSERT, UPDATE, SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE on table "public"."curriculum_sources" to "service_role";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."demo_requests" to "anon";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."demo_requests" to "authenticated";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."demo_requests" to "service_role";
grant SELECT, INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE on table "public"."habits_checkins" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."habits_checkins" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."habits_checkins" to "service_role";
grant UPDATE, INSERT, DELETE, TRUNCATE, REFERENCES, TRIGGER, SELECT on table "public"."import_runs" to "anon";
grant UPDATE, INSERT, SELECT, TRIGGER, DELETE, TRUNCATE, REFERENCES on table "public"."import_runs" to "authenticated";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."import_runs" to "service_role";
grant TRIGGER, SELECT, UPDATE, INSERT, DELETE, TRUNCATE, REFERENCES on table "public"."llm_logs" to "anon";
grant TRUNCATE, INSERT, TRIGGER, REFERENCES, DELETE, UPDATE, SELECT on table "public"."llm_logs" to "authenticated";
grant INSERT, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, TRIGGER on table "public"."llm_logs" to "service_role";
grant INSERT, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, TRIGGER on table "public"."message_reactions" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."message_reactions" to "authenticated";
grant TRIGGER, REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."message_reactions" to "service_role";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."messages" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."messages" to "authenticated";
grant DELETE, UPDATE, SELECT, INSERT, TRUNCATE, REFERENCES, TRIGGER on table "public"."messages" to "service_role";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."otp_codes" to "anon";
grant DELETE, INSERT, TRIGGER, REFERENCES, TRUNCATE, UPDATE, SELECT on table "public"."otp_codes" to "authenticated";
grant SELECT, REFERENCES, TRUNCATE, TRIGGER, DELETE, UPDATE, INSERT on table "public"."otp_codes" to "service_role";
grant TRUNCATE, REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE on table "public"."parent_children" to "anon";
grant DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT, SELECT, UPDATE on table "public"."parent_children" to "authenticated";
grant DELETE, TRUNCATE, TRIGGER, REFERENCES, INSERT, SELECT, UPDATE on table "public"."parent_children" to "service_role";
grant TRUNCATE, INSERT, TRIGGER, SELECT, UPDATE, DELETE, REFERENCES on table "public"."parent_daily_tasks" to "anon";
grant SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."parent_daily_tasks" to "authenticated";
grant DELETE, TRUNCATE, INSERT, REFERENCES, TRIGGER, SELECT, UPDATE on table "public"."parent_daily_tasks" to "service_role";
grant TRUNCATE, DELETE, TRIGGER, UPDATE, INSERT, SELECT, REFERENCES on table "public"."parent_student" to "anon";
grant DELETE, TRUNCATE, REFERENCES, TRIGGER, INSERT, SELECT, UPDATE on table "public"."parent_student" to "authenticated";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."parent_student" to "service_role";
grant TRUNCATE, DELETE, UPDATE, SELECT, INSERT, TRIGGER, REFERENCES on table "public"."resource_files" to "anon";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."resource_files" to "authenticated";
grant SELECT, UPDATE, DELETE, INSERT, TRUNCATE, REFERENCES, TRIGGER on table "public"."resource_files" to "service_role";
grant UPDATE, TRUNCATE, REFERENCES, TRIGGER, INSERT, SELECT, DELETE on table "public"."resource_folders" to "anon";
grant TRIGGER, REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."resource_folders" to "authenticated";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."resource_folders" to "service_role";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."schedule_events" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."schedule_events" to "authenticated";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."schedule_events" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."school_access_requests" to "anon";
grant REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER on table "public"."school_access_requests" to "authenticated";
grant TRIGGER, SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."school_access_requests" to "service_role";
grant REFERENCES, TRIGGER, INSERT, UPDATE, DELETE, TRUNCATE, SELECT on table "public"."schools" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."schools" to "authenticated";
grant INSERT, TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."schools" to "service_role";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."short_links" to "anon";
grant REFERENCES, TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, INSERT on table "public"."short_links" to "authenticated";
grant TRIGGER, REFERENCES, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."short_links" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."student_daily_log" to "anon";
grant UPDATE, INSERT, SELECT, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."student_daily_log" to "authenticated";
grant INSERT, TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."student_daily_log" to "service_role";
grant DELETE, UPDATE, TRIGGER, REFERENCES, TRUNCATE, SELECT, INSERT on table "public"."student_preferences" to "anon";
grant DELETE, INSERT, SELECT, UPDATE, TRUNCATE, REFERENCES, TRIGGER on table "public"."student_preferences" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."student_preferences" to "service_role";
grant INSERT, REFERENCES, TRUNCATE, DELETE, UPDATE, TRIGGER, SELECT on table "public"."student_stats" to "anon";
grant TRIGGER, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, INSERT on table "public"."student_stats" to "authenticated";
grant SELECT, UPDATE, DELETE, INSERT, TRUNCATE, REFERENCES, TRIGGER on table "public"."student_stats" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."student_subject_time" to "anon";
grant UPDATE, INSERT, SELECT, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."student_subject_time" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."student_subject_time" to "service_role";
grant REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE on table "public"."syllabus_chapters" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."syllabus_chapters" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."syllabus_chapters" to "service_role";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."syllabus_extraction_jobs" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."syllabus_extraction_jobs" to "authenticated";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."syllabus_extraction_jobs" to "service_role";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."syllabus_topics" to "anon";
grant DELETE, TRIGGER, REFERENCES, TRUNCATE, UPDATE, SELECT, INSERT on table "public"."syllabus_topics" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."syllabus_topics" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."teacher_student" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."teacher_student" to "authenticated";
grant DELETE, SELECT, INSERT, TRUNCATE, REFERENCES, TRIGGER, UPDATE on table "public"."teacher_student" to "service_role";
grant TRUNCATE, REFERENCES, TRIGGER, INSERT, SELECT, UPDATE, DELETE on table "public"."teacher_students" to "anon";
grant TRIGGER, SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."teacher_students" to "authenticated";
grant UPDATE, INSERT, SELECT, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."teacher_students" to "service_role";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."timetable_slots" to "anon";
grant UPDATE, INSERT, SELECT, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."timetable_slots" to "authenticated";
grant INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."timetable_slots" to "service_role";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."topic_attempts" to "anon";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."topic_attempts" to "authenticated";
grant DELETE, SELECT, INSERT, TRUNCATE, REFERENCES, TRIGGER, UPDATE on table "public"."topic_attempts" to "service_role";
grant SELECT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, INSERT on table "public"."topic_resources" to "anon";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."topic_resources" to "authenticated";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."topic_resources" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."upload_jobs" to "anon";
grant REFERENCES, TRUNCATE, DELETE, TRIGGER, UPDATE, SELECT, INSERT on table "public"."upload_jobs" to "authenticated";
grant DELETE, INSERT, SELECT, UPDATE, TRUNCATE, REFERENCES, TRIGGER on table "public"."upload_jobs" to "service_role";
grant INSERT, TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT on table "public"."user_preferences" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."user_preferences" to "authenticated";
grant UPDATE, TRIGGER, REFERENCES, TRUNCATE, DELETE, SELECT, INSERT on table "public"."user_preferences" to "service_role";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."users" to "anon";
grant TRIGGER, REFERENCES, TRUNCATE, DELETE, UPDATE, SELECT, INSERT on table "public"."users" to "authenticated";
grant UPDATE, TRIGGER, REFERENCES, TRUNCATE, DELETE, INSERT, SELECT on table "public"."users" to "service_role";
grant TRIGGER, INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES on table "public"."videos" to "anon";
grant UPDATE, INSERT, SELECT, DELETE, TRUNCATE, REFERENCES, TRIGGER on table "public"."videos" to "authenticated";
grant SELECT, REFERENCES, TRIGGER, INSERT, TRUNCATE, DELETE, UPDATE on table "public"."videos" to "service_role";

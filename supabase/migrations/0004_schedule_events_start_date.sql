ALTER TABLE "public"."schedule_events" ADD COLUMN IF NOT EXISTS "start_date" text;
ALTER TABLE "public"."schedule_events" ADD COLUMN IF NOT EXISTS "challenge_id" text;

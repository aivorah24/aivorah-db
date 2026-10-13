-- Notification V2: school/platform announcements reach the bell (aivorah-school-admin-service).
-- Keeps every type from 0014 and adds announcement. Parents get announcements as themselves
-- (no child), like account_updated. announcements.notified_version = last content_version fanned out.

alter table "public"."notifications" drop constraint if exists "notifications_type_check";
alter table "public"."notifications" add constraint "notifications_type_check"
  check (type in ('challenge_assigned', 'assignment_assigned', 'challenge_due', 'assignment_due', 'event_scheduled', 'account_updated', 'class_post', 'announcement'));

alter table "public"."notifications" drop constraint if exists "notifications_entity_type_check";
alter table "public"."notifications" add constraint "notifications_entity_type_check"
  check (entity_type in ('challenge_assignment', 'assignment', 'schedule_event', 'user', 'class_post', 'announcement'));

alter table "public"."notifications" drop constraint if exists "notifications_parent_has_child";
alter table "public"."notifications" add constraint "notifications_parent_has_child"
  check (recipient_role <> 'parent' or child_id is not null or type in ('account_updated', 'announcement'));

alter table "public"."announcements" add column if not exists "notified_version" integer;

-- Platform-admin edits to a user's account (aivorah-platform-admin-service) notify that user. Widens checks only.

alter table "public"."notifications" drop constraint if exists "notifications_type_check";
alter table "public"."notifications" add constraint "notifications_type_check"
  check (type in ('challenge_assigned', 'assignment_assigned', 'challenge_due', 'assignment_due', 'event_scheduled', 'account_updated'));

alter table "public"."notifications" drop constraint if exists "notifications_entity_type_check";
alter table "public"."notifications" add constraint "notifications_entity_type_check"
  check (entity_type in ('challenge_assignment', 'assignment', 'schedule_event', 'user'));

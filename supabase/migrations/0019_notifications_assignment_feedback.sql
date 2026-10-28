-- Notification V2: teacher feedback on a submission reaches the student + parent bell
-- (aivorah-assignments-service PUT /assignments/:id/teacher-feedback). Keeps every type from 0016.

alter table "public"."notifications" drop constraint if exists "notifications_type_check";
alter table "public"."notifications" add constraint "notifications_type_check"
  check (type in ('challenge_assigned', 'assignment_assigned', 'challenge_due', 'assignment_due', 'event_scheduled', 'account_updated', 'class_post', 'announcement', 'assignment_feedback'));

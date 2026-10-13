-- Account notices (platform-admin edits) go to parents themselves, not about a child. Widens one check only.

alter table "public"."notifications" drop constraint if exists "notifications_parent_has_child";
alter table "public"."notifications" add constraint "notifications_parent_has_child"
  check (recipient_role <> 'parent' or child_id is not null or type = 'account_updated');

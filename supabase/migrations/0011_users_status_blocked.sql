-- Platform-admin block/unblock (aivorah-platform-admin-service) sets users.status = 'blocked'. Widens check only.

alter table "public"."users" drop constraint if exists "users_status_check";
alter table "public"."users" add constraint "users_status_check"
  check (status in ('active', 'inactive', 'archived', 'blocked'));

-- Students archived by their school could not ask a new school to join:
-- POST /user/request-school-access refuses anyone with an 'approved'
-- school_access_requests row ("already verified and linked"), and archiving
-- left that row approved. aivorah-school-admin-service now marks it
-- 'archived' when a student is archived; this does the same once for
-- students archived before that change.
-- school_access_requests is unique on (user_email, school_id, status), so a
-- row is skipped when an 'archived' one already exists for that school.

update public.school_access_requests r
set status = 'archived'
from public.users u
where u.email = r.user_email
  and u.role = 'student'
  and u.status = 'archived'
  and u.school_id = r.school_id
  and r.status = 'approved'
  and not exists (
    select 1 from public.school_access_requests x
    where x.user_email = r.user_email
      and x.school_id = r.school_id
      and x.status = 'archived'
  );

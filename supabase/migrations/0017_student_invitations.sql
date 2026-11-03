-- Teacher → student Google SSO invitations (aivorah-students-service).
-- The student's users row is created only when the invitation is accepted, inside
-- accept_student_invitation(), so a Google sign-in alone never yields a profile.

create table if not exists "public"."student_invitations" (
  "id" uuid primary key default gen_random_uuid(),
  "token_hash" text not null unique,
  "email" text not null check (email = lower(btrim(email))),
  "name" text not null,
  "grade" text not null,
  "curriculum" text not null,
  "school" text,
  "school_id" uuid,
  "invited_by" uuid not null references "public"."users"(id) on delete cascade,
  "status" text not null default 'pending'
    check (status in ('pending', 'accepted', 'expired', 'revoked')),
  "email_status" text not null default 'pending'
    check (email_status in ('pending', 'sent', 'failed')),
  "expires_at" timestamptz not null,
  "accepted_at" timestamptz,
  "accepted_firebase_uid" text,
  "student_user_id" uuid references "public"."users"(id) on delete set null,
  "created_at" timestamptz not null default now(),
  "updated_at" timestamptz not null default now()
);

create unique index if not exists student_invitations_one_pending_per_email
  on "public"."student_invitations" (email) where status = 'pending';
create index if not exists student_invitations_invited_by_idx
  on "public"."student_invitations" (invited_by);

alter table "public"."student_invitations" enable row level security;
revoke all on "public"."student_invitations" from anon, authenticated;

-- Single transaction: validate + consume the invitation and create the student.
-- Idempotent for the same Firebase UID (a retried accept returns the same student).
create or replace function "public"."accept_student_invitation"(
  p_token_hash text, p_firebase_uid text, p_email text, p_student_code text
) returns jsonb
language plpgsql
set search_path = public
as $$
declare
  inv student_invitations%rowtype;
  uid_owner text;
  new_id uuid;
begin
  select * into inv from student_invitations where token_hash = p_token_hash for update;
  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if inv.status = 'accepted' then
    if inv.accepted_firebase_uid = p_firebase_uid then
      return jsonb_build_object('ok', true, 'alreadyAccepted', true,
        'studentUserId', inv.student_user_id, 'email', inv.email);
    end if;
    return jsonb_build_object('ok', false, 'code', 'already_used');
  end if;
  if inv.status <> 'pending' then
    return jsonb_build_object('ok', false, 'code', inv.status);
  end if;
  if inv.expires_at <= now() then
    update student_invitations set status = 'expired', updated_at = now() where id = inv.id;
    return jsonb_build_object('ok', false, 'code', 'expired');
  end if;
  if lower(btrim(p_email)) <> inv.email then
    return jsonb_build_object('ok', false, 'code', 'email_mismatch');
  end if;

  select user_email into uid_owner from user_preferences
    where data->>'firebaseUid' = p_firebase_uid limit 1;
  if uid_owner is not null and uid_owner <> inv.email then
    return jsonb_build_object('ok', false, 'code', 'uid_linked_elsewhere');
  end if;
  if exists (select 1 from users where email = inv.email) then
    return jsonb_build_object('ok', false, 'code', 'account_exists');
  end if;

  insert into users (name, email, role, grade, curriculum, school, school_id, onboarding_complete)
    values (inv.name, inv.email, 'student', inv.grade, inv.curriculum, coalesce(inv.school, ''), inv.school_id, true)
    returning id into new_id;
  insert into student_stats (student_id) values (new_id) on conflict do nothing;
  insert into teacher_student (teacher_id, student_id, subject)
    values (inv.invited_by, new_id, inv.curriculum) on conflict do nothing;
  insert into user_preferences (user_email, data, updated_at)
    values (inv.email, jsonb_build_object(
      'studentId', p_student_code,
      'createdByTeacher', (select email from users where id = inv.invited_by),
      'accountStatus', 'active',
      'authProvider', 'google',
      'firebaseUid', p_firebase_uid,
      'invitationId', inv.id,
      'activatedAt', now()), now())
    on conflict (user_email) do update
      set data = coalesce(user_preferences.data, '{}'::jsonb) || excluded.data, updated_at = now();

  update student_invitations
    set status = 'accepted', accepted_at = now(), accepted_firebase_uid = p_firebase_uid,
        student_user_id = new_id, updated_at = now()
    where id = inv.id;

  return jsonb_build_object('ok', true, 'alreadyAccepted', false, 'studentUserId', new_id, 'email', inv.email);
end;
$$;

revoke all on function "public"."accept_student_invitation"(text, text, text, text) from public, anon, authenticated;
grant execute on function "public"."accept_student_invitation"(text, text, text, text) to service_role;

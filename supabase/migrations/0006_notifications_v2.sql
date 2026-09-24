-- Notification System V2 foundation (docs: aivorah-frontend/docs/architecture/NOTIFICATION_V2_DESIGN.md).
-- Additive only. One row per recipient per event; (recipient_id, event_key) makes creation idempotent.

create table if not exists "public"."notifications" (
  "id"              uuid primary key default gen_random_uuid(),
  "recipient_id"    uuid not null references public.users(id) on delete cascade,
  "recipient_role"  text not null check (recipient_role in ('student', 'parent', 'teacher', 'school_admin')),
  "type"            text not null check (type in ('challenge_assigned', 'assignment_assigned', 'challenge_due', 'assignment_due')),
  "entity_type"     text not null check (entity_type in ('challenge_assignment', 'assignment')),
  "entity_id"       text not null,
  "child_id"        uuid references public.users(id) on delete cascade,
  "title"           text not null,
  "body"            text,
  "data"            jsonb not null default '{}'::jsonb,
  "event_key"       text not null,
  "actor_email"     text,
  "actor_role"      text,
  "created_at"      timestamptz not null default now(),
  "read_at"         timestamptz,
  -- 'disabled' until centralized push delivery ships, so legacy and V2 never both push.
  "push_status"     text not null default 'disabled'
                    check (push_status in ('disabled', 'pending', 'sending', 'sent', 'failed', 'skipped')),
  "push_attempts"   integer not null default 0,
  "push_next_at"    timestamptz,
  "push_error"      text,
  "push_ticket_ids" text[],
  constraint notifications_recipient_event_uniq unique (recipient_id, event_key),
  constraint notifications_parent_has_child check (recipient_role <> 'parent' or child_id is not null)
);

create index if not exists notifications_feed_idx
  on public.notifications using btree (recipient_id, created_at desc, id desc);
create index if not exists notifications_unread_idx
  on public.notifications using btree (recipient_id) where read_at is null;
create index if not exists notifications_push_idx
  on public.notifications using btree (push_next_at) where push_status in ('pending', 'sending');
create index if not exists notifications_entity_idx
  on public.notifications using btree (entity_type, entity_id);

alter table "public"."notifications" enable row level security;
revoke all on table "public"."notifications" from anon, authenticated;
grant select, insert, update, delete on table "public"."notifications" to "service_role";

-- Version for re-assignment: bumped when a completed challenge is assigned again.
alter table "public"."challenge_assignments" add column if not exists "assigned_at" timestamptz;
update "public"."challenge_assignments" set "assigned_at" = "created_at" where "assigned_at" is null;
alter table "public"."challenge_assignments" alter column "assigned_at" set default now();
alter table "public"."challenge_assignments" alter column "assigned_at" set not null;

do $$
begin
  if exists (select 1 from public.challenge_assignments group by challenge_id, student_id having count(*) > 1) then
    raise exception 'challenge_assignments has duplicate (challenge_id, student_id) rows; dedupe before applying 0006';
  end if;
  if not exists (select 1 from pg_constraint where conname = 'challenge_assignments_challenge_student_uniq') then
    alter table public.challenge_assignments
      add constraint challenge_assignments_challenge_student_uniq unique (challenge_id, student_id);
  end if;
end $$;

-- <type>:<entity_type>:<entity_id>:<version epoch ms>[:<qualifier>]; parent rows append :child=<childId>.
create or replace function public.notification_event_key(
  p_type text, p_entity_type text, p_entity_id text, p_version timestamptz, p_qualifier text default null
) returns text
language sql immutable
set search_path = public
as $$
  select p_type || ':' || p_entity_type || ':' || p_entity_id || ':'
      || floor(extract(epoch from p_version) * 1000)::bigint::text
      || coalesce(':' || nullif(p_qualifier, ''), '');
$$;

-- Fan-out + idempotent insert for one business event.
-- p_event: {type, entity_type, entity_id, version, qualifier?, student_ids[], notify_parents?,
--           actor_email?, actor_role?, title, body?, parent_title?, parent_body?, data?}
-- parent_title/parent_body may contain {child}, replaced with the child's name.
create or replace function public.notify_event(p_event jsonb)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_type        text := p_event->>'type';
  v_entity_type text := p_event->>'entity_type';
  v_entity_id   text := p_event->>'entity_id';
  v_version     timestamptz := (p_event->>'version')::timestamptz;
  v_qualifier   text := p_event->>'qualifier';
  v_actor       text := lower(nullif(trim(p_event->>'actor_email'), ''));
  v_parents     boolean := coalesce((p_event->>'notify_parents')::boolean, true);
  v_title       text := nullif(trim(p_event->>'title'), '');
  v_data        jsonb := coalesce(p_event->'data', '{}'::jsonb);
  v_students    uuid[];
  v_key         text;
  v_candidates  integer;
  v_orphans     integer := 0;
  v_inserted    jsonb;
begin
  if v_type is null or v_entity_type is null or v_entity_id is null or v_version is null or v_title is null then
    raise exception 'notify_event: type, entity_type, entity_id, version and title are required';
  end if;
  select coalesce(array_agg(distinct s::uuid), '{}') into v_students
    from jsonb_array_elements_text(coalesce(p_event->'student_ids', '[]'::jsonb)) s;
  if cardinality(v_students) = 0 then
    raise exception 'notify_event: student_ids must be a non-empty array';
  end if;

  v_key := notification_event_key(v_type, v_entity_type, v_entity_id, v_version, v_qualifier);

  if v_parents then
    select count(*) into v_orphans
      from parent_children pc
     where pc.child_id = any(v_students)
       and (v_actor is null or lower(pc.parent_email) <> v_actor)
       and not exists (select 1 from users pu where lower(pu.email) = lower(pc.parent_email));
  end if;

  with recipients as (
    select u.id as recipient_id, 'student'::text as recipient_role, null::uuid as child_id,
           v_title as title, p_event->>'body' as body, v_key as event_key
      from users u
     where u.id = any(v_students)
       and (v_actor is null or lower(u.email) <> v_actor)
    union all
    select distinct on (pu.id, c.id)
           pu.id, 'parent', c.id,
           replace(coalesce(nullif(p_event->>'parent_title', ''), v_title), '{child}', coalesce(nullif(c.name, ''), 'your child')),
           replace(coalesce(p_event->>'parent_body', p_event->>'body'), '{child}', coalesce(nullif(c.name, ''), 'your child')),
           v_key || ':child=' || c.id
      from parent_children pc
      join users c  on c.id = pc.child_id
      join users pu on lower(pu.email) = lower(pc.parent_email)
     where v_parents
       and pc.child_id = any(v_students)
       and (v_actor is null or lower(pc.parent_email) <> v_actor)
  ),
  ins as (
    insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, child_id,
                               title, body, data, event_key, actor_email, actor_role)
    select r.recipient_id, r.recipient_role, v_type, v_entity_type, v_entity_id, r.child_id,
           r.title, r.body,
           case when r.child_id is null then v_data else v_data || jsonb_build_object('childId', r.child_id) end,
           r.event_key, v_actor, p_event->>'actor_role'
      from recipients r
    on conflict (recipient_id, event_key) do nothing
    returning id, recipient_id, recipient_role, child_id, event_key
  )
  select (select count(*) from recipients),
         coalesce((select jsonb_agg(to_jsonb(ins)) from ins), '[]'::jsonb)
    into v_candidates, v_inserted;

  return jsonb_build_object(
    'eventKey',          v_key,
    'recipients',        v_candidates,
    'inserted',          v_inserted,
    'duplicates',        v_candidates - jsonb_array_length(v_inserted),
    'orphanParentLinks', v_orphans
  );
end;
$$;

revoke all on function public.notify_event(jsonb) from public, anon, authenticated;
revoke all on function public.notification_event_key(text, text, text, timestamptz, text) from public, anon, authenticated;
grant execute on function public.notify_event(jsonb) to service_role;
grant execute on function public.notification_event_key(text, text, text, timestamptz, text) to service_role;

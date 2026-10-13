-- Notification V2: B2B class posts (aivorah-school-admin-service class portfolio).
-- Widens the type/entity checks and lets producers skip recipients who turned the
-- category off (p_event.exclude_emails). notify_event is otherwise unchanged from 0006.

alter table "public"."notifications" drop constraint if exists "notifications_type_check";
alter table "public"."notifications" add constraint "notifications_type_check"
  check (type in ('challenge_assigned', 'assignment_assigned', 'challenge_due', 'assignment_due', 'event_scheduled', 'class_post'));

alter table "public"."notifications" drop constraint if exists "notifications_entity_type_check";
alter table "public"."notifications" add constraint "notifications_entity_type_check"
  check (entity_type in ('challenge_assignment', 'assignment', 'schedule_event', 'class_post'));

-- p_event: as 0006, plus exclude_emails?: text[] (students and/or parents to skip).
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
  v_excluded    text[];
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
  select coalesce(array_agg(distinct lower(trim(e))), '{}') into v_excluded
    from jsonb_array_elements_text(coalesce(p_event->'exclude_emails', '[]'::jsonb)) e;

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
       and not (lower(u.email) = any(v_excluded))
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
       and not (lower(pu.email) = any(v_excluded))
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
grant execute on function public.notify_event(jsonb) to service_role;

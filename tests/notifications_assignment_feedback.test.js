// Runs migrations 0006 → 0019 on PGlite: notify_event fans assignment_feedback out to the student and parents.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const migration = name => fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', name), 'utf8');

const STUB = `
  create role anon; create role authenticated; create role service_role;
  create table users (id uuid primary key default gen_random_uuid(), email text unique, name text, role text);
  create table parent_children (id uuid primary key default gen_random_uuid(), parent_email text not null,
    child_id uuid not null references users(id) on delete cascade, unique (parent_email, child_id));
  create table challenge_assignments (id text primary key, challenge_id text not null, student_id uuid not null
    references users(id) on delete cascade, status text not null default 'assigned',
    created_at timestamptz not null default now());
  create table announcements (id uuid primary key default gen_random_uuid(), title text not null,
    content_version integer not null default 1);
`;

const ASHA = '11111111-1111-1111-1111-111111111111';
const MOM  = '33333333-3333-3333-3333-333333333333';

async function freshDb() {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(`insert into users (id, email, name, role) values
    ('${ASHA}', 'asha@x.com', 'Asha', 'student'), ('${MOM}', 'mom@x.com', 'Mom', 'parent');
    insert into parent_children (parent_email, child_id) values ('mom@x.com', '${ASHA}');`);
  for (const m of ['0006_notifications_v2.sql', '0010_notifications_schedule_events.sql', '0012_notifications_account_updated.sql',
    '0013_notifications_account_updated_any_role.sql', '0014_notifications_class_post.sql', '0016_notifications_announcement.sql', '0019_notifications_assignment_feedback.sql']) {
    await db.exec(migration(m));
  }
  return db;
}

const feedbackEvent = (version, title = 'Teacher feedback on your assignment: Fractions') => ({
  type: 'assignment_feedback', entity_type: 'assignment', entity_id: 'as-1', version,
  student_ids: [ASHA], actor_email: 't@x.com', actor_role: 'teacher',
  title, body: 'Great job!', parent_title: 'Teacher feedback for {child}: Fractions', parent_body: 'Great job!',
  data: { assignmentId: 'as-1' },
});

const rows = db => db.query(`select recipient_role, child_id, title from notifications where type = 'assignment_feedback' order by recipient_role`);

describe('0019 assignment_feedback notifications', () => {
  test('notify_event delivers teacher feedback to the student and the parent (with child)', async () => {
    const db = await freshDb();
    await db.query('select notify_event($1::jsonb)', [JSON.stringify(feedbackEvent('2026-10-28T10:00:00Z'))]);
    const { rows: r } = await rows(db);
    assert.deepEqual(r, [
      { recipient_role: 'parent', child_id: ASHA, title: 'Teacher feedback for Asha: Fractions' },
      { recipient_role: 'student', child_id: null, title: 'Teacher feedback on your assignment: Fractions' },
    ]);
  });

  test('an edited feedback (new version) is a new notification; replaying the same version is not', async () => {
    const db = await freshDb();
    const send = e => db.query('select notify_event($1::jsonb)', [JSON.stringify(e)]);
    await send(feedbackEvent('2026-10-28T10:00:00Z'));
    await send(feedbackEvent('2026-10-28T10:00:00Z'));
    await send(feedbackEvent('2026-10-28T11:00:00Z', 'Teacher updated feedback on your assignment: Fractions'));
    const { rows: r } = await db.query(`select count(*)::int n from notifications where recipient_role = 'student'`);
    assert.equal(r[0].n, 2);
  });

  test('earlier notification types are still accepted', async () => {
    const db = await freshDb();
    for (const type of ['assignment_assigned', 'account_updated', 'announcement']) {
      await db.query(
        `insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key)
         values ($1, 'student', $2, 'assignment', 'x', 't', $3)`, [ASHA, type, `k:${type}`]);
    }
  });

  test('unknown types are still rejected', async () => {
    const db = await freshDb();
    await assert.rejects(db.query(
      `insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key)
       values ($1, 'student', 'bogus', 'assignment', 'x', 't', 'k')`, [ASHA]), /notifications_type_check/);
  });
});

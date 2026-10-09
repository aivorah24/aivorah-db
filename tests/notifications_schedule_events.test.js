// Runs migrations 0006 + 0010 on PGlite: schedule events go through notify_event like assignments.
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
`;

const ASHA = '11111111-1111-1111-1111-111111111111';
const RAVI = '22222222-2222-2222-2222-222222222222';
const MOM  = '33333333-3333-3333-3333-333333333333';
const DAD  = '44444444-4444-4444-4444-444444444444';

async function freshDb() {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(`
    insert into users (id, email, name, role) values
      ('${ASHA}', 'asha@x.com', 'Asha', 'student'), ('${RAVI}', 'ravi@x.com', 'Ravi', 'student'),
      ('${MOM}', 'mom@x.com', 'Mom', 'parent'), ('${DAD}', 'dad@x.com', 'Dad', 'parent');
    insert into parent_children (parent_email, child_id) values
      ('mom@x.com', '${ASHA}'), ('dad@x.com', '${ASHA}'), ('mom@x.com', '${RAVI}');
  `);
  await db.exec(migration('0006_notifications_v2.sql'));
  await db.exec(migration('0010_notifications_schedule_events.sql'));
  return db;
}

const notify = async (db, event) =>
  (await db.query('select notify_event($1::jsonb) as r', [JSON.stringify(event)])).rows[0].r;

const scheduleEvent = (overrides = {}) => ({
  type: 'event_scheduled', entity_type: 'schedule_event', entity_id: 'ev_abc123',
  version: '2026-10-09T11:28:28.574Z', student_ids: [ASHA, RAVI],
  actor_email: 'teacher@x.com', actor_role: 'teacher',
  title: 'New event: Math class', body: '10 Oct · 09:00',
  parent_title: 'New event for {child}: Math class',
  data: { eventId: 'ev_abc123', date: '2026-10-10' },
  ...overrides,
});

describe('0010 schedule event notifications', () => {
  test('teacher class event reaches every listed student and each child of their parents once', async () => {
    const db = await freshDb();
    const r = await notify(db, scheduleEvent());
    assert.equal(r.inserted.length, 5); // Asha, Ravi, Mom×Asha, Mom×Ravi, Dad×Asha
    const { rows } = await db.query(`select recipient_id, recipient_role, child_id, title from notifications`);
    assert.deepEqual(rows.filter(x => x.recipient_role === 'student').map(x => x.recipient_id).sort(), [ASHA, RAVI]);
    const momRows = rows.filter(x => x.recipient_id === MOM);
    assert.deepEqual(momRows.map(x => x.title).sort(), ['New event for Asha: Math class', 'New event for Ravi: Math class']);
  });

  test('a parent who creates the event is not notified; the child and the other parent are', async () => {
    const db = await freshDb();
    await notify(db, scheduleEvent({ student_ids: [ASHA], actor_email: 'mom@x.com', actor_role: 'parent' }));
    const { rows } = await db.query(`select recipient_id from notifications order by recipient_id`);
    assert.deepEqual(rows.map(x => x.recipient_id), [ASHA, DAD]);
  });

  test('re-sending the same event inserts nothing', async () => {
    const db = await freshDb();
    await notify(db, scheduleEvent());
    const again = await notify(db, scheduleEvent());
    assert.equal(again.inserted.length, 0);
  });

  test('unknown types are still rejected', async () => {
    const db = await freshDb();
    await assert.rejects(notify(db, scheduleEvent({ type: 'event_whatever' })), /notifications_type_check/);
    await assert.rejects(notify(db, scheduleEvent({ entity_type: 'calendar' })), /notifications_entity_type_check/);
  });

  test('leaves exactly one check each on type and entity_type', async () => {
    const db = await freshDb();
    await db.exec(migration('0010_notifications_schedule_events.sql'));
    const { rows } = await db.query(`select pg_get_constraintdef(oid) d from pg_constraint
      where conrelid = 'notifications'::regclass and contype = 'c'`);
    assert.equal(rows.filter(r => /\(type = ANY/.test(r.d)).length, 1);
    assert.equal(rows.filter(r => /\(entity_type = ANY/.test(r.d)).length, 1);
  });

  test('is re-runnable', async () => {
    const db = await freshDb();
    await db.exec(migration('0010_notifications_schedule_events.sql'));
    const r = await notify(db, scheduleEvent());
    assert.equal(r.inserted.length, 5);
  });
});

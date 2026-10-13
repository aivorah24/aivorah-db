// Runs migrations 0006 + 0010 + 0011 on PGlite: class posts fan out to students + parents, honouring opt-outs.
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
  await db.exec(migration('0011_notifications_class_post.sql'));
  return db;
}

const notify = async (db, event) =>
  (await db.query('select notify_event($1::jsonb) as r', [JSON.stringify(event)])).rows[0].r;

const classPost = (overrides = {}) => ({
  type: 'class_post', entity_type: 'class_post', entity_id: 'post-1',
  version: '2026-10-13T09:00:00.000Z', student_ids: [ASHA, RAVI],
  actor_email: 'teacher@x.com', actor_role: 'teacher',
  title: 'New class post: Grade 5-A', body: 'Science fair photos',
  parent_title: 'New class post for {child}: Grade 5-A',
  data: { postId: 'post-1', grade: 'Grade 5', section: 'A' },
  ...overrides,
});

describe('0011 class post notifications', () => {
  test('every student in the class and each linked parent (per child) gets one row', async () => {
    const db = await freshDb();
    const r = await notify(db, classPost());
    assert.equal(r.inserted.length, 5); // Asha, Ravi, Mom×Asha, Mom×Ravi, Dad×Asha
    const { rows } = await db.query(`select recipient_id, recipient_role, type, entity_type, data from notifications`);
    assert.ok(rows.every(x => x.type === 'class_post' && x.entity_type === 'class_post' && x.data.postId === 'post-1'));
    assert.deepEqual(rows.filter(x => x.recipient_role === 'parent').map(x => x.data.childId).sort(), [ASHA, ASHA, RAVI].sort());
  });

  test('exclude_emails skips opted-out students and parents only', async () => {
    const db = await freshDb();
    const r = await notify(db, classPost({ exclude_emails: ['Asha@X.com', 'mom@x.com'] }));
    const { rows } = await db.query(`select recipient_id, child_id from notifications order by recipient_id`);
    // Asha opted out but Dad still hears about her; Mom opted out entirely.
    assert.deepEqual(rows.map(x => [x.recipient_id, x.child_id]), [[RAVI, null], [DAD, ASHA]]);
    assert.equal(r.inserted.length, 2);
  });

  test('the posting teacher is never a recipient and re-publishing is idempotent', async () => {
    const db = await freshDb();
    await notify(db, classPost());
    const again = await notify(db, classPost());
    assert.equal(again.inserted.length, 0);
    const { rows } = await db.query(`select count(*)::int n from notifications where actor_email = 'teacher@x.com'`);
    assert.equal(rows[0].n, 5);
  });

  test('earlier event types still work and unknown types are rejected', async () => {
    const db = await freshDb();
    const r = await notify(db, classPost({ type: 'event_scheduled', entity_type: 'schedule_event' }));
    assert.equal(r.inserted.length, 5);
    await assert.rejects(notify(db, classPost({ type: 'class_whatever' })), /notifications_type_check/);
  });

  test('is re-runnable and leaves one check each', async () => {
    const db = await freshDb();
    await db.exec(migration('0011_notifications_class_post.sql'));
    const { rows } = await db.query(`select pg_get_constraintdef(oid) d from pg_constraint
      where conrelid = 'notifications'::regclass and contype = 'c'`);
    assert.equal(rows.filter(r => /\(type = ANY/.test(r.d)).length, 1);
    assert.equal(rows.filter(r => /\(entity_type = ANY/.test(r.d)).length, 1);
    assert.equal((await notify(db, classPost())).inserted.length, 5);
  });
});

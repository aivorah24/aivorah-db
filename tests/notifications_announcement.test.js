// Runs migrations 0006 → 0016 on PGlite: announcement rows are accepted for every role, parents without a child.
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
    ('${ASHA}', 'asha@x.com', 'Asha', 'student'), ('${MOM}', 'mom@x.com', 'Mom', 'parent');`);
  for (const m of ['0006_notifications_v2.sql', '0010_notifications_schedule_events.sql', '0012_notifications_account_updated.sql',
    '0013_notifications_account_updated_any_role.sql', '0014_notifications_class_post.sql', '0016_notifications_announcement.sql']) {
    await db.exec(migration(m));
  }
  return db;
}

const insert = (db, recipient, role, overrides = {}) => db.query(
  `insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key)
   values ($1, $2, $3, $4, 'ann-1', 'New announcement: Sports Day', $5)`,
  [recipient, role, overrides.type || 'announcement', overrides.entity_type || 'announcement', `announcement:ann-1:1:${role}`],
);

describe('0016 announcement notifications', () => {
  test('students and parents (no child) get announcement rows', async () => {
    const db = await freshDb();
    await insert(db, ASHA, 'student');
    await insert(db, MOM, 'parent');
    const { rows } = await db.query(`select recipient_role, child_id from notifications order by recipient_role`);
    assert.deepEqual(rows.map(r => [r.recipient_role, r.child_id]), [['parent', null], ['student', null]]);
  });

  test('other parent rows still need a child', async () => {
    const db = await freshDb();
    await assert.rejects(insert(db, MOM, 'parent', { type: 'class_post', entity_type: 'class_post' }), /notifications_parent_has_child/);
  });

  test('earlier types are kept and unknown ones rejected', async () => {
    const db = await freshDb();
    await insert(db, ASHA, 'student', { type: 'account_updated', entity_type: 'user' });
    await insert(db, MOM, 'parent', { type: 'account_updated', entity_type: 'user' }).catch(() => assert.fail('account_updated parent rejected'));
    await assert.rejects(insert(db, ASHA, 'student', { type: 'banana' }), /notifications_type_check/);
  });

  test('announcements gain notified_version', async () => {
    const db = await freshDb();
    await db.exec(`insert into announcements (title) values ('Sports Day')`);
    const { rows } = await db.query(`select notified_version from announcements`);
    assert.equal(rows[0].notified_version, null);
  });
});

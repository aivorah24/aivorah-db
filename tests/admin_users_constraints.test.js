// Runs 0011 + 0012 on PGlite: 'blocked' users and 'account_updated' notifications are accepted.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const migration = name => fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', name), 'utf8');

const STUB = `
  create role anon; create role authenticated; create role service_role;
  create table users (id uuid primary key default gen_random_uuid(), email text unique, name text, role text,
    status text default 'active', constraint users_status_check check (status in ('active', 'inactive', 'archived')));
  create table parent_children (id uuid primary key default gen_random_uuid(), parent_email text not null,
    child_id uuid not null references users(id) on delete cascade, unique (parent_email, child_id));
  create table challenge_assignments (id text primary key, challenge_id text not null, student_id uuid not null
    references users(id) on delete cascade, status text not null default 'assigned',
    created_at timestamptz not null default now());
`;

const TEACHER = '11111111-1111-1111-1111-111111111111';

async function freshDb() {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(`insert into users (id, email, name, role) values ('${TEACHER}', 't@x.com', 'T', 'teacher')`);
  for (const m of ['0006_notifications_v2.sql', '0010_notifications_schedule_events.sql',
    '0011_users_status_blocked.sql', '0012_notifications_account_updated.sql']) await db.exec(migration(m));
  return db;
}

const accountRow = (o = {}) => ({ type: 'account_updated', entity_type: 'user', event_key: 'account_updated:user:1', ...o });
const insert = (db, r) => db.query(
  `insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key)
   values ($1::uuid, 'teacher', $2, $3, $1::text, 'Your account details have been updated', $4)`,
  [TEACHER, r.type, r.entity_type, r.event_key]);

describe('0011 users status', () => {
  test("accepts 'blocked' and keeps rejecting unknown statuses", async () => {
    const db = await freshDb();
    await db.query(`update users set status = 'blocked' where id = $1`, [TEACHER]);
    await assert.rejects(db.query(`update users set status = 'banned' where id = $1`, [TEACHER]), /users_status_check/);
  });

  test('is re-runnable and leaves one status check', async () => {
    const db = await freshDb();
    await db.exec(migration('0011_users_status_blocked.sql'));
    const { rows } = await db.query(`select 1 from pg_constraint where conname = 'users_status_check'`);
    assert.equal(rows.length, 1);
  });
});

describe('0012 account_updated notifications', () => {
  test('accepts account_updated / user and keeps all 0010 values', async () => {
    const db = await freshDb();
    await insert(db, accountRow());
    await insert(db, accountRow({ type: 'event_scheduled', entity_type: 'schedule_event', event_key: 'k2' }));
    await insert(db, accountRow({ type: 'challenge_due', entity_type: 'challenge_assignment', event_key: 'k3' }));
    const { rows } = await db.query(`select count(*)::int n from notifications`);
    assert.equal(rows[0].n, 3);
  });

  test('unknown types are still rejected', async () => {
    const db = await freshDb();
    await assert.rejects(insert(db, accountRow({ type: 'account_whatever' })), /notifications_type_check/);
    await assert.rejects(insert(db, accountRow({ entity_type: 'school' })), /notifications_entity_type_check/);
  });

  test('is re-runnable and leaves exactly one check each on type and entity_type', async () => {
    const db = await freshDb();
    await db.exec(migration('0012_notifications_account_updated.sql'));
    const { rows } = await db.query(`select pg_get_constraintdef(oid) d from pg_constraint
      where conrelid = 'notifications'::regclass and contype = 'c'`);
    assert.equal(rows.filter(r => /\(type = ANY/.test(r.d)).length, 1);
    assert.equal(rows.filter(r => /\(entity_type = ANY/.test(r.d)).length, 1);
  });
});

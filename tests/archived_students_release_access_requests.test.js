// Runs 0020 on PGlite: an archived student's approved join request for the
// school that archived them becomes 'archived', so Connect to School works again.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATION = fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', '0020_archived_students_release_access_requests.sql'), 'utf8');

async function freshDb() {
  const db = new PGlite();
  await db.exec(`
    create table users (id serial primary key, email text unique, role text, status text, school_id text);
    create table school_access_requests (id serial primary key, user_email text not null, school_id text not null,
      status text not null default 'pending', unique (user_email, school_id, status));
    insert into users (email, role, status, school_id) values
      ('archived@x.com', 'student', 'archived', 'old'),
      ('active@x.com',   'student', 'active',   'old'),
      ('again@x.com',    'student', 'archived', 'old'),
      ('teacher@x.com',  'teacher', 'archived', 'old'),
      ('moved@x.com',    'student', 'archived', 'old');
    insert into school_access_requests (user_email, school_id, status) values
      ('archived@x.com', 'old',   'approved'),
      ('active@x.com',   'old',   'approved'),
      ('again@x.com',    'old',   'approved'),
      ('again@x.com',    'old',   'archived'),
      ('teacher@x.com',  'old',   'approved'),
      ('moved@x.com',    'other', 'approved'),
      ('archived@x.com', 'new',   'pending');
  `);
  return db;
}

const statusOf = async (db, email, school) => (await db.query(
  'select status from school_access_requests where user_email = $1 and school_id = $2 order by id', [email, school])).rows.map((r) => r.status);

test('archived student: approved request at the archiving school -> archived', async () => {
  const db = await freshDb();
  await db.exec(MIGRATION);
  assert.deepEqual(await statusOf(db, 'archived@x.com', 'old'), ['archived']);
  // their pending request to the new school is untouched
  assert.deepEqual(await statusOf(db, 'archived@x.com', 'new'), ['pending']);
});

test('active students, teachers and other schools are left alone', async () => {
  const db = await freshDb();
  await db.exec(MIGRATION);
  assert.deepEqual(await statusOf(db, 'active@x.com', 'old'), ['approved']);
  assert.deepEqual(await statusOf(db, 'teacher@x.com', 'old'), ['approved']);
  assert.deepEqual(await statusOf(db, 'moved@x.com', 'other'), ['approved']);
});

test('an existing archived row for the same school does not break the unique key', async () => {
  const db = await freshDb();
  await db.exec(MIGRATION);
  assert.deepEqual(await statusOf(db, 'again@x.com', 'old'), ['approved', 'archived']);
});

test('running it twice changes nothing more', async () => {
  const db = await freshDb();
  await db.exec(MIGRATION);
  const before = (await db.query('select user_email, school_id, status from school_access_requests order by id')).rows;
  await db.exec(MIGRATION);
  const after = (await db.query('select user_email, school_id, status from school_access_requests order by id')).rows;
  assert.deepEqual(after, before);
});

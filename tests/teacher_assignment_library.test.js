// Runs 0021 on PGlite: the private per-teacher assignment library.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATION = fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', '0021_teacher_assignment_library.sql'), 'utf8');
const T1 = '11111111-1111-1111-1111-111111111111';
const T2 = '22222222-2222-2222-2222-222222222222';

async function freshDb() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated;
    create table users (id uuid primary key, email text);
    insert into users values ('${T1}', 't1@x.com'), ('${T2}', 't2@x.com');
  `);
  await db.exec(MIGRATION);
  return db;
}

const add = (db, teacher, hash, title = 'Fractions quiz') => db.query(
  `insert into teacher_assignment_library (teacher_id, title, type, content, content_hash) values ($1, $2, 'quiz', '{"title":"x"}', $3)`,
  [teacher, title, hash]);

test('a teacher can keep many items; defaults are filled in', async () => {
  const db = await freshDb();
  await add(db, T1, 'h1');
  await add(db, T1, 'h2', 'Decimals quiz');
  const { rows } = await db.query('select title, times_assigned, created_at is not null as dated from teacher_assignment_library order by title');
  assert.deepEqual(rows.map((r) => [r.title, r.times_assigned, r.dated]), [['Decimals quiz', 1, true], ['Fractions quiz', 1, true]]);
});

test('the same content twice for one teacher is rejected (the service bumps times_assigned instead)', async () => {
  const db = await freshDb();
  await add(db, T1, 'same');
  await assert.rejects(() => add(db, T1, 'same'));
  // another teacher may have identical content in their own library
  await add(db, T2, 'same');
});

test('deleting the teacher removes their library', async () => {
  const db = await freshDb();
  await add(db, T1, 'h1');
  await db.query(`delete from users where id = '${T1}'`);
  const { rows } = await db.query('select count(*)::int as n from teacher_assignment_library');
  assert.equal(rows[0].n, 0);
});

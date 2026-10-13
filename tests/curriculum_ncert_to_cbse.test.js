// Runs migration 0015 against real Postgres (PGlite) on a minimal stub of the tables it rewrites.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATION = fs.readFileSync(
  path.join(__dirname, '..', 'supabase', 'migrations', '0015_curriculum_ncert_to_cbse.sql'), 'utf8');

const STUB = `
  create table users (id serial primary key, email text unique, role text, curriculum text);
  create table schools (id serial primary key, name text, curriculum text);
  create table syllabus_chapters (id serial primary key, grade text, subject text, curriculum text not null default 'CBSE');
  create table topic_ai_enrichment (id serial primary key, curriculum text, grade text, subject text, topic text,
    unique (curriculum, grade, subject, topic));
  create table teacher_student (teacher_id int, student_id int, subject text, unique (teacher_id, student_id, subject));
  create table resource_files (id serial primary key, scope text not null default 'school');
  create table branding_logos (kind text, name text, logo_url text, unique (kind, name));
  create table user_preferences (user_email text primary key, data jsonb default '{}'::jsonb);
  create table teacher_learning_paths (id serial primary key, content jsonb, published_content jsonb);
  create table teacher_curricula (id serial primary key, extracted_structure jsonb);
  create view student_view as select id, curriculum from users;
`;

const SEED = `
  insert into users (email, role, curriculum) values
    ('a@x', 'student', 'NCERT'), ('b@x', 'student', 'ncert'), ('c@x', 'student', ' N cert '),
    ('d@x', 'student', 'CBSE'), ('e@x', 'student', 'IB PYP'), ('f@x', 'teacher', null),
    ('g@x', 'student', 'NCERT Books');
  insert into schools (name, curriculum) values ('TSRA', 'NCERT'), ('Oak', 'IB');
  insert into syllabus_chapters (grade, subject, curriculum) values ('8', 'Science', 'NCERT');
  insert into topic_ai_enrichment (curriculum, grade, subject, topic) values
    ('NCERT', '8', 'Science', 'Cells'), ('CBSE', '8', 'Science', 'Cells'), ('NCERT', '8', 'Science', 'Force');
  insert into teacher_student values (1, 2, 'NCERT'), (1, 2, 'CBSE'), (1, 3, 'NCERT'), (1, 4, 'IB PYP');
  insert into resource_files (scope) values ('NCERT'), ('Grade 8'), ('school');
  insert into branding_logos values ('curriculum', 'NCERT', 'u1'), ('school', 'NCERT', 'u2');
  insert into user_preferences values
    ('a@x', '{"curriculum":"NCERT","avatarStyle":"gamer"}'),
    ('t@x', '{"teaches":[{"grade":"Grade 8","curriculum":"ncert","subjects":["Maths"]},{"grade":"Grade 3","curriculum":"IB PYP"},"junk"]}'),
    ('p@x', '{"children":[{"name":"Kid","curriculum":"NCERT"}]}'),
    ('z@x', '{"teaches":"not-an-array"}'),
    ('n@x', null);
  insert into teacher_learning_paths (content, published_content) values
    ('{"metadata":{"curriculum":"NCERT","grade":"8"}}', '{"metadata":{"curriculum":"ncert"}}'),
    ('{"metadata":{"curriculum":"IB PYP"}}', null);
  insert into teacher_curricula (extracted_structure) values
    ('{"metadata":{"curriculum":"NCERT"},"uploadConfig":{"curriculum":"NCERT","grade":"8"}}');
`;

async function migratedDb() {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(SEED);
  await db.exec(MIGRATION);
  return db;
}

const col = async (db, sql) => (await db.query(sql)).rows.map((r) => Object.values(r)[0]);

describe('0015_curriculum_ncert_to_cbse', () => {
  test('users/schools/syllabus_chapters: NCERT in any case/spacing becomes CBSE, others untouched', async () => {
    const db = await migratedDb();
    assert.deepEqual(await col(db, 'select curriculum from users order by id'),
      ['CBSE', 'CBSE', 'CBSE', 'CBSE', 'IB PYP', null, 'NCERT Books']);
    assert.deepEqual(await col(db, 'select curriculum from schools order by id'), ['CBSE', 'IB']);
    assert.deepEqual(await col(db, 'select curriculum from syllabus_chapters'), ['CBSE']);
  });

  test('unique twins: the NCERT duplicate is dropped, the CBSE row kept', async () => {
    const db = await migratedDb();
    assert.deepEqual(await col(db, `select topic || ':' || curriculum from topic_ai_enrichment order by topic`),
      ['Cells:CBSE', 'Force:CBSE']);
    assert.deepEqual(await col(db, `select student_id || ':' || subject from teacher_student order by student_id`),
      ['2:CBSE', '3:CBSE', '4:IB PYP']);
  });

  test('resource scopes and curriculum logos (not school logos) are rewritten', async () => {
    const db = await migratedDb();
    assert.deepEqual(await col(db, 'select scope from resource_files order by id'), ['CBSE', 'Grade 8', 'school']);
    assert.deepEqual(await col(db, `select kind || ':' || name from branding_logos order by kind`),
      ['curriculum:CBSE', 'school:NCERT']);
  });

  test('user_preferences: top-level curriculum, teaches[] and children[] entries', async () => {
    const db = await migratedDb();
    const prefs = Object.fromEntries((await db.query('select user_email, data from user_preferences')).rows
      .map((r) => [r.user_email, r.data]));
    assert.deepEqual(prefs['a@x'], { curriculum: 'CBSE', avatarStyle: 'gamer' });
    assert.deepEqual(prefs['t@x'].teaches, [
      { grade: 'Grade 8', curriculum: 'CBSE', subjects: ['Maths'] }, { grade: 'Grade 3', curriculum: 'IB PYP' }, 'junk']);
    assert.deepEqual(prefs['p@x'].children, [{ name: 'Kid', curriculum: 'CBSE' }]);
    assert.deepEqual(prefs['z@x'], { teaches: 'not-an-array' });
    assert.equal(prefs['n@x'], null);
  });

  test('learning-path JSON metadata', async () => {
    const db = await migratedDb();
    assert.deepEqual(await col(db, `select content #>> '{metadata,curriculum}' from teacher_learning_paths order by id`), ['CBSE', 'IB PYP']);
    assert.deepEqual(await col(db, `select published_content #>> '{metadata,curriculum}' from teacher_learning_paths order by id`), ['CBSE', null]);
    const [es] = await col(db, 'select extracted_structure from teacher_curricula');
    assert.deepEqual(es, { metadata: { curriculum: 'CBSE' }, uploadConfig: { curriculum: 'CBSE', grade: '8' } });
  });

  test('idempotent: a second run changes nothing', async () => {
    const db = await migratedDb();
    const snapshot = async () => JSON.stringify(await Promise.all(
      ['users', 'schools', 'topic_ai_enrichment', 'teacher_student', 'resource_files', 'branding_logos',
        'user_preferences', 'teacher_learning_paths', 'teacher_curricula']
        .map((t) => db.query(`select * from ${t} order by 1`).then((r) => r.rows))));
    const before = await snapshot();
    await db.exec(MIGRATION);
    assert.equal(await snapshot(), before);
  });

  test('runs on a database missing the optional tables', async () => {
    const db = new PGlite();
    await db.exec(`create table users (id serial primary key, curriculum text);
                   insert into users (curriculum) values ('NCERT');`);
    await db.exec(MIGRATION);
    assert.deepEqual(await col(db, 'select curriculum from users'), ['CBSE']);
  });
});

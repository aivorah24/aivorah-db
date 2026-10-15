// Runs migration 0017 against real Postgres (PGlite) on a minimal stub of syllabus_chapters.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATION = fs.readFileSync(
  path.join(__dirname, '..', 'supabase', 'migrations', '0017_cisce_official_curriculum.sql'), 'utf8');

const STUB = `
  create role anon; create role authenticated;
  create table syllabus_chapters (id uuid primary key default gen_random_uuid(), grade text not null,
    subject text not null, curriculum text not null default 'CBSE', school_id uuid, unit_no int not null, title text not null);
  insert into syllabus_chapters (grade, subject, curriculum, school_id, unit_no, title) values
    ('Class I', 'Mathematics', 'ICSE', null, 1, 'Numbers'),
    ('Class II', 'English', 'ICSE', null, 1, 'Stories'),
    ('Class VI', 'Science', 'ICSE', '00000000-0000-0000-0000-000000000001', 1, 'School upload'),
    ('8', 'Science', 'CBSE', null, 1, 'Crop Production'),
    ('Grade 3', 'Maths', 'IB PYP', null, 1, 'Patterns');
`;

async function migratedDb() {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(MIGRATION);
  return db;
}

const SOURCE = `insert into cisce_sources (id, url, kind, programme, exam_year, version, subject)
  values ('icse-2028-physics', 'https://cisce.org/x/10.-Physics.pdf', 'SYLLABUS_PDF', 'ICSE', 2028, 'icse-2028', 'Physics')`;

describe('0017 cisce official curriculum', () => {
  test('is idempotent', async () => {
    const db = await migratedDb();
    await db.exec(MIGRATION);
  });

  test('existing syllabus_chapters rows are untouched', async () => {
    const db = await migratedDb();
    const rows = (await db.query('select grade, subject, curriculum, title from syllabus_chapters order by title')).rows;
    assert.equal(rows.length, 5);
    assert.deepEqual(rows.map((r) => r.curriculum).sort(), ['CBSE', 'IB PYP', 'ICSE', 'ICSE', 'ICSE']);
  });

  test('icse_supplementary_content labels only board-level ICSE rows', async () => {
    const db = await migratedDb();
    const rows = (await db.query('select grade, provenance_status from icse_supplementary_content order by grade')).rows;
    assert.deepEqual(rows, [
      { grade: 'Class I', provenance_status: 'SUPPLEMENTARY_ONLY' },
      { grade: 'Class II', provenance_status: 'SUPPLEMENTARY_ONLY' },
    ]);
  });

  test('cisce_sources rejects unknown link status and storage without approval', async () => {
    const db = await migratedDb();
    await db.exec(SOURCE);
    await assert.rejects(db.exec(`update cisce_sources set link_status = 'MAYBE'`));
    await assert.rejects(db.exec(`update cisce_sources set storage = 'CLOUDINARY_PRIVATE'`));
    await db.exec(`update cisce_sources set storage = 'CLOUDINARY_PRIVATE', storage_approved_by = 'owner'`);
  });

  test('nodes are pinned to curriculum_id cisce and need an approver to be approved', async () => {
    const db = await migratedDb();
    await db.exec(SOURCE);
    const node = (over = '') => `insert into cisce_curriculum_nodes (id, version, programme, source_id, source_sha256,
      grade_label, grade_number, subject, level, ordinal, path, title, provenance_status, content_hash ${over ? ', ' + over.split('=')[0] : ''})
      values (gen_random_uuid(), 'icse-2028', 'ICSE', 'icse-2028-physics', 'abc', 'Class IX', 9, 'Physics', 'UNIT', 1, '1',
      'Force', 'VERIFIED_OFFICIAL', 'h' ${over ? ', ' + over.split('=')[1] : ''})`;
    await db.exec(node());
    await assert.rejects(db.exec(node(`curriculum_id='icse'`)));
    await assert.rejects(db.exec(node('approved=true')));
  });

  test('coverage only accepts the defined statuses', async () => {
    const db = await migratedDb();
    await db.exec(`insert into cisce_ingestion_runs (run_id) values ('r1')`);
    await db.exec(`insert into cisce_coverage (run_id, grade_label, subject, status) values ('r1', 'Class I', 'All subjects', 'OFFICIAL_PARTIAL')`);
    await assert.rejects(db.exec(`insert into cisce_coverage (run_id, grade_label, subject, status) values ('r1', 'Class II', 'x', 'DONE')`));
  });
});

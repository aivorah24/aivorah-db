// Runs migration 0006 against real Postgres (PGlite) on a minimal stub of the baseline tables it depends on.
const { test, describe, before } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MIGRATION = fs.readFileSync(
  path.join(__dirname, '..', 'supabase', 'migrations', '0006_notifications_v2.sql'), 'utf8');

const STUB = `
  create role anon; create role authenticated; create role service_role;
  create table users (id uuid primary key default gen_random_uuid(), email text unique, name text, role text);
  create table parent_children (id uuid primary key default gen_random_uuid(), parent_email text not null,
    child_id uuid not null references users(id) on delete cascade, unique (parent_email, child_id));
  create table challenge_assignments (id text primary key, challenge_id text not null, student_id uuid not null
    references users(id) on delete cascade, status text not null default 'assigned',
    created_at timestamptz not null default now());
`;

const IDS = {
  asha:  '11111111-1111-1111-1111-111111111111',
  ravi:  '22222222-2222-2222-2222-222222222222',
  mom:   '33333333-3333-3333-3333-333333333333',
  dad:   '44444444-4444-4444-4444-444444444444',
  ghost: '99999999-9999-9999-9999-999999999999',
};

async function freshDb({ seedDuplicateAssignments = false } = {}) {
  const db = new PGlite();
  await db.exec(STUB);
  await db.exec(`
    insert into users (id, email, name, role) values
      ('${IDS.asha}', 'asha@x.com', 'Asha', 'student'),
      ('${IDS.ravi}', 'ravi@x.com', 'Ravi', 'student'),
      ('${IDS.mom}',  'mom@x.com',  'Mom',  'parent'),
      ('${IDS.dad}',  'dad@x.com',  'Dad',  'parent');
    insert into parent_children (parent_email, child_id) values
      ('mom@x.com', '${IDS.asha}'), ('dad@x.com', '${IDS.asha}'),
      ('mom@x.com', '${IDS.ravi}'), ('orphan@example.com', '${IDS.asha}');
    insert into challenge_assignments (id, challenge_id, student_id, created_at)
      values ('ca-old', 'ch1', '${IDS.asha}', '2026-09-01T10:00:00Z');
  `);
  if (seedDuplicateAssignments) {
    await db.exec(`insert into challenge_assignments (id, challenge_id, student_id) values ('ca-dup', 'ch1', '${IDS.asha}')`);
  }
  await db.exec(MIGRATION);
  return db;
}

const notify = async (db, event) =>
  (await db.query('select notify_event($1::jsonb) as r', [JSON.stringify(event)])).rows[0].r;

const challengeEvent = (overrides = {}) => ({
  type: 'challenge_assigned', entity_type: 'challenge_assignment', entity_id: 'ca-1',
  version: '2026-09-24T10:00:00.123Z', student_ids: [IDS.asha],
  actor_email: 'teacher@x.com', actor_role: 'teacher',
  title: 'New challenge: Motion', body: 'Science',
  parent_title: 'New challenge for {child}: Motion',
  data: { challengeId: 'ch-motion', challengeAssignmentId: 'ca-1' },
  ...overrides,
});

describe('notification_event_key', () => {
  let db;
  before(async () => { db = await freshDb(); });

  test('builds <type>:<entity_type>:<entity_id>:<epoch ms>', async () => {
    const { rows } = await db.query(
      `select notification_event_key('challenge_assigned', 'challenge_assignment', 'ca-1', '2026-09-24T10:00:00.123Z') k`);
    assert.equal(rows[0].k, 'challenge_assigned:challenge_assignment:ca-1:1790244000123');
  });

  test('appends the qualifier (due date) when given, ignores empty qualifier', async () => {
    const { rows } = await db.query(`select
      notification_event_key('challenge_due', 'challenge_assignment', 'ca-1', '2026-09-24T10:00:00Z', '2026-09-30') a,
      notification_event_key('challenge_due', 'challenge_assignment', 'ca-1', '2026-09-24T10:00:00Z', '') b`);
    assert.equal(rows[0].a, 'challenge_due:challenge_assignment:ca-1:1790244000000:2026-09-30');
    assert.equal(rows[0].b, 'challenge_due:challenge_assignment:ca-1:1790244000000');
  });

  test('sub-millisecond differences in the version map to the same key', async () => {
    const { rows } = await db.query(`select
      notification_event_key('t', 'assignment', 'a', '2026-09-24T10:00:00.123456Z') a,
      notification_event_key('t', 'assignment', 'a', '2026-09-24T10:00:00.123Z') b`);
    assert.equal(rows[0].a, rows[0].b);
  });
});

describe('notify_event fan-out', () => {
  test('creates one student row and one row per linked parent, with child context', async () => {
    const db = await freshDb();
    const r = await notify(db, challengeEvent());
    assert.equal(r.recipients, 3);
    assert.equal(r.inserted.length, 3);
    assert.equal(r.duplicates, 0);
    assert.equal(r.orphanParentLinks, 1);

    const { rows } = await db.query(`select recipient_id, recipient_role, child_id, title, data, event_key
      from notifications order by recipient_role, recipient_id`);
    const student = rows.find(x => x.recipient_role === 'student');
    assert.equal(student.recipient_id, IDS.asha);
    assert.equal(student.child_id, null);
    assert.equal(student.title, 'New challenge: Motion');
    assert.equal(student.event_key, 'challenge_assigned:challenge_assignment:ca-1:1790244000123');
    assert.deepEqual(student.data, { challengeId: 'ch-motion', challengeAssignmentId: 'ca-1' });

    const parents = rows.filter(x => x.recipient_role === 'parent');
    assert.deepEqual(parents.map(p => p.recipient_id).sort(), [IDS.mom, IDS.dad].sort());
    for (const p of parents) {
      assert.equal(p.child_id, IDS.asha);
      assert.equal(p.title, 'New challenge for Asha: Motion');
      assert.equal(p.data.childId, IDS.asha);
      assert.equal(p.event_key, `${student.event_key}:child=${IDS.asha}`);
    }
  });

  test('is idempotent: the same event twice creates no duplicates', async () => {
    const db = await freshDb();
    await notify(db, challengeEvent());
    const again = await notify(db, challengeEvent());
    assert.equal(again.inserted.length, 0);
    assert.equal(again.duplicates, 3);
    const { rows } = await db.query('select count(*)::int n from notifications');
    assert.equal(rows[0].n, 3);
  });

  test('a new version (legitimate re-assignment) creates a new notification per recipient', async () => {
    const db = await freshDb();
    await notify(db, challengeEvent());
    const reassigned = await notify(db, challengeEvent({ version: '2026-10-01T09:00:00Z' }));
    assert.equal(reassigned.inserted.length, 3);
    const { rows } = await db.query(`select count(*)::int n from notifications where recipient_id = '${IDS.asha}'`);
    assert.equal(rows[0].n, 2);
  });

  test('excludes the parent who performed the action', async () => {
    const db = await freshDb();
    const r = await notify(db, challengeEvent({ actor_email: 'MOM@x.com', actor_role: 'parent' }));
    const { rows } = await db.query('select recipient_id from notifications');
    assert.deepEqual(rows.map(x => x.recipient_id).sort(), [IDS.asha, IDS.dad].sort());
    assert.equal(r.recipients, 2);
  });

  test('notify_parents=false notifies only the student', async () => {
    const db = await freshDb();
    const r = await notify(db, challengeEvent({ notify_parents: false }));
    assert.equal(r.inserted.length, 1);
    assert.equal(r.orphanParentLinks, 0);
  });

  test('class-wide: a parent of two recipients gets one notification per child', async () => {
    const db = await freshDb();
    const r = await notify(db, {
      type: 'assignment_assigned', entity_type: 'assignment', entity_id: 'as-1',
      version: '2026-09-24T10:00:00Z', student_ids: [IDS.asha, IDS.ravi],
      title: 'New assignment: Fractions', parent_title: '{child}: New assignment',
    });
    assert.equal(r.inserted.length, 5); // asha, ravi, mom×2, dad×1
    const { rows } = await db.query(`select child_id, title from notifications
      where recipient_id = '${IDS.mom}' order by title`);
    assert.deepEqual(rows.map(x => x.title), ['Asha: New assignment', 'Ravi: New assignment']);
  });

  test('student ids with no users row are skipped without failing the event', async () => {
    const db = await freshDb();
    const r = await notify(db, challengeEvent({ student_ids: [IDS.ghost] }));
    assert.equal(r.recipients, 0);
    assert.equal(r.inserted.length, 0);
  });

  test('duplicate student ids in the input collapse to one recipient', async () => {
    const db = await freshDb();
    const r = await notify(db, challengeEvent({ student_ids: [IDS.asha, IDS.asha], notify_parents: false }));
    assert.equal(r.inserted.length, 1);
  });

  test('rejects an event with no title or no students', async () => {
    const db = await freshDb();
    await assert.rejects(notify(db, challengeEvent({ title: '  ' })), /required/);
    await assert.rejects(notify(db, challengeEvent({ student_ids: [] })), /non-empty/);
  });

  test('rejects an unknown notification type via the table constraint', async () => {
    const db = await freshDb();
    await assert.rejects(notify(db, challengeEvent({ type: 'made_up' })), /check constraint/);
  });
});

describe('schema constraints', () => {
  test('backfills assigned_at from created_at and defaults it for new rows', async () => {
    const db = await freshDb();
    const { rows } = await db.query(`select assigned_at = created_at same from challenge_assignments where id = 'ca-old'`);
    assert.equal(rows[0].same, true);
    await db.exec(`insert into challenge_assignments (id, challenge_id, student_id) values ('ca-new', 'ch2', '${IDS.asha}')`);
    const n = await db.query(`select assigned_at is not null ok from challenge_assignments where id = 'ca-new'`);
    assert.equal(n.rows[0].ok, true);
  });

  test('blocks a second (challenge_id, student_id) row', async () => {
    const db = await freshDb();
    await assert.rejects(
      db.exec(`insert into challenge_assignments (id, challenge_id, student_id) values ('ca-2', 'ch1', '${IDS.asha}')`),
      /challenge_assignments_challenge_student_uniq/);
  });

  test('migration refuses to run when duplicate assignment pairs already exist', async () => {
    await assert.rejects(freshDb({ seedDuplicateAssignments: true }), /dedupe before applying 0006/);
  });

  test('parent notifications must carry child_id', async () => {
    const db = await freshDb();
    await assert.rejects(db.exec(`insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key)
      values ('${IDS.mom}', 'parent', 'challenge_assigned', 'challenge_assignment', 'x', 't', 'k')`),
      /notifications_parent_has_child/);
  });

  test('deleting a user removes their notifications', async () => {
    const db = await freshDb();
    await notify(db, challengeEvent());
    await db.exec(`delete from users where id = '${IDS.dad}'`);
    const { rows } = await db.query(`select count(*)::int n from notifications where recipient_id = '${IDS.dad}'`);
    assert.equal(rows[0].n, 0);
  });
});

describe('feed keyset pagination (same predicate the API sends)', () => {
  test('pages through tied timestamps newest-first with no gaps or repeats', async () => {
    const db = await freshDb();
    await db.exec(`insert into notifications (recipient_id, recipient_role, type, entity_type, entity_id, title, event_key, created_at)
      select '${IDS.asha}', 'student', 'assignment_assigned', 'assignment', 'a' || g, 'T' || g, 'k' || g,
             case when g <= 3 then '2026-09-24T10:00:00.5Z'::timestamptz else '2026-09-24T09:00:00Z'::timestamptz + (g || ' seconds')::interval end
        from generate_series(1, 7) g`);
    const all = (await db.query(`select id, created_at from notifications order by created_at desc, id desc`)).rows;

    const seen = [];
    let cursor = null;
    for (let page = 0; page < 10; page++) {
      const { rows } = await db.query(
        `select id, created_at from notifications
          where recipient_id = $1
            and ($2::timestamptz is null or created_at < $2 or (created_at = $2 and id < $3::uuid))
          order by created_at desc, id desc limit 2`,
        [IDS.asha, cursor?.c ?? null, cursor?.i ?? null]);
      seen.push(...rows);
      if (rows.length < 2) break;
      const last = rows[rows.length - 1];
      cursor = { c: last.created_at, i: last.id };
    }
    assert.deepEqual(seen.map(r => r.id), all.map(r => r.id));
    assert.equal(new Set(seen.map(r => r.id)).size, 7);
  });
});

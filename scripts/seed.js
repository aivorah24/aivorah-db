// Seed a NON-PRODUCTION environment with synthetic data.
//   node scripts/seed.js dev
//   node scripts/seed.js test
//
// Production is refused outright — seeds are synthetic and must never touch real data.
const path = require('path');
const { resolveEnv, query, readSqlWithIncludes, fail } = require('./lib');

const envName = process.argv[2];
if (!envName) fail('Usage: node scripts/seed.js <dev|test>');
if (envName === 'prod') fail('Refusing to seed production. Seeds are synthetic data and must never run against aivorah-prod.');

const target = resolveEnv(envName);
const seedFile = path.join(__dirname, '..', 'supabase', 'seed', `${envName}_seed.sql`);

(async () => {
  // The seed file itself guards on this setting, so a stray copy/paste into the
  // SQL editor of the wrong project fails closed rather than inserting rows.
  const sql = `set local aivorah.allow_seed = 'yes';\n\n${readSqlWithIncludes(seedFile)}`;

  console.log(`Seeding ${target.label} (${target.ref}) from ${path.basename(seedFile)}`);
  await query(target.ref, sql);

  const [counts] = await query(target.ref, `select
      (select count(*) from public.users) as users,
      (select count(*) from public.schools) as schools,
      (select count(*) from public.teacher_student) as teacher_links,
      (select count(*) from public.parent_student) as parent_links,
      (select count(*) from public.student_stats) as stats`);
  console.log('Done:', counts);
})().catch((e) => fail(e.message));

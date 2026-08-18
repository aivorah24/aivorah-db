// Apply pending migrations to an environment, in filename order.
//   node scripts/migrate.js dev
//   node scripts/migrate.js test
//   node scripts/migrate.js prod --confirm-prod
//
// Promotion order is always dev -> test -> prod. Applying to prod requires the
// explicit --confirm-prod flag so it can never happen by reflex or by script.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { resolveEnv, query, fail } = require('./lib');

const envName = process.argv[2];
if (!envName) fail('Usage: node scripts/migrate.js <dev|test|prod> [--confirm-prod]');
if (envName === 'prod' && !process.argv.includes('--confirm-prod')) {
  fail('Refusing to touch production without --confirm-prod. Apply to dev and test first.');
}

const target = resolveEnv(envName);
const dir = path.join(__dirname, '..', 'supabase', 'migrations');

(async () => {
  // Ledger of what has already run, so migrations are applied exactly once.
  // It lives in `public` (the only schema the Management API exposes by default),
  // so its default anon/authenticated grants are stripped and RLS is switched on —
  // nothing but the service role has any business reading it.
  await query(target.ref, `create table if not exists public.schema_migrations (
      version text primary key,
      checksum text not null,
      applied_at timestamptz not null default now()
    );
    revoke all on public.schema_migrations from anon, authenticated;
    alter table public.schema_migrations enable row level security;`);

  const applied = Object.fromEntries(
    (await query(target.ref, `select version, checksum from public.schema_migrations`))
      .map((r) => [r.version, r.checksum])
  );

  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  let ran = 0;

  for (const file of files) {
    const version = file.replace(/\.sql$/, '');
    // Normalize CRLF -> LF before hashing/applying so a Windows checkout and a
    // Unix checkout of the identical file produce the identical checksum.
    const sql = fs.readFileSync(path.join(dir, file), 'utf8').replace(/\r\n/g, '\n');
    const checksum = crypto.createHash('sha256').update(sql).digest('hex');

    if (applied[version]) {
      if (applied[version] !== checksum) {
        fail(`${file} was already applied to ${target.label} but its contents have changed.\n` +
             `Migrations are immutable once applied — add a new migration instead of editing this one.`);
      }
      console.log(`  skip   ${file} (already applied)`);
      continue;
    }

    console.log(`  apply  ${file}`);
    await query(target.ref, sql);
    await query(target.ref,
      `insert into public.schema_migrations (version, checksum) values ('${version}', '${checksum}')`);
    ran++;
  }

  console.log(ran ? `Applied ${ran} migration(s) to ${target.label}.` : `${target.label} is already up to date.`);
})().catch((e) => fail(e.message));

// Deep schema fingerprint comparison between Supabase projects
const TOKEN = process.env.SUPABASE_ACCESS_TOKEN;
const fs = require('fs');
const lines = [];
const log = (s = '') => { console.log(s); lines.push(s); };

const PROJECTS = {
  PROD: process.env.PROD_REF,
  DEV: process.env.DEV_REF,
  TEST: process.env.TEST_REF,
};
for (const [k, v] of Object.entries(PROJECTS)) {
  if (!v) { console.error(`Missing env ${k}_REF — see .env.example`); process.exit(1); }
}

const QUERIES = {
  columns: `select c.relname||'.'||a.attname||' :: '||pg_catalog.format_type(a.atttypid,a.atttypmod)
      ||' notnull='||a.attnotnull||' default='||coalesce(pg_get_expr(d.adbin,d.adrelid),'-')
      ||' identity='||coalesce(nullif(a.attidentity::text,''),'-')||' generated='||coalesce(nullif(a.attgenerated::text,''),'-') as sig
    from pg_attribute a
    join pg_class c on c.oid=a.attrelid
    join pg_namespace n on n.oid=c.relnamespace
    left join pg_attrdef d on d.adrelid=a.attrelid and d.adnum=a.attnum
    where n.nspname='public' and c.relkind='r' and a.attnum>0 and not a.attisdropped
    order by 1`,
  constraints: `select c.relname||' | '||con.conname||' | '||pg_get_constraintdef(con.oid) as sig
    from pg_constraint con join pg_class c on c.oid=con.conrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='r' order by 1`,
  indexes: `select indexdef as sig from pg_indexes where schemaname='public' order by 1`,
  policies: `select tablename||' | '||policyname||' | '||cmd||' | '||coalesce(roles::text,'-')
      ||' | using='||coalesce(qual,'-')||' | check='||coalesce(with_check,'-') as sig
    from pg_policies where schemaname='public' order by 1`,
  rls: `select c.relname||' rls='||c.relrowsecurity||' force='||c.relforcerowsecurity as sig
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='r' order by 1`,
  functions: `select p.proname||' | '||md5(pg_get_functiondef(p.oid)) as sig
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind in ('f','p') order by 1`,
  enums: `select t.typname||' = '||string_agg(e.enumlabel,',' order by e.enumsortorder) as sig
    from pg_type t join pg_enum e on e.enumtypid=t.oid join pg_namespace n on n.oid=t.typnamespace
    where n.nspname='public' group by t.typname order by 1`,
  extensions: `select extname as sig from pg_extension order by 1`,
  sequences: `select sequence_name as sig from information_schema.sequences where sequence_schema='public' order by 1`,
  buckets: `select id||' public='||public as sig from storage.buckets order by 1`,
  views: `select table_name||' | '||md5(view_definition) as sig
    from information_schema.views where table_schema='public' order by 1`,
  triggers: `select c.relname||' | '||t.tgname||' | '||md5(pg_get_triggerdef(t.oid)) as sig
    from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and not t.tgisinternal order by 1`,
  domains: `select t.typname||' | '||pg_catalog.format_type(t.typbasetype,t.typtypmod)
      ||' notnull='||t.typnotnull||' default='||coalesce(t.typdefault,'-') as sig
    from pg_type t join pg_namespace n on n.oid=t.typnamespace
    where n.nspname='public' and t.typtype='d' order by 1`,
  grants: `select sig from (
      select table_name||' | '||grantee||' | '||string_agg(privilege_type,',' order by privilege_type) as sig
      from information_schema.role_table_grants
      where table_schema='public' and grantee in ('anon','authenticated','service_role')
      group by table_name, grantee
    ) t order by sig`,
};

async function q(ref, sql) {
  const r = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: sql }),
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`${ref} HTTP ${r.status}: ${t.slice(0, 300)}`);
  // schema_migrations is this repo's own bookkeeping, not application schema.
  // It exists wherever migrate.js has run, so comparing it is pure noise.
  return JSON.parse(t)
    .map((row) => row.sig)
    .filter((sig) => !/\bschema_migrations\b/.test(sig));
}

(async () => {
  const snap = {};
  for (const [name, ref] of Object.entries(PROJECTS)) {
    snap[name] = {};
    for (const [k, sql] of Object.entries(QUERIES)) snap[name][k] = await q(ref, sql);
  }

  let allMatch = true;
  for (const target of ['DEV', 'TEST']) {
    log(`\n===== PROD vs ${target} =====`);
    for (const k of Object.keys(QUERIES)) {
      const a = snap.PROD[k], b = snap[target][k];
      const setB = new Set(b), setA = new Set(a);
      const missing = a.filter((x) => !setB.has(x));
      const extra = b.filter((x) => !setA.has(x));
      if (!missing.length && !extra.length) {
        log(`  MATCH  ${k.padEnd(12)} (${a.length})`);
      } else {
        allMatch = false;
        log(`  DIFF   ${k.padEnd(12)} prod=${a.length} ${target.toLowerCase()}=${b.length}`);
        missing.slice(0, 8).forEach((m) => log(`     missing in ${target}: ${m.slice(0, 160)}`));
        extra.slice(0, 8).forEach((m) => log(`     extra   in ${target}: ${m.slice(0, 160)}`));
        if (missing.length > 8) log(`     ...+${missing.length - 8} more missing`);
        if (extra.length > 8) log(`     ...+${extra.length - 8} more extra`);
      }
    }
  }

  // Row counts — confirm no prod data leaked into dev/test
  // Dev/test should hold only seeded rows (tens), never a production-sized dataset.
  // A count in the thousands here means production data has leaked in.
  log('\n===== ROW COUNTS =====');
  const rowSql = `select coalesce(sum(n_live_tup),0)::text as sig from pg_stat_user_tables where schemaname='public'`;
  for (const [name, ref] of Object.entries(PROJECTS)) {
    log(`  ${name.padEnd(5)} approx rows in public: ${(await q(ref, rowSql))[0]}`);
  }
  const authSql = `select count(*)::text as sig from auth.users`;
  for (const [name, ref] of Object.entries(PROJECTS)) {
    log(`  ${name.padEnd(5)} auth.users: ${(await q(ref, authSql))[0]}`);
  }

  log(`\n===== VERDICT: ${allMatch ? 'SCHEMA IDENTICAL' : 'DIFFERENCES FOUND'} =====`);
  fs.writeFileSync('schema-compare-report.txt', lines.join('\n') + '\n');
  if (!allMatch) process.exit(1);
})().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });

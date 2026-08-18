// Shared helpers for aivorah-db scripts.
const fs = require('fs');
const path = require('path');

const ENVS = {
  dev:  { refEnv: 'DEV_REF',  label: 'aivorah-dev' },
  test: { refEnv: 'TEST_REF', label: 'aivorah-test' },
  prod: { refEnv: 'PROD_REF', label: 'aivorah-prod' },
};

function token() {
  const t = process.env.SUPABASE_ACCESS_TOKEN;
  if (!t) fail('SUPABASE_ACCESS_TOKEN is not set. Generate one at https://supabase.com/dashboard/account/tokens');
  return t;
}

function resolveEnv(name) {
  const e = ENVS[name];
  if (!e) fail(`Unknown environment "${name}". Use one of: ${Object.keys(ENVS).join(', ')}`);
  const ref = process.env[e.refEnv];
  if (!ref) fail(`Missing env var ${e.refEnv}. Copy .env.example and fill it in.`);
  return { name, ref, label: e.label };
}

async function query(ref, sql) {
  const r = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: sql }),
  });
  const body = await r.text();
  if (!r.ok) throw new Error(`HTTP ${r.status}: ${body.slice(0, 600)}`);
  return JSON.parse(body);
}

// Resolves "-- @include other.sql" directives relative to the file's own directory.
function readSqlWithIncludes(file, seen = new Set()) {
  const abs = path.resolve(file);
  if (seen.has(abs)) fail(`Circular @include detected at ${abs}`);
  seen.add(abs);
  return fs.readFileSync(abs, 'utf8').replace(/^--\s*@include\s+(\S+)\s*$/gm, (_, inc) =>
    readSqlWithIncludes(path.join(path.dirname(abs), inc), seen)
  );
}

function fail(msg) {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

module.exports = { ENVS, token, resolveEnv, query, readSqlWithIncludes, fail };

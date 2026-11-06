# aivorah-db

Single source of truth for the Aivorah database schema.

One Supabase database is shared by every Aivorah microservice, so the schema
belongs to none of them individually — it lives here.

## Environments

| Env  | Project   | Ref                    | Region | Purpose |
|------|-----------|------------------------|--------|---------|
| Dev  | `Dev DB`  | `evlqkcozespsfrnuhevf` | ap-southeast-2 | Development. Free plan: pauses after a week idle (resume in the dashboard). |
| Test | `Test DB` | `xmwzifxlpmgsrxgxsgan` | ap-southeast-1 | **Live today:** every Render service and real pilot users use this project. |
| Prod | `aivorah-prod` | `jwlepxmclbkrmfzrumch` | — | Future production. No service uses it yet. |

## Migration status

Checked 2026-11-03: **Dev and Test both have all 22 migrations applied and recorded** in `public.schema_migrations`, with matching checksums. `migrate.js dev` and `migrate.js test` report "already up to date".

Some numbers are used twice (`0008_*`, `0009_*`, `0017_*`). That is intentional and safe: the ledger key is the full file name. Never rename an applied file. The next migration is **`0021_…`**.

## Rules

1. **No schema changes in the Supabase dashboard.** Every change is a migration file in this repo.
2. **Migrations are immutable.** Once applied, never edit a migration — add a new one. `migrate.js` enforces this with checksums.
3. **Promotion order is always Dev → Test → Prod.** Never prod first.
4. **Every change goes through a PR.** No direct pushes to `main`.
5. **Seeds are synthetic only.** Never copy production data into dev or test — it contains real student, parent and teacher records.

## Setup

```bash
cp .env.example .env    # then paste your access token into .env
```

Node 18+ is required (uses the built-in `fetch`). There are no dependencies to install.

## Usage

```bash
node scripts/migrate.js dev          # apply pending migrations to dev
node scripts/migrate.js test         # then test
node scripts/migrate.js prod --confirm-prod   # only after test passes

node scripts/seed.js dev             # load synthetic data
node scripts/seed.js test

node scripts/compare-schema.js       # verify dev/test still match prod
```

`compare-schema.js` diffs columns, constraints, indexes, policies, RLS flags,
functions, enums, extensions, sequences, storage buckets and grants across all
three projects, and reports row counts so data leakage into dev/test is visible.

## Adding a change

1. Write `supabase/migrations/000N_short_description.sql`.
2. `node scripts/migrate.js dev` — confirm it applies cleanly.
3. `node scripts/compare-schema.js` — dev will now differ from prod. That difference is your change; read it and confirm it is exactly what you intended.
4. `node scripts/migrate.js test`, then run the e2e suite against test.
5. Open a PR. Include the compare output in the description.
6. After review and merge: `node scripts/migrate.js prod --confirm-prod`.
7. `node scripts/compare-schema.js` — all three should match again.

## Layout

```
supabase/
  migrations/
    0001_baseline.sql      Full schema as extracted from production 2026-08-18
  seed/
    _common_seed.sql       Shared synthetic dataset (schools, users, relationships)
    dev_seed.sql           Dev-only additions
    test_seed.sql          Dedicated per-test e2e accounts
scripts/
  lib.js                   Shared helpers (Management API, @include resolution)
  migrate.js               Apply migrations, with a checksum ledger
  seed.js                  Load seed data (refuses prod)
  compare-schema.js        Deep schema diff across environments
  dump-schema.js           Regenerate a baseline from a live project
```

## About `0001_baseline.sql`

Extracted from production on 2026-08-18 and verified before commit:

- Applied to dev and test, then diffed against prod across all 11 dimensions — identical (506 columns, 140 constraints, 134 indexes, 4 policies, 55 RLS flags, 2 functions, 5 enums, 5 extensions, 1 sequence, 2 storage buckets, 165 grants).
- Contains **no production data** — the only `INSERT` statements are parameterised writes inside function bodies. Dev and test both report 0 rows and 0 auth users.
- Contains no credentials, emails or phone numbers.

It is a *baseline*, not a from-scratch history: production predates this repo, so
`0001` describes the schema as it already existed. Prod should be marked as
having this migration applied (see below) rather than having it run against it.

### Marking prod as already at baseline

Prod already has this schema, so the baseline must be recorded, not executed:

```sql
create table if not exists public.schema_migrations (
  version text primary key,
  checksum text not null,
  applied_at timestamptz not null default now()
);
insert into public.schema_migrations (version, checksum)
values ('0001_baseline', '<sha256 of the file>')
on conflict (version) do nothing;
```

Run this against prod **once**, deliberately, after the PR is merged.

## Not covered here

- **Auth users** are not seeded. Dev and test have empty `auth.users`; create test
  logins through the app's signup flow or the Supabase dashboard.
- **Storage file contents** are not copied — only the buckets
  (`challenge-thumbnails`, `ncert-books`) are created.
- **Edge functions** and project settings (SMTP, auth providers, redirect URLs)
  are configured per project in the dashboard and are not tracked here yet.

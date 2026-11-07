-- Face login (aivorah-auth-service /user/passkeys): WebAuthn passkeys. The
-- face / fingerprint check happens on the user's own device; Aivorah stores
-- only each device's credential id and PUBLIC key - no biometric data.
-- Read and written by the service role only.

create table if not exists "public"."user_passkeys" (
  "id" uuid primary key default gen_random_uuid(),
  "user_id" uuid not null references "public"."users"(id) on delete cascade,
  "credential_id" text not null unique,   -- base64url, as the browser reports it
  "public_key" text not null,             -- base64url COSE public key
  "counter" bigint not null default 0,    -- signature counter (clone detection)
  "transports" text[] not null default '{}',
  "device_label" text,
  "created_at" timestamptz not null default now(),
  "last_used_at" timestamptz
);

create index if not exists user_passkeys_user_idx on "public"."user_passkeys" (user_id);

alter table "public"."user_passkeys" enable row level security;
revoke all on "public"."user_passkeys" from anon, authenticated;

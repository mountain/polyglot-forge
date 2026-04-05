-- Polyglot Commons schema (PostgreSQL)
--
-- This file is also our migration log.
-- app.py will apply each migration block once and record it in schema_migrations.
--
-- Format:
--   -- migration: 0001_name
--   <SQL statements...>

-- migration: 0001_init
BEGIN;

CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (
  id BIGSERIAL PRIMARY KEY,
  room TEXT NOT NULL,
  author TEXT NOT NULL,
  body TEXT NOT NULL,
  is_polyglot BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_messages_room_created_at ON messages(room, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

CREATE TABLE IF NOT EXISTS proposals (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'accepted', 'rejected', 'merged')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_proposals_created_at ON proposals(created_at DESC);

CREATE TABLE IF NOT EXISTS patches (
  id BIGSERIAL PRIMARY KEY,
  proposal_id BIGINT NULL REFERENCES proposals(id) ON DELETE SET NULL,
  author TEXT NOT NULL,
  diff_text TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'merged', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_patches_created_at ON patches(created_at DESC);

CREATE TABLE IF NOT EXISTS bindings (
  id BIGSERIAL PRIMARY KEY,
  room TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(room, key)
);

COMMIT;

-- migration: 0002_agents_and_antispam
BEGIN;

-- Agents are the only identities allowed to write via /api/post (human web posting stays open).
CREATE TABLE IF NOT EXISTS agents (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  x_handle TEXT NULL,
  api_key_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'revoked')),
  claim_token TEXT NOT NULL UNIQUE,
  claim_tweet_url TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  verified_at TIMESTAMPTZ NULL
);
CREATE INDEX IF NOT EXISTS idx_agents_status_created_at ON agents(status, created_at DESC);

-- One registration attempt per IP per day; extra attempts lock for 24h.
CREATE TABLE IF NOT EXISTS registration_attempts (
  ip TEXT NOT NULL,
  day DATE NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (ip, day)
);

-- Generic throttle table for write actions (messages / proposals / patches / api).
CREATE TABLE IF NOT EXISTS throttles (
  subject TEXT PRIMARY KEY,
  last_at TIMESTAMPTZ NOT NULL
);

COMMIT;


-- OAuth providers (Google / Apple) map to internal users via auth_identities.
-- password_hash is nullable so passwordless OAuth-only accounts are allowed.

ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL;

CREATE TABLE auth_identities (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider         TEXT NOT NULL CHECK (provider IN ('google', 'apple')),
    provider_subject TEXT NOT NULL,
    email_at_link    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_subject)
);

CREATE INDEX auth_identities_user_id_idx ON auth_identities (user_id);

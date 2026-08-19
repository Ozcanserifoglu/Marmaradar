CREATE TABLE user_reputation (
    user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    xp           BIGINT NOT NULL DEFAULT 0,
    rank_code    TEXT NOT NULL DEFAULT 'caylak',
    level        INT NOT NULL DEFAULT 1,
    elo_rating   DOUBLE PRECISION NOT NULL DEFAULT 1000,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_rank_history (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_rank_code  TEXT,
    to_rank_code    TEXT NOT NULL,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_rank_history_user_changed
    ON user_rank_history (user_id, changed_at DESC);

CREATE TABLE user_streaks (
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    streak_type        TEXT NOT NULL,
    current_streak     INT NOT NULL DEFAULT 0,
    best_streak        INT NOT NULL DEFAULT 0,
    last_activity_day  DATE,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, streak_type)
);

CREATE TABLE user_reputation_events (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_key   TEXT NOT NULL UNIQUE,
    reason      TEXT NOT NULL,
    xp_delta    BIGINT NOT NULL DEFAULT 0,
    elo_delta   DOUBLE PRECISION NOT NULL DEFAULT 0,
    metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_reputation_events_user_created
    ON user_reputation_events (user_id, created_at DESC);

CREATE TABLE first_responder_awards (
    report_type  TEXT PRIMARY KEY,
    report_id    UUID NOT NULL UNIQUE REFERENCES user_reports(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    awarded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS live_reports_submitted INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS live_confirmations_given INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS live_drivers_saved INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS night_reports_submitted INT NOT NULL DEFAULT 0;

ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '2 hours');
ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS verification_state TEXT NOT NULL DEFAULT 'pending'
        CHECK (verification_state IN ('pending', 'confirmed', 'rejected', 'expired'));
ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS weighted_up_score DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS weighted_down_score DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS weighted_score DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE user_reports
    ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;

UPDATE user_reports
SET expires_at = created_at + interval '2 hours',
    verification_state = CASE
        WHEN created_at < now() - interval '2 hours' THEN 'expired'
        ELSE 'pending'
    END,
    settled_at = CASE
        WHEN created_at < now() - interval '2 hours' THEN now()
        ELSE settled_at
    END
WHERE expires_at IS NULL
   OR verification_state = 'pending';

CREATE INDEX idx_user_reports_state_expires
    ON user_reports (verification_state, expires_at);
CREATE INDEX idx_user_reports_score_state
    ON user_reports (verification_state, weighted_score, created_at DESC);

ALTER TABLE report_votes
    ADD COLUMN IF NOT EXISTS vote_weight DOUBLE PRECISION NOT NULL DEFAULT 1;
ALTER TABLE report_votes
    ADD COLUMN IF NOT EXISTS voter_rank_code TEXT NOT NULL DEFAULT 'caylak';
ALTER TABLE report_votes
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE report_votes
SET updated_at = COALESCE(updated_at, created_at),
    vote_weight = COALESCE(vote_weight, 1),
    voter_rank_code = COALESCE(NULLIF(voter_rank_code, ''), 'caylak');

CREATE INDEX idx_report_votes_report_updated
    ON report_votes (report_id, updated_at DESC);

INSERT INTO user_reputation (user_id, xp, rank_code, level, elo_rating, updated_at)
SELECT
    us.user_id,
    GREATEST(
        FLOOR(us.total_distance_m / 1000)::BIGINT
        + (us.total_drives * 5)::BIGINT
        + (us.reports_submitted * 25)::BIGINT
        + (us.confirmations_given * 10)::BIGINT
        + (us.drivers_saved * 20)::BIGINT,
        0
    ) AS xp,
    CASE
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 4000 THEN 'radar_avcisi'
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 1500 THEN 'yolun_hakimi'
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 500 THEN 'gozcu'
        ELSE 'caylak'
    END,
    CASE
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 4000 THEN 4
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 1500 THEN 3
        WHEN GREATEST(
            FLOOR(us.total_distance_m / 1000)::BIGINT
            + (us.total_drives * 5)::BIGINT
            + (us.reports_submitted * 25)::BIGINT
            + (us.confirmations_given * 10)::BIGINT
            + (us.drivers_saved * 20)::BIGINT,
            0
        ) >= 500 THEN 2
        ELSE 1
    END,
    1000,
    now()
FROM user_stats us
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_rank_history (user_id, from_rank_code, to_rank_code, changed_at)
SELECT ur.user_id, NULL, ur.rank_code, now()
FROM user_reputation ur
ON CONFLICT DO NOTHING;

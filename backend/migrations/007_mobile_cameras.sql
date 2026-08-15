-- Crowdsourced mobile cameras (TTL + confidence) and report gamification counters.

CREATE TABLE mobile_cameras (
    id                 BIGSERIAL PRIMARY KEY,
    reporter_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    region_code        TEXT NOT NULL REFERENCES regions(code),
    location           GEOGRAPHY(POINT, 4326) NOT NULL,
    heading_deg        REAL,
    status             TEXT NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'expired', 'removed')),
    confidence_score   REAL NOT NULL DEFAULT 0.35
                       CHECK (confidence_score BETWEEN 0 AND 1),
    upvotes            INT NOT NULL DEFAULT 0 CHECK (upvotes >= 0),
    downvotes          INT NOT NULL DEFAULT 0 CHECK (downvotes >= 0),
    expires_at         TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '3 hours'),
    last_confirmed_at  TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mobile_cameras_location ON mobile_cameras USING GIST (location);
CREATE INDEX idx_mobile_cameras_active_expires
    ON mobile_cameras (expires_at)
    WHERE status = 'active';
CREATE INDEX idx_mobile_cameras_reporter ON mobile_cameras (reporter_id);
CREATE INDEX idx_mobile_cameras_region_status
    ON mobile_cameras (region_code, status);

CREATE TABLE mobile_camera_votes (
    camera_id   BIGINT NOT NULL REFERENCES mobile_cameras(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    value       SMALLINT NOT NULL CHECK (value IN (-1, 1)),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (camera_id, user_id)
);

CREATE INDEX idx_mobile_camera_votes_user ON mobile_camera_votes (user_id);

ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS reports_submitted INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS confirmations_given INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS drivers_saved INT NOT NULL DEFAULT 0;
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS fake_reports INT NOT NULL DEFAULT 0;

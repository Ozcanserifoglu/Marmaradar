-- Public display name for leaderboards / profile.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS username TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_lower
    ON users (lower(username))
    WHERE username IS NOT NULL;

-- Lifetime verified community contributions for the reports leaderboard.
-- Counts: non-removed mobile cameras + confirmed live reports.
ALTER TABLE user_stats
    ADD COLUMN IF NOT EXISTS valid_contributions INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_user_stats_distance_desc
    ON user_stats (total_distance_m DESC)
    WHERE total_distance_m > 0;

CREATE INDEX IF NOT EXISTS idx_user_stats_contributions_desc
    ON user_stats (valid_contributions DESC)
    WHERE valid_contributions > 0;

-- Ensure stats rows exist for users who only contributed reports.
INSERT INTO user_stats (user_id, updated_at)
SELECT DISTINCT reporter_id, now()
FROM mobile_cameras
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_stats (user_id, updated_at)
SELECT DISTINCT user_id, now()
FROM user_reports
ON CONFLICT (user_id) DO NOTHING;

UPDATE user_stats us
SET valid_contributions = COALESCE((
        SELECT COUNT(*)::INT
        FROM mobile_cameras mc
        WHERE mc.reporter_id = us.user_id
          AND mc.status <> 'removed'
    ), 0) + COALESCE((
        SELECT COUNT(*)::INT
        FROM user_reports ur
        WHERE ur.user_id = us.user_id
          AND ur.verification_state = 'confirmed'
    ), 0),
    updated_at = now();

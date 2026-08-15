ALTER TABLE drives
    ADD COLUMN IF NOT EXISTS radars_encountered INT NOT NULL DEFAULT 0;

CREATE TABLE user_stats (
    user_id               UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_distance_m      DOUBLE PRECISION NOT NULL DEFAULT 0,
    total_drive_time_sec  BIGINT NOT NULL DEFAULT 0,
    total_drives          INT NOT NULL DEFAULT 0,
    radars_encountered    INT NOT NULL DEFAULT 0,
    night_drives          INT NOT NULL DEFAULT 0,
    safe_drives           INT NOT NULL DEFAULT 0,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_camera_encounters (
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    camera_id    BIGINT NOT NULL REFERENCES fixed_cameras(id) ON DELETE CASCADE,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, camera_id)
);

CREATE INDEX idx_user_camera_encounters_user ON user_camera_encounters (user_id);

CREATE TABLE user_achievements (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code        TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, code)
);

CREATE INDEX idx_user_achievements_user ON user_achievements (user_id);

-- Per-drive radar counts from existing geometry.
UPDATE drives d
SET radars_encountered = (
    SELECT COUNT(*)::INT
    FROM fixed_cameras c
    WHERE c.active
      AND ST_DWithin(c.location, d.path, 150)
);

INSERT INTO user_camera_encounters (user_id, camera_id, first_seen_at)
SELECT d.user_id, c.id, MIN(d.started_at)
FROM drives d
JOIN fixed_cameras c
  ON c.active
 AND ST_DWithin(c.location, d.path, 150)
GROUP BY d.user_id, c.id
ON CONFLICT DO NOTHING;

INSERT INTO user_stats (
    user_id,
    total_distance_m,
    total_drive_time_sec,
    total_drives,
    radars_encountered,
    night_drives,
    safe_drives,
    updated_at
)
SELECT
    d.user_id,
    COALESCE(SUM(d.length_m), 0),
    COALESCE(SUM(EXTRACT(EPOCH FROM (d.ended_at - d.started_at)))::BIGINT, 0),
    COUNT(*)::INT,
    COALESCE((
        SELECT COUNT(*)::INT
        FROM user_camera_encounters e
        WHERE e.user_id = d.user_id
    ), 0),
    COUNT(*) FILTER (
        WHERE EXTRACT(HOUR FROM d.started_at AT TIME ZONE 'Europe/Istanbul') IN (22, 23, 0, 1, 2, 3, 4)
    )::INT,
    COUNT(*) FILTER (
        WHERE COALESCE((
            SELECT MAX((p->>'speed_mps')::DOUBLE PRECISION)
            FROM jsonb_array_elements(d.points) AS p
        ), 0) <= 36.111
    )::INT,
    now()
FROM drives d
GROUP BY d.user_id
ON CONFLICT (user_id) DO UPDATE SET
    total_distance_m = EXCLUDED.total_distance_m,
    total_drive_time_sec = EXCLUDED.total_drive_time_sec,
    total_drives = EXCLUDED.total_drives,
    radars_encountered = EXCLUDED.radars_encountered,
    night_drives = EXCLUDED.night_drives,
    safe_drives = EXCLUDED.safe_drives,
    updated_at = now();

INSERT INTO user_achievements (user_id, code, unlocked_at)
SELECT us.user_id, 'first_drive', now()
FROM user_stats us
WHERE us.total_drives >= 1
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (user_id, code, unlocked_at)
SELECT us.user_id, 'club_100km', now()
FROM user_stats us
WHERE us.total_distance_m >= 100000
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (user_id, code, unlocked_at)
SELECT us.user_id, 'night_rider', now()
FROM user_stats us
WHERE us.night_drives >= 5
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (user_id, code, unlocked_at)
SELECT us.user_id, 'safe_driver', now()
FROM user_stats us
WHERE us.safe_drives >= 10
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (user_id, code, unlocked_at)
SELECT us.user_id, 'radar_scout', now()
FROM user_stats us
WHERE us.radars_encountered >= 25
ON CONFLICT DO NOTHING;

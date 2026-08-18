-- Community live reports (police / accident). Rows are never deleted;
-- the API filters to the last 2 hours for map display.

CREATE TABLE user_reports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    report_type  TEXT NOT NULL CHECK (report_type IN ('police', 'accident')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_reports_created_at ON user_reports (created_at DESC);

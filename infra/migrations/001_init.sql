CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE regions (
    code        TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    bbox        GEOMETRY(POLYGON, 4326) NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE data_sources (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    source_url  TEXT,
    license     TEXT,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE import_runs (
    id               BIGSERIAL PRIMARY KEY,
    data_source_id   BIGINT REFERENCES data_sources(id),
    region_code      TEXT REFERENCES regions(code),
    status           TEXT NOT NULL CHECK (status IN ('running', 'success', 'failed')),
    records_in       INT DEFAULT 0,
    records_upserted INT DEFAULT 0,
    error_message    TEXT,
    started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at      TIMESTAMPTZ
);

CREATE TABLE fixed_cameras (
    id                      BIGSERIAL PRIMARY KEY,
    external_id             TEXT,
    region_code             TEXT NOT NULL REFERENCES regions(code),
    location                GEOGRAPHY(POINT, 4326) NOT NULL,
    road_name               TEXT,
    maxspeed_kmh            SMALLINT,
    direction_deg           SMALLINT CHECK (direction_deg BETWEEN 0 AND 359),
    direction_tolerance_deg SMALLINT NOT NULL DEFAULT 35,
    camera_type             TEXT NOT NULL DEFAULT 'fixed'
                            CHECK (camera_type IN ('fixed', 'mobile', 'red_light', 'unknown')),
    active                  BOOLEAN NOT NULL DEFAULT true,
    source_id               BIGINT REFERENCES data_sources(id),
    source_tags             JSONB NOT NULL DEFAULT '{}',
    confidence              REAL NOT NULL DEFAULT 0.5 CHECK (confidence BETWEEN 0 AND 1),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (region_code, external_id)
);

CREATE INDEX idx_fixed_cameras_location ON fixed_cameras USING GIST (location);
CREATE INDEX idx_fixed_cameras_region_active ON fixed_cameras (region_code) WHERE active;

CREATE TABLE speed_corridors (
    id               BIGSERIAL PRIMARY KEY,
    external_id      TEXT,
    region_code      TEXT NOT NULL REFERENCES regions(code),
    name             TEXT NOT NULL,
    route_polyline   GEOGRAPHY(LINESTRING, 4326),
    corridor_polygon GEOGRAPHY(POLYGON, 4326),
    length_m         DOUBLE PRECISION NOT NULL,
    maxspeed_kmh     SMALLINT NOT NULL,
    direction        TEXT NOT NULL DEFAULT 'both'
                       CHECK (direction IN ('both', 'forward', 'backward')),
    active           BOOLEAN NOT NULL DEFAULT true,
    source_id        BIGINT REFERENCES data_sources(id),
    metadata         JSONB NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (region_code, external_id)
);

CREATE INDEX idx_speed_corridors_polygon ON speed_corridors USING GIST (corridor_polygon);

CREATE TABLE corridor_gates (
    id            BIGSERIAL PRIMARY KEY,
    corridor_id   BIGINT NOT NULL REFERENCES speed_corridors(id) ON DELETE CASCADE,
    gate_type     TEXT NOT NULL CHECK (gate_type IN ('entry', 'exit')),
    location      GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_m      REAL NOT NULL DEFAULT 80,
    sequence      SMALLINT NOT NULL DEFAULT 0,
    direction_deg SMALLINT,
    UNIQUE (corridor_id, gate_type, sequence)
);

CREATE INDEX idx_corridor_gates_location ON corridor_gates USING GIST (location);

INSERT INTO regions (code, name, bbox) VALUES
  ('bursa', 'Bursa', ST_MakeEnvelope(28.75, 39.95, 29.55, 40.55, 4326)::geometry),
  ('istanbul', 'Istanbul', ST_MakeEnvelope(28.4, 40.8, 29.5, 41.35, 4326)::geometry),
  ('marmara', 'Marmara', ST_MakeEnvelope(27.5, 40.0, 30.5, 41.5, 4326)::geometry);

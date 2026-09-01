ALTER TABLE users
    ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
    ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(32) NOT NULL DEFAULT 'sedan',
    ADD COLUMN IF NOT EXISTS vehicle_color VARCHAR(16) NOT NULL DEFAULT '#E8262D';

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_vehicle_type_check;

ALTER TABLE users
    ADD CONSTRAINT users_vehicle_type_check
    CHECK (vehicle_type IN ('sedan', 'hatchback', 'station_wagon', 'kamyon', 'tir'));

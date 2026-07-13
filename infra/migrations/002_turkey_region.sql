-- Turkey-wide region support and additional city regions.
INSERT INTO regions (code, name, bbox) VALUES
  ('turkey', 'Turkey', ST_MakeEnvelope(25.66, 35.8, 44.8, 42.1, 4326)::geometry),
  ('ankara', 'Ankara', ST_MakeEnvelope(32.3, 39.6, 33.2, 40.2, 4326)::geometry),
  ('izmir', 'Izmir', ST_MakeEnvelope(26.8, 38.1, 27.5, 38.7, 4326)::geometry)
ON CONFLICT (code) DO NOTHING;

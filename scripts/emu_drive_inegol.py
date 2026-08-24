#!/usr/bin/env python3
"""Replay a 30 km/h GPS track into an Android emulator along D200 (Kestel → İnegöl).

Sends `adb emu geo fix <lon> <lat>` once per second so the app sees a steady
stream of ticks instead of teleporting.

The path is the real D200 approach into İnegöl (OSRM-aligned). It starts just
outside the 5 km local camera query box used by `camerasNear`, then passes
within ~15 m of seed EDS `bursa-eds-inegol-001` (40.0778, 29.5134) and the
İnegöl–Eskişehir corridor entry gate (40.0780, 29.5130).

Usage:
  python3 scripts/emu_drive_inegol.py
  python3 scripts/emu_drive_inegol.py --dry-run
  python3 scripts/emu_drive_inegol.py --serial emulator-5554
"""

from __future__ import annotations

import argparse
import math
import subprocess
import sys
import time

# Seed: data-pipeline/data/seed/bursa_cameras.csv
EDS_LAT = 40.0778
EDS_LON = 29.5134
EDS_ID = "bursa-eds-inegol-001"

# mobile/lib/features/alerts/road_eta_models.dart
QUERY_RADIUS_M = 5000.0

# D200 / Bursa–İnegöl Yolu, west of İnegöl toward Kestel, then into town.
# Coordinates are lon, lat (adb order). Sampled from an OSRM driving geometry.
WAYPOINTS_LON_LAT: list[tuple[float, float]] = [
    (29.445232, 40.118242),
    (29.452384, 40.114004),
    (29.460686, 40.109017),
    (29.464553, 40.106735),
    (29.468914, 40.104113),
    (29.472718, 40.101836),
    (29.477416, 40.098888),
    (29.481910, 40.096307),
    (29.486764, 40.093455),
    (29.490235, 40.091932),
    (29.492036, 40.090662),
    (29.495038, 40.089834),
    (29.498663, 40.087576),
    (29.501664, 40.085216),
    (29.504831, 40.082633),
    (29.507338, 40.081067),
    (29.509576, 40.079930),
    (29.511317, 40.079251),
    (29.512560, 40.079268),
    (29.513405, 40.077954),
    (29.513503, 40.077875),
]


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def query_bbox(lat: float, lon: float, radius_m: float) -> tuple[float, float, float, float]:
    lat_delta = radius_m / 111320.0
    lon_scale = 111320.0 * math.cos(math.radians(lat))
    lon_delta = 180.0 if abs(lon_scale) < 1 else radius_m / abs(lon_scale)
    return (
        lat - lat_delta,
        lat + lat_delta,
        lon - lon_delta,
        lon + lon_delta,
    )


def in_query_bbox(cam_lat: float, cam_lon: float, lat: float, lon: float) -> bool:
    lat_min, lat_max, lon_min, lon_max = query_bbox(lat, lon, QUERY_RADIUS_M)
    return lat_min <= cam_lat <= lat_max and lon_min <= cam_lon <= lon_max


def densify(
    waypoints: list[tuple[float, float]],
    step_m: float,
) -> list[tuple[float, float]]:
    if step_m <= 0:
        raise ValueError("step_m must be positive")
    out: list[tuple[float, float]] = [waypoints[0]]
    for (lon0, lat0), (lon1, lat1) in zip(waypoints, waypoints[1:]):
        dist = haversine_m(lat0, lon0, lat1, lon1)
        n = max(1, round(dist / step_m))
        for i in range(1, n + 1):
            t = i / n
            out.append((lon0 + (lon1 - lon0) * t, lat0 + (lat1 - lat0) * t))
    return out


def adb_prefix(serial: str | None) -> list[str]:
    cmd = ["adb"]
    if serial:
        cmd.extend(["-s", serial])
    return cmd


def send_fix(lon: float, lat: float, serial: str | None) -> None:
    result = subprocess.run(
        adb_prefix(serial) + ["emu", "geo", "fix", f"{lon:.6f}", f"{lat:.6f}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip() or f"exit {result.returncode}"
        raise RuntimeError(f"adb geo fix failed: {err}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--speed-kmh", type=float, default=30.0)
    parser.add_argument("--interval", type=float, default=1.0, help="Seconds between GPS ticks")
    parser.add_argument("--serial", help="adb device serial, e.g. emulator-5554")
    parser.add_argument("--dry-run", action="store_true", help="Print ticks without calling adb")
    args = parser.parse_args()

    step_m = (args.speed_kmh / 3.6) * args.interval
    points = densify(WAYPOINTS_LON_LAT, step_m)
    total_m = sum(
        haversine_m(a[1], a[0], b[1], b[0]) for a, b in zip(points, points[1:])
    )

    print(
        f"D200 Kestel→İnegöl replay  {args.speed_kmh:.0f} km/h  "
        f"{args.interval:.1f}s ticks  {step_m:.1f} m/tick"
    )
    print(
        f"{len(points)} points  {total_m / 1000:.2f} km  "
        f"~{len(points) * args.interval / 60:.1f} min"
    )
    print(
        f"Target EDS {EDS_ID}  {EDS_LAT:.4f},{EDS_LON:.4f}  "
        f"query radius {QUERY_RADIUS_M:.0f} m"
    )
    print("Ctrl+C to stop.\n")

    if not args.dry_run:
        probe = subprocess.run(
            adb_prefix(args.serial) + ["get-state"],
            capture_output=True,
            text=True,
        )
        if probe.returncode != 0:
            print("adb is not talking to an emulator. Start one, then retry.", file=sys.stderr)
            print(probe.stderr or probe.stdout, file=sys.stderr)
            return 1

    prev_in_box = False
    try:
        for i, (lon, lat) in enumerate(points, start=1):
            dist = haversine_m(lat, lon, EDS_LAT, EDS_LON)
            in_box = in_query_bbox(EDS_LAT, EDS_LON, lat, lon)
            in_circle = dist <= QUERY_RADIUS_M
            if in_box and not prev_in_box:
                print("--- entered 5 km query bbox (camera should become eligible) ---")
            prev_in_box = in_box

            flags = []
            if in_box:
                flags.append("bbox")
            if in_circle:
                flags.append("circle")
            if dist < 80:
                flags.append("NEAR_EDS")
            tag = ",".join(flags) if flags else "outside"

            line = (
                f"[{i:04d}/{len(points)}]  "
                f"lon={lon:.6f}  lat={lat:.6f}  "
                f"eds={dist:6.0f} m  {tag}"
            )
            print(line, flush=True)

            if not args.dry_run:
                send_fix(lon, lat, args.serial)

            if i < len(points) and not args.dry_run:
                time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nStopped.")
        return 130

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

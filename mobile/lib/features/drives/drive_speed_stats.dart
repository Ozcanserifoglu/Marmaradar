class DriveSpeedStats {
  const DriveSpeedStats({
    this.avgKmh,
    this.minKmh,
    this.maxKmh,
  });

  final double? avgKmh;
  final double? minKmh;
  final double? maxKmh;

  static const _idleMps = 1.0;
  static const _implausibleMps = 70.0; // ~250 km/h

  static DriveSpeedStats fromPoints(
    List<({double speedMps})> points, {
    required double lengthM,
    required Duration duration,
  }) {
    double? minMps;
    double? maxMps;
    for (final p in points) {
      final s = p.speedMps;
      if (s < _idleMps || s > _implausibleMps) continue;
      minMps = minMps == null ? s : (s < minMps ? s : minMps);
      maxMps = maxMps == null ? s : (s > maxMps ? s : maxMps);
    }

    double? avg;
    final seconds = duration.inMilliseconds / 1000.0;
    if (lengthM > 0 && seconds > 0) {
      avg = (lengthM / seconds) * 3.6;
    }

    return DriveSpeedStats(
      avgKmh: avg,
      minKmh: minMps == null ? null : minMps * 3.6,
      maxKmh: maxMps == null ? null : maxMps * 3.6,
    );
  }
}

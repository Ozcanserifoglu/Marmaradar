class CorridorPaceDelta {
  const CorridorPaceDelta({
    required this.deltaSec,
    required this.remainingM,
    required this.legalSec,
    required this.projectedSec,
  });

  /// Projected time through the corridor minus the time at the speed limit.
  /// Positive = slower than the legal average (safer). Negative = too fast.
  final double deltaSec;
  final double remainingM;
  final double legalSec;
  final double projectedSec;

  bool get overLimit => deltaSec < 0;
  bool get nearLimit => !overLimit && deltaSec < 5;

  String get signedLabel {
    final abs = deltaSec.abs();
    final sign = deltaSec >= 0 ? '+' : '−';
    if (abs >= 10) {
      return '$sign${abs.round()}';
    }
    return '$sign${abs.toStringAsFixed(1)}';
  }
}

CorridorPaceDelta? computeCorridorPaceDelta({
  required double lengthM,
  required int limitKmh,
  required double distanceM,
  required double elapsedSec,
  double? speedMps,
}) {
  if (lengthM < 50 || limitKmh <= 0) return null;

  final limitMps = limitKmh / 3.6;
  if (limitMps <= 0) return null;
  final legalSec = lengthM / limitMps;
  final remainingM = (lengthM - distanceM).clamp(0.0, lengthM);

  double? paceMps;
  if (elapsedSec >= 3 && distanceM >= 20) {
    paceMps = distanceM / elapsedSec;
  } else if (speedMps != null && speedMps >= 1) {
    paceMps = speedMps;
  }
  if (paceMps == null || paceMps < 0.5) return null;

  final projectedSec = remainingM < 8
      ? elapsedSec
      : elapsedSec + remainingM / paceMps;

  return CorridorPaceDelta(
    deltaSec: projectedSec - legalSec,
    remainingM: remainingM,
    legalSec: legalSec,
    projectedSec: projectedSec,
  );
}

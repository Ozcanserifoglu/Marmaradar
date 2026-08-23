import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/features/drives/drive_speed_stats.dart';

void main() {
  test('computes avg from length/duration and min/max from samples', () {
    final stats = DriveSpeedStats.fromPoints(
      [
        (speedMps: 10),
        (speedMps: 20),
        (speedMps: 0),
        (speedMps: 15),
      ],
      lengthM: 3600,
      duration: const Duration(seconds: 360),
    );
    expect(stats.avgKmh, closeTo(36, 0.01));
    expect(stats.minKmh, closeTo(36, 0.01));
    expect(stats.maxKmh, closeTo(72, 0.01));
  });
}

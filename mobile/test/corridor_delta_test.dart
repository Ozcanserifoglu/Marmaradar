import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/features/corridors/corridor_delta.dart';

void main() {
  const lengthM = 2000.0;
  const limitKmh = 72; // 20 m/s → legal time 100s

  test('under the limit average yields a positive (safe) delta', () {
    final delta = computeCorridorPaceDelta(
      lengthM: lengthM,
      limitKmh: limitKmh,
      distanceM: 400,
      elapsedSec: 30,
    );
    expect(delta, isNotNull);
    expect(delta!.deltaSec, greaterThan(0));
    expect(delta.overLimit, isFalse);
    expect(delta.signedLabel.startsWith('+'), isTrue);
  });

  test('over the limit average yields a negative (too fast) delta', () {
    final delta = computeCorridorPaceDelta(
      lengthM: lengthM,
      limitKmh: limitKmh,
      distanceM: 800,
      elapsedSec: 20,
    );
    expect(delta, isNotNull);
    expect(delta!.deltaSec, lessThan(0));
    expect(delta.overLimit, isTrue);
    expect(delta.signedLabel.startsWith('−'), isTrue);
  });

  test('returns null until there is enough distance and time', () {
    expect(
      computeCorridorPaceDelta(
        lengthM: lengthM,
        limitKmh: limitKmh,
        distanceM: 5,
        elapsedSec: 1,
      ),
      isNull,
    );
  });

  test('falls back to instantaneous speed when average is not ready', () {
    final delta = computeCorridorPaceDelta(
      lengthM: lengthM,
      limitKmh: limitKmh,
      distanceM: 5,
      elapsedSec: 1,
      speedMps: 10,
    );
    expect(delta, isNotNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/data/api/auth_models.dart';

void main() {
  DriveSummary summary({String? name}) => DriveSummary(
        id: '1',
        name: name,
        startedAt: DateTime.utc(2026, 8, 22),
        endedAt: DateTime.utc(2026, 8, 22, 1),
        lengthM: 1000,
        pointCount: 10,
      );

  test('copyWith keeps name when omitted', () {
    expect(summary(name: 'A').copyWith().name, 'A');
  });

  test('copyWith can clear name to null', () {
    expect(summary(name: 'A').copyWith(name: null).name, isNull);
  });
}

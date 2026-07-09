import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/core/geo/bearing.dart';

void main() {
  group('bearing', () {
    test('haversine distance is zero for same point', () {
      expect(haversineM(40.2, 29.0, 40.2, 29.0), 0);
    });

    test('isAhead accepts target within heading cone', () {
      final ahead = isAhead(90, 40.2, 29.0, 40.2, 29.01, null, 35);
      expect(ahead, isTrue);
    });

    test('isAhead rejects target behind vehicle', () {
      final behind = isAhead(270, 40.2, 29.0, 40.2, 29.01, null, 35);
      expect(behind, isFalse);
    });
  });
}

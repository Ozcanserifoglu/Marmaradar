import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/features/alerts/road_eta_cache.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';

void main() {
  group('RoadEtaCache', () {
    test('isFresh respects TTL and move threshold', () {
      final cache = RoadEtaCache();
      final fetchedAt = DateTime.utc(2026, 1, 1, 12);
      cache.put(CachedRoadEta(
        cameraId: 1,
        distanceM: 2000,
        durationSec: 120,
        originLat: 40.2,
        originLon: 29.0,
        fetchedAt: fetchedAt,
      ));

      expect(
        cache.isFresh(1, lat: 40.2, lon: 29.0, now: fetchedAt),
        isTrue,
      );
      expect(
        cache.isFresh(
          1,
          lat: 40.2,
          lon: 29.0,
          now: fetchedAt.add(const Duration(seconds: 30)),
        ),
        isFalse,
      );
    });

    test('interpolated decays distance by movement', () {
      final cache = RoadEtaCache();
      cache.put(CachedRoadEta(
        cameraId: 7,
        distanceM: 1000,
        durationSec: 60,
        originLat: 40.2,
        originLon: 29.0,
        fetchedAt: DateTime.utc(2026, 1, 1, 12),
      ));

      // ~111 m north
      final adj = cache.interpolated(
        7,
        lat: 40.201,
        lon: 29.0,
        now: DateTime.utc(2026, 1, 1, 12, 0, 5),
      );
      expect(adj, isNotNull);
      expect(adj!.distanceM, lessThan(1000));
      expect(adj.distanceM, greaterThan(800));
      expect(adj.durationSec, closeTo(55, 1));
    });
  });
}

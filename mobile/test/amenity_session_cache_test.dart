import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/amenities/amenity_session_cache.dart';
import 'package:radar_alert/features/amenities/amenity_visibility.dart';

void main() {
  group('AmenityCellRef', () {
    test('indexes floor lat/lon by cellDeg', () {
      final cell = AmenityCellRef.fromLatLon(40.21, 29.05);
      expect(cell.latIndex, (40.21 / AmenityConstants.cellDeg).floor());
      expect(cell.lonIndex, (29.05 / AmenityConstants.cellDeg).floor());
      expect(cell.key, '${cell.latIndex}:${cell.lonIndex}');
    });
  });

  group('AmenitySessionCache', () {
    test('dedupes places by placeId across cells', () {
      final cache = AmenitySessionCache();
      cache.putPlaces([
        const AmenityPlace(
          placeId: 'a',
          name: 'Shell',
          lat: 40.2,
          lon: 29.0,
          category: AmenityCategory.gasStation,
          cellKey: '1:1',
        ),
        const AmenityPlace(
          placeId: 'a',
          name: 'Shell Dup',
          lat: 40.2,
          lon: 29.0,
          category: AmenityCategory.gasStation,
          cellKey: '1:2',
        ),
        const AmenityPlace(
          placeId: 'b',
          name: 'Rest',
          lat: 40.21,
          lon: 29.01,
          category: AmenityCategory.restStop,
          cellKey: '1:1',
        ),
      ]);

      final all = cache.allPlaces();
      expect(all.map((p) => p.placeId).toSet(), {'a', 'b'});
    });

    test('markFetched prevents re-request of empty cells', () {
      final cache = AmenitySessionCache();
      expect(cache.hasCell('9:9'), isFalse);
      cache.markFetched(['9:9']);
      expect(cache.hasCell('9:9'), isTrue);
      expect(cache.get('9:9')!.places, isEmpty);
    });
  });

  group('amenityCellsAlongHeading', () {
    test('includes current cell and look-ahead', () {
      final cells = amenityCellsAlongHeading(
        lat: 40.2,
        lon: 29.0,
        headingDeg: 90, // east
        lookAhead: 2,
      );
      expect(cells.length, greaterThanOrEqualTo(1));
      expect(cells.first.key, AmenityCellRef.fromLatLon(40.2, 29.0).key);
      final keys = cells.map((c) => c.key).toSet();
      expect(keys.length, cells.length);
      expect(cells.length, lessThanOrEqualTo(3));
    });
  });

  group('AmenityVisibility.selectVisible', () {
    test('caps to maxCount and prefers nearer ahead places', () {
      final originLat = 40.2;
      final originLon = 29.0;
      final places = <AmenityPlace>[
        for (var i = 0; i < 20; i++)
          AmenityPlace(
            placeId: 'p$i',
            name: 'P$i',
            // North of driver (ahead when heading 0)
            lat: originLat + 0.001 * (i + 1),
            lon: originLon,
            category: AmenityCategory.gasStation,
            cellKey: '0:0',
          ),
      ];

      final visible = AmenityVisibility.selectVisible(
        places: places,
        driverLat: originLat,
        driverLon: originLon,
        headingDeg: 0,
        maxCount: 5,
      );
      expect(visible, hasLength(5));
      expect(visible.first.placeId, 'p0');
      expect(visible.last.placeId, 'p4');
    });

    test('includes places inside viewport even if behind', () {
      const place = AmenityPlace(
        placeId: 'behind',
        name: 'South',
        lat: 40.19,
        lon: 29.0,
        category: AmenityCategory.restStop,
        cellKey: '0:0',
      );
      final visible = AmenityVisibility.selectVisible(
        places: const [place],
        driverLat: 40.2,
        driverLon: 29.0,
        headingDeg: 0, // north — place is behind
        south: 40.18,
        west: 28.9,
        north: 40.25,
        east: 29.1,
        maxCount: 5,
      );
      expect(visible, hasLength(1));
      expect(visible.first.placeId, 'behind');
    });
  });
}

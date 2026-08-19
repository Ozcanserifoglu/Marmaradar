import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/geo/map_pin_filter.dart';

typedef _Pin = ({String id, double lat, double lng});

void main() {
  const originLat = 41.0082;
  const originLng = 28.9784;

  List<_Pin> filter(
    List<_Pin> pins, {
    double? lat = originLat,
    double? lng = originLng,
    List<GeoPoint>? route,
  }) {
    return MapPinFilter.filterMapPins(
      pins: pins,
      latOf: (p) => p.lat,
      lngOf: (p) => p.lng,
      originLat: lat,
      originLng: lng,
      routePoints: route,
    );
  }

  group('Mode A free roam', () {
    test('keeps pins within 10 km of the driver', () {
      final near = (id: 'near', lat: originLat + 0.05, lng: originLng);
      final far = (id: 'far', lat: originLat + 0.15, lng: originLng);
      expect(haversineM(originLat, originLng, near.lat, near.lng), lessThan(10000));
      expect(haversineM(originLat, originLng, far.lat, far.lng), greaterThan(10000));

      final visible = filter([near, far]);
      expect(visible.map((p) => p.id), ['near']);
    });

    test('hides all pins when GPS is unknown', () {
      final pin = (id: 'p', lat: originLat, lng: originLng);
      expect(filter([pin], lat: null, lng: null), isEmpty);
    });

    test('returns empty for an empty catalog', () {
      expect(filter(const []), isEmpty);
    });
  });

  group('Mode B route buffer', () {
    final route = <GeoPoint>[
      (lat: originLat, lng: originLng),
      (lat: originLat + 0.18, lng: originLng),
    ];

    test('keeps pins within the route buffer', () {
      final onRoute = (id: 'on', lat: originLat + 0.12, lng: originLng + 0.004);
      expect(
        MapPinFilter.distanceToPolylineM(onRoute.lat, onRoute.lng, route),
        lessThan(MapPinFilter.routeBufferM),
      );
      expect(filter([onRoute], route: route).map((p) => p.id), ['on']);
    });

    test('drops pins far from the route and the driver', () {
      final off = (id: 'off', lat: originLat + 0.12, lng: originLng + 0.08);
      expect(
        MapPinFilter.distanceToPolylineM(off.lat, off.lng, route),
        greaterThan(MapPinFilter.routeBufferM),
      );
      expect(haversineM(originLat, originLng, off.lat, off.lng), greaterThan(2000));
      expect(filter([off], route: route), isEmpty);
    });

    test('keeps off-route pins inside local proximity of the driver', () {
      final local = (id: 'local', lat: originLat, lng: originLng + 0.021);
      expect(
        MapPinFilter.distanceToPolylineM(local.lat, local.lng, route),
        greaterThan(MapPinFilter.routeBufferM),
      );
      expect(
        haversineM(originLat, originLng, local.lat, local.lng),
        lessThan(MapPinFilter.routeLocalProximityM),
      );
      expect(filter([local], route: route).map((p) => p.id), ['local']);
    });

    test('still shows route-buffer pins when GPS is missing', () {
      final onRoute = (id: 'on', lat: originLat + 0.12, lng: originLng);
      final off = (id: 'off', lat: originLat + 0.12, lng: originLng + 0.08);
      final visible = filter(
        [onRoute, off],
        lat: null,
        lng: null,
        route: route,
      );
      expect(visible.map((p) => p.id), ['on']);
    });
  });

  group('mode switch', () {
    test('a distant on-route pin appears only after a route is set', () {
      final route = <GeoPoint>[
        (lat: originLat, lng: originLng),
        (lat: originLat + 0.18, lng: originLng),
      ];
      final distantOnRoute = (
        id: 'along',
        lat: originLat + 0.12,
        lng: originLng,
      );
      expect(
        haversineM(originLat, originLng, distantOnRoute.lat, distantOnRoute.lng),
        greaterThan(MapPinFilter.freeRoamRadiusM),
      );

      expect(filter([distantOnRoute]), isEmpty);
      expect(filter([distantOnRoute], route: route).map((p) => p.id), ['along']);
    });
  });
}

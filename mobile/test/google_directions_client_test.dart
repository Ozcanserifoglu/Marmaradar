import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/data/api/google_directions_client.dart';
import 'package:radar_alert/features/directions/directions_models.dart';

void main() {
  group('GoogleDirectionsClient.parseRouteResponse', () {
    test('parses OK response with polyline and leg metrics', () {
      // Google reference polyline: (38.5,-120.2) → (40.7,-120.95) → (43.252,-126.453)
      final result = GoogleDirectionsClient.parseRouteResponse({
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {
              'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            },
            'legs': [
              {
                'distance': {'value': 12400, 'text': '12.4 km'},
                'duration': {'value': 1080, 'text': '18 mins'},
              },
            ],
          },
        ],
      });

      expect(result.points, hasLength(3));
      expect(result.distanceM, 12400);
      expect(result.durationSec, 1080);
      expect(result.distanceKm, closeTo(12.4, 1e-9));
      expect(result.durationMin, 18);
    });

    test('throws on ZERO_RESULTS', () {
      expect(
        () => GoogleDirectionsClient.parseRouteResponse({
          'status': 'ZERO_RESULTS',
          'routes': [],
        }),
        throwsA(
          isA<DirectionsException>().having(
            (e) => e.status,
            'status',
            'ZERO_RESULTS',
          ),
        ),
      );
    });

    test('throws on REQUEST_DENIED', () {
      expect(
        () => GoogleDirectionsClient.parseRouteResponse({
          'status': 'REQUEST_DENIED',
          'routes': [],
        }),
        throwsA(
          isA<DirectionsException>().having(
            (e) => e.status,
            'status',
            'REQUEST_DENIED',
          ),
        ),
      );
    });
  });
}

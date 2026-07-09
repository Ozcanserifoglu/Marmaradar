import 'package:drift/drift.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';

class RegionSyncService {
  RegionSyncService(this._db, this._api);

  final AppDatabase _db;
  final RadarApiClient _api;

  static const bursaBbox = '28.75,39.95,29.55,40.55';

  Future<int> syncBursa({DateTime? since}) async {
    final payload = await _api.syncRegion(
      region: 'bursa',
      bbox: bursaBbox,
      since: since,
    );

    var count = 0;
    final cameras = (payload['cameras'] as List<dynamic>? ?? []);
    for (final raw in cameras) {
      final c = raw as Map<String, dynamic>;
      await _db.upsertCamera(
        CachedCamerasCompanion(
          id: Value(c['id'] as int),
          lat: Value((c['lat'] as num).toDouble()),
          lon: Value((c['lon'] as num).toDouble()),
          maxspeedKmh: Value(c['maxspeed_kmh'] as int?),
          directionDeg: Value(c['direction_deg'] as int?),
          directionToleranceDeg: Value(
            (c['direction_tolerance_deg'] as int?) ?? 35,
          ),
          roadName: Value(c['road_name'] as String?),
          cameraType: Value((c['camera_type'] as String?) ?? 'fixed'),
          regionCode: Value((c['region_code'] as String?) ?? 'bursa'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      count++;
    }

    final corridors = (payload['corridors'] as List<dynamic>? ?? []);
    for (final raw in corridors) {
      final c = raw as Map<String, dynamic>;
      final corridorId = c['id'] as int;
      await _db.upsertCorridor(
        CachedCorridorsCompanion(
          id: Value(corridorId),
          name: Value(c['name'] as String),
          maxspeedKmh: Value(c['maxspeed_kmh'] as int),
          lengthM: Value((c['length_m'] as num).toDouble()),
          regionCode: Value((c['region_code'] as String?) ?? 'bursa'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      final gates = (c['gates'] as List<dynamic>? ?? []);
      await _db.replaceGatesForCorridor(
        corridorId,
        gates.map((g) {
          final gate = g as Map<String, dynamic>;
          return CachedCorridorGatesCompanion(
            corridorId: Value(corridorId),
            gateType: Value(gate['gate_type'] as String),
            lat: Value((gate['lat'] as num).toDouble()),
            lon: Value((gate['lon'] as num).toDouble()),
            radiusM: Value(((gate['radius_m'] as num?) ?? 80).toDouble()),
            sequence: Value((gate['sequence'] as int?) ?? 0),
            directionDeg: Value(gate['direction_deg'] as int?),
          );
        }).toList(),
      );
      count++;
    }

    return count;
  }
}

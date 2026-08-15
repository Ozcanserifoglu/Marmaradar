class RoadEtaConstants {
  RoadEtaConstants._();

  static const localQueryRadiusM = 5000.0;

  static const matrixGateRadiusM = 4000.0;

  static const maxDestinations = 3;

  static const cacheTtl = Duration(seconds: 25);

  static const moveThresholdM = 250.0;

  static const requestTimeout = Duration(seconds: 5);
}

enum RoadEtaSource { haversine, matrix }

class RoadEtaResult {
  const RoadEtaResult({
    required this.cameraId,
    required this.distanceM,
    required this.durationSec,
    required this.status,
  });

  final int cameraId;
  final double distanceM;
  final double durationSec;
  final String status;

  bool get isOk => status == 'OK';

  factory RoadEtaResult.fromJson(Map<String, dynamic> json) {
    return RoadEtaResult(
      cameraId: (json['camera_id'] as num).toInt(),
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
      durationSec: (json['duration_sec'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
}

class RoadEtaDestination {
  const RoadEtaDestination({
    required this.cameraId,
    required this.lat,
    required this.lon,
  });

  final int cameraId;
  final double lat;
  final double lon;

  Map<String, dynamic> toJson() => {
        'camera_id': cameraId,
        'lat': lat,
        'lon': lon,
      };
}

class CachedRoadEta {
  const CachedRoadEta({
    required this.cameraId,
    required this.distanceM,
    required this.durationSec,
    required this.originLat,
    required this.originLon,
    required this.fetchedAt,
  });

  final int cameraId;
  final double distanceM;
  final double durationSec;
  final double originLat;
  final double originLon;
  final DateTime fetchedAt;
}

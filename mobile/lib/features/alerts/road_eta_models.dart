/// Shared constants and models for two-tier road distance / ETA.
class RoadEtaConstants {
  RoadEtaConstants._();

  /// Drift / local bbox query radius (Tier 0).
  static const localQueryRadiusM = 5000.0;

  /// Straight-line distance at which Distance Matrix may be requested.
  static const matrixGateRadiusM = 4000.0;

  /// Max destinations per Matrix proxy call.
  static const maxDestinations = 3;

  /// Client cache TTL before a refresh is allowed.
  static const cacheTtl = Duration(seconds: 25);

  /// Force refresh after the user has moved this far from the fetch origin.
  static const moveThresholdM = 250.0;

  /// Network timeout for the ETA proxy (fail soft quickly).
  static const requestTimeout = Duration(seconds: 5);
}

enum RoadEtaSource { haversine, matrix }

/// One camera's road metrics from the backend Distance Matrix proxy.
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

/// Destination payload for POST /v1/eta/cameras.
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

/// Cached Matrix snapshot plus the origin where it was measured.
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

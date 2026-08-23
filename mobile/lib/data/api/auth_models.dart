class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String userId;
  final String email;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      userId: user['id'] as String,
      email: user['email'] as String,
    );
  }
}

class DriveUploadResult {
  const DriveUploadResult({
    required this.id,
    required this.lengthM,
    required this.pointCount,
  });

  final String id;
  final double lengthM;
  final int pointCount;

  factory DriveUploadResult.fromJson(Map<String, dynamic> json) {
    return DriveUploadResult(
      id: json['id'] as String,
      lengthM: (json['length_m'] as num).toDouble(),
      pointCount: json['point_count'] as int,
    );
  }
}

class DrivePointPayload {
  const DrivePointPayload({
    required this.lat,
    required this.lon,
    required this.speedMps,
    required this.recordedAt,
  });

  final double lat;
  final double lon;
  final double speedMps;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'speed_mps': speedMps,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };
}

const _unset = Object();

class DriveSummary {
  const DriveSummary({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.lengthM,
    required this.pointCount,
    this.avgSpeedKmh,
    this.minSpeedKmh,
    this.maxSpeedKmh,
    this.isLocal = false,
  });

  final String id;
  final String? name;
  final DateTime startedAt;
  final DateTime endedAt;
  final double lengthM;
  final int pointCount;
  final double? avgSpeedKmh;
  final double? minSpeedKmh;
  final double? maxSpeedKmh;
  final bool isLocal;

  Duration get duration => endedAt.difference(startedAt);

  bool get hasName => name != null && name!.trim().isNotEmpty;

  DriveSummary copyWith({Object? name = _unset}) => DriveSummary(
        id: id,
        name: identical(name, _unset) ? this.name : name as String?,
        startedAt: startedAt,
        endedAt: endedAt,
        lengthM: lengthM,
        pointCount: pointCount,
        avgSpeedKmh: avgSpeedKmh,
        minSpeedKmh: minSpeedKmh,
        maxSpeedKmh: maxSpeedKmh,
        isLocal: isLocal,
      );

  factory DriveSummary.fromJson(Map<String, dynamic> json) {
    return DriveSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
      endedAt: DateTime.parse(json['ended_at'] as String).toLocal(),
      lengthM: (json['length_m'] as num).toDouble(),
      pointCount: json['point_count'] as int,
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
      minSpeedKmh: (json['min_speed_kmh'] as num?)?.toDouble(),
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble(),
    );
  }
}

class DrivePoint {
  const DrivePoint({
    required this.lat,
    required this.lon,
    required this.speedMps,
    required this.recordedAt,
  });

  final double lat;
  final double lon;
  final double speedMps;
  final DateTime recordedAt;

  factory DrivePoint.fromJson(Map<String, dynamic> json) {
    return DrivePoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      speedMps: (json['speed_mps'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
    );
  }
}

class SnappedPoint {
  const SnappedPoint({
    required this.lat,
    required this.lon,
  });

  final double lat;
  final double lon;

  factory SnappedPoint.fromJson(Map<String, dynamic> json) {
    return SnappedPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}

class DriveDetail {
  const DriveDetail({
    required this.summary,
    required this.points,
    this.snappedPoints = const [],
  });

  final DriveSummary summary;
  final List<DrivePoint> points;
  final List<SnappedPoint> snappedPoints;

  List<SnappedPoint> get displayPoints {
    if (snappedPoints.length >= 2) return snappedPoints;
    return [
      for (final p in points) SnappedPoint(lat: p.lat, lon: p.lon),
    ];
  }

  factory DriveDetail.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final snapped = (json['snapped_points'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return DriveDetail(
      summary: DriveSummary.fromJson(json),
      points: rawPoints.map(DrivePoint.fromJson).toList(),
      snappedPoints: snapped.map(SnappedPoint.fromJson).toList(),
    );
  }
}

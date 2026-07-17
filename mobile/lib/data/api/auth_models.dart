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

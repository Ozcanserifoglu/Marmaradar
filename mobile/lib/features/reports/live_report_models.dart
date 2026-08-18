enum LiveReportType {
  police,
  accident;

  String get apiValue => name;

  String get label => switch (this) {
        LiveReportType.police => 'Polis',
        LiveReportType.accident => 'Kaza',
      };

  static LiveReportType fromApi(String value) {
    switch (value) {
      case 'accident':
        return LiveReportType.accident;
      case 'police':
      default:
        return LiveReportType.police;
    }
  }
}

class LiveReport {
  const LiveReport({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
    required this.createdAt,
    this.userId,
    this.isOptimistic = false,
  });

  final String id;
  final String? userId;
  final double lat;
  final double lng;
  final LiveReportType type;
  final DateTime createdAt;
  final bool isOptimistic;

  LiveReport copyWith({
    String? id,
    String? userId,
    bool? isOptimistic,
  }) {
    return LiveReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lat: lat,
      lng: lng,
      type: type,
      createdAt: createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  factory LiveReport.fromJson(Map<String, dynamic> json) {
    return LiveReport(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      type: LiveReportType.fromApi(json['report_type'] as String? ?? ''),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }
}

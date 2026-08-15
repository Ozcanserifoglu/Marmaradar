class AchievementUnlock {
  const AchievementUnlock({
    required this.code,
    required this.unlockedAt,
  });

  final String code;
  final DateTime unlockedAt;

  factory AchievementUnlock.fromJson(Map<String, dynamic> json) {
    return AchievementUnlock(
      code: json['code'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String).toLocal(),
    );
  }
}

class UserStats {
  const UserStats({
    required this.totalDistanceM,
    required this.totalDriveTimeSec,
    required this.totalDrives,
    required this.radarsEncountered,
    required this.achievements,
    required this.updatedAt,
  });

  final double totalDistanceM;
  final int totalDriveTimeSec;
  final int totalDrives;
  final int radarsEncountered;
  final List<AchievementUnlock> achievements;
  final DateTime updatedAt;

  Duration get totalDriveTime => Duration(seconds: totalDriveTimeSec);

  Set<String> get unlockedCodes =>
      achievements.map((a) => a.code).toSet();

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final raw = (json['achievements'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return UserStats(
      totalDistanceM: (json['total_distance_m'] as num).toDouble(),
      totalDriveTimeSec: (json['total_drive_time_sec'] as num).toInt(),
      totalDrives: json['total_drives'] as int,
      radarsEncountered: json['radars_encountered'] as int,
      achievements: raw.map(AchievementUnlock.fromJson).toList(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String code;
  final String title;
  final String description;
  final String icon;
}

const achievementCatalog = <AchievementDefinition>[
  AchievementDefinition(
    code: 'first_drive',
    title: 'İlk Sürüş',
    description: 'İlk sürüşünüzü kaydedin',
    icon: 'flag',
  ),
  AchievementDefinition(
    code: 'club_100km',
    title: '100 km Kulübü',
    description: 'Toplam 100 km sürün',
    icon: 'distance',
  ),
  AchievementDefinition(
    code: 'night_rider',
    title: 'Gece Sürücüsü',
    description: '5 gece sürüşü tamamlayın',
    icon: 'night',
  ),
  AchievementDefinition(
    code: 'safe_driver',
    title: 'Güvenli Sürücü',
    description: '10 sürüşü 130 km/s altında tamamlayın',
    icon: 'shield',
  ),
  AchievementDefinition(
    code: 'radar_scout',
    title: 'Radar İzcisi',
    description: '25 farklı radarın yanından geçin',
    icon: 'radar',
  ),
];

import 'package:flutter/material.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';

enum LeaderboardCategory {
  distance,
  reports;

  String get apiValue => switch (this) {
        LeaderboardCategory.distance => 'distance',
        LeaderboardCategory.reports => 'reports',
      };

  String get labelTr => switch (this) {
        LeaderboardCategory.distance => 'Mesafe',
        LeaderboardCategory.reports => 'Katkılar',
      };

  static LeaderboardCategory fromApi(String? value) {
    switch (value) {
      case 'reports':
        return LeaderboardCategory.reports;
      case 'distance':
      default:
        return LeaderboardCategory.distance;
    }
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    required this.vehicleType,
    required this.vehicleColor,
    required this.value,
  });

  final int rank;
  final String userId;
  final String username;
  final String? profilePictureUrl;
  final VehicleType vehicleType;
  final Color vehicleColor;
  final double value;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '***',
      profilePictureUrl: json['profile_picture_url'] as String?,
      vehicleType: VehicleType.fromApi(json['vehicle_type'] as String?),
      vehicleColor: parseVehicleColor(json['vehicle_color'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LeaderboardMeEntry {
  const LeaderboardMeEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    required this.vehicleType,
    required this.vehicleColor,
    required this.value,
    required this.inTop,
  });

  final int rank;
  final String userId;
  final String username;
  final String? profilePictureUrl;
  final VehicleType vehicleType;
  final Color vehicleColor;
  final double value;
  final bool inTop;

  factory LeaderboardMeEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardMeEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '***',
      profilePictureUrl: json['profile_picture_url'] as String?,
      vehicleType: VehicleType.fromApi(json['vehicle_type'] as String?),
      vehicleColor: parseVehicleColor(json['vehicle_color'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      inTop: json['in_top'] as bool? ?? false,
    );
  }

  LeaderboardEntry asEntry() => LeaderboardEntry(
        rank: rank,
        userId: userId,
        username: username,
        profilePictureUrl: profilePictureUrl,
        vehicleType: vehicleType,
        vehicleColor: vehicleColor,
        value: value,
      );
}

class LeaderboardResponse {
  const LeaderboardResponse({
    required this.category,
    required this.entries,
    required this.me,
  });

  final LeaderboardCategory category;
  final List<LeaderboardEntry> entries;
  final LeaderboardMeEntry me;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    return LeaderboardResponse(
      category: LeaderboardCategory.fromApi(json['category'] as String?),
      entries: rawEntries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      me: LeaderboardMeEntry.fromJson(json['me'] as Map<String, dynamic>),
    );
  }
}

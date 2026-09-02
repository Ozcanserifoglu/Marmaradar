import 'package:flutter/material.dart';

enum VehicleType {
  sedan,
  hatchback,
  stationWagon,
  kamyon,
  tir;

  String get apiValue => switch (this) {
        VehicleType.sedan => 'sedan',
        VehicleType.hatchback => 'hatchback',
        VehicleType.stationWagon => 'station_wagon',
        VehicleType.kamyon => 'kamyon',
        VehicleType.tir => 'tir',
      };

  String get labelTr => switch (this) {
        VehicleType.sedan => 'Sedan',
        VehicleType.hatchback => 'Hatchback',
        VehicleType.stationWagon => 'Station Wagon',
        VehicleType.kamyon => 'Kamyon',
        VehicleType.tir => 'Tır',
      };

  static VehicleType fromApi(String? value) {
    switch (value) {
      case 'hatchback':
        return VehicleType.hatchback;
      case 'station_wagon':
        return VehicleType.stationWagon;
      case 'kamyon':
        return VehicleType.kamyon;
      case 'tir':
        return VehicleType.tir;
      case 'sedan':
      default:
        return VehicleType.sedan;
    }
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.profilePictureUrl,
    required this.vehicleType,
    required this.vehicleColor,
  });

  final String id;
  final String email;
  final String? username;
  final String? profilePictureUrl;
  final VehicleType vehicleType;
  final Color vehicleColor;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      vehicleType: VehicleType.fromApi(json['vehicle_type'] as String?),
      vehicleColor: parseVehicleColor(json['vehicle_color'] as String?),
    );
  }
}

Color parseVehicleColor(String? hex) {
  final raw = (hex ?? '#E8262D').trim();
  final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
  if (normalized.length != 6) {
    return const Color(0xFFE8262D);
  }
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return const Color(0xFFE8262D);
  }
  return Color(0xFF000000 | value);
}

String vehicleColorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}

const kDefaultVehicleColor = Color(0xFFE8262D);

final usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

bool isValidUsername(String value) => usernamePattern.hasMatch(value);

const kVehicleColorSwatches = <Color>[
  Color(0xFFE8262D),
  Color(0xFFFFFFFF),
  Color(0xFF1A1A1A),
  Color(0xFF1E5AA8),
  Color(0xFF6B7280),
  Color(0xFF2F7D4A),
];

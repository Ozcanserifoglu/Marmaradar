import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

class PlaceResult {
  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.latLng,
    this.formattedAddress,
  });

  final String placeId;
  final String name;
  final LatLng latLng;
  final String? formattedAddress;
}

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceM,
    required this.durationSec,
  });

  final List<LatLng> points;
  final int distanceM;
  final int durationSec;

  double get distanceKm => distanceM / 1000.0;

  int get durationMin => (durationSec / 60).round().clamp(1, 9999);
}

/// Failure from Places / Directions REST (or a local guard such as missing GPS).
class DirectionsException implements Exception {
  const DirectionsException(this.message, {this.status, this.cause});

  /// User-facing Turkish message when possible.
  final String message;

  /// Google API `status` when available (e.g. `ZERO_RESULTS`).
  final String? status;

  final Object? cause;

  bool get isMissingGps => status == 'MISSING_GPS';
  bool get isZeroResults => status == 'ZERO_RESULTS';
  bool get isRequestDenied => status == 'REQUEST_DENIED';
  bool get isNetwork => status == 'NETWORK';

  @override
  String toString() =>
      'DirectionsException($message, status: $status, cause: $cause)';
}

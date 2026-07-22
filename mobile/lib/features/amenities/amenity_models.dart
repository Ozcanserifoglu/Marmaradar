/// Shared constants and models for drive-time route amenities.
class AmenityConstants {
  AmenityConstants._();

  /// Spatial grid cell size in degrees (≈ 2 km).
  static const cellDeg = 0.02;

  /// Prefetch this many cells ahead along heading (plus current).
  static const lookAheadCells = 2;

  /// Max cells per proxy request.
  static const maxCellsPerRequest = 3;

  /// Max amenity markers drawn on the map at once.
  static const maxVisibleMarkers = 15;

  /// Hide amenity markers below this map zoom.
  static const minZoom = 12.0;

  /// Ahead-cone distance used when selecting visible markers.
  static const aheadRadiusM = 5000.0;

  /// Heading cone half-angle for "ahead" selection.
  static const aheadToleranceDeg = 60;

  /// Network timeout for the amenities proxy (fail soft).
  static const requestTimeout = Duration(seconds: 8);

  /// Back off after a total failure before retrying.
  static const failureCooldown = Duration(seconds: 30);

  static const defaultTypes = ['gas_station', 'rest_stop'];
}

enum AmenityCategory {
  gasStation,
  restStop;

  String get apiValue => switch (this) {
        AmenityCategory.gasStation => 'gas_station',
        AmenityCategory.restStop => 'rest_stop',
      };

  static AmenityCategory fromApi(String value) {
    switch (value) {
      case 'rest_stop':
        return AmenityCategory.restStop;
      case 'gas_station':
      default:
        return AmenityCategory.gasStation;
    }
  }
}

/// One place from POST /v1/amenities/cells.
class AmenityPlace {
  const AmenityPlace({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.category,
    required this.cellKey,
    this.openNow,
    this.rating,
  });

  final String placeId;
  final String name;
  final double lat;
  final double lon;
  final AmenityCategory category;
  final String cellKey;
  final bool? openNow;
  final double? rating;

  factory AmenityPlace.fromJson(Map<String, dynamic> json) {
    return AmenityPlace(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      category: AmenityCategory.fromApi(json['category'] as String? ?? ''),
      cellKey: json['cell_key'] as String? ?? '',
      openNow: json['open_now'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

/// Cell coordinates for the amenities proxy request.
class AmenityCellRef {
  const AmenityCellRef({
    required this.latIndex,
    required this.lonIndex,
  });

  final int latIndex;
  final int lonIndex;

  String get key => '$latIndex:$lonIndex';

  Map<String, dynamic> toJson() => {
        'lat_index': latIndex,
        'lon_index': lonIndex,
      };

  static AmenityCellRef fromLatLon(double lat, double lon) {
    return AmenityCellRef(
      latIndex: (lat / AmenityConstants.cellDeg).floor(),
      lonIndex: (lon / AmenityConstants.cellDeg).floor(),
    );
  }

  /// Cell center in WGS84.
  ({double lat, double lon}) get center {
    final lat = (latIndex + 0.5) * AmenityConstants.cellDeg;
    final lon = (lonIndex + 0.5) * AmenityConstants.cellDeg;
    return (lat: lat, lon: lon);
  }
}

/// Session cache entry for one fetched cell.
class CachedAmenityCell {
  const CachedAmenityCell({
    required this.cellKey,
    required this.places,
    required this.fetchedAt,
  });

  final String cellKey;
  final List<AmenityPlace> places;
  final DateTime fetchedAt;
}

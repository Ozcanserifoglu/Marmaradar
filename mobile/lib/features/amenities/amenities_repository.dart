import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/amenities/amenity_session_cache.dart';

class AmenitiesRepository {
  AmenitiesRepository({
    required RadarApiClient api,
    AmenitySessionCache? cache,
  })  : _api = api,
        cache = cache ?? AmenitySessionCache();

  final RadarApiClient _api;
  final AmenitySessionCache cache;

  Future<List<AmenityPlace>>? _inFlight;
  String? _inFlightKey;

  bool needsRefresh(Iterable<AmenityCellRef> cells) {
    for (final c in cells) {
      if (!cache.hasCell(c.key)) return true;
    }
    return false;
  }

  List<AmenityCellRef> missingCells(Iterable<AmenityCellRef> cells) {
    return cells.where((c) => !cache.hasCell(c.key)).toList();
  }

  List<AmenityPlace> allPlaces() => cache.allPlaces();

  Future<List<AmenityPlace>> fetchCells({
    required List<AmenityCellRef> cells,
    List<String> types = AmenityConstants.defaultTypes,
  }) async {
    if (cells.isEmpty) return const [];

    final capped = cells.take(AmenityConstants.maxCellsPerRequest).toList();
    final keys = capped.map((c) => c.key).toList()..sort();
    final flightKey = '${keys.join(',')}|${types.join(',')}';

    final existing = _inFlight;
    if (existing != null && _inFlightKey == flightKey) {
      return existing;
    }

    final hasSession = await _api.tokenStore.hasSession;
    if (!hasSession) return const [];

    final future = _fetchAndCache(cells: capped, types: types);
    _inFlight = future;
    _inFlightKey = flightKey;

    try {
      return await future;
    } finally {
      if (_inFlightKey == flightKey) {
        _inFlight = null;
        _inFlightKey = null;
      }
    }
  }

  Future<List<AmenityPlace>> _fetchAndCache({
    required List<AmenityCellRef> cells,
    required List<String> types,
  }) async {
    try {
      final results = await _api.fetchAmenityCells(
        cells: cells,
        types: types,
      );
      cache.putPlaces(results);
      cache.markFetched(cells.map((c) => c.key));
      return results;
    } on ApiException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  void clear() {
    cache.clear();
    _inFlight = null;
    _inFlightKey = null;
  }
}

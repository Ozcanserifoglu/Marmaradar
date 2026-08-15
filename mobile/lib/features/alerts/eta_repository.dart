import 'dart:async';

import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/features/alerts/road_eta_cache.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';

class EtaRepository {
  EtaRepository({
    required RadarApiClient api,
    RoadEtaCache? cache,
  })  : _api = api,
        cache = cache ?? RoadEtaCache();

  final RadarApiClient _api;
  final RoadEtaCache cache;

  Future<List<RoadEtaResult>>? _inFlight;
  String? _inFlightKey;

  ({double distanceM, double durationSec})? lookup(
    int cameraId, {
    required double lat,
    required double lon,
  }) {
    return cache.interpolated(cameraId, lat: lat, lon: lon);
  }

  bool needsRefresh(
    Iterable<int> cameraIds, {
    required double lat,
    required double lon,
  }) {
    for (final id in cameraIds) {
      if (!cache.isFresh(id, lat: lat, lon: lon)) return true;
    }
    return false;
  }

  Future<List<RoadEtaResult>> refresh({
    required double originLat,
    required double originLon,
    required List<RoadEtaDestination> destinations,
  }) async {
    if (destinations.isEmpty) return const [];

    final capped = destinations.take(RoadEtaConstants.maxDestinations).toList();
    final key = capped.map((d) => d.cameraId).toList()..sort();
    final flightKey = key.join(',');

    final existing = _inFlight;
    if (existing != null && _inFlightKey == flightKey) {
      return existing;
    }

    final hasSession = await _api.tokenStore.hasSession;
    if (!hasSession) return const [];

    final future = _fetchAndCache(
      originLat: originLat,
      originLon: originLon,
      destinations: capped,
    );
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

  Future<List<RoadEtaResult>> _fetchAndCache({
    required double originLat,
    required double originLon,
    required List<RoadEtaDestination> destinations,
  }) async {
    try {
      final results = await _api.fetchCameraEtas(
        originLat: originLat,
        originLon: originLon,
        destinations: destinations,
      );
      final now = DateTime.now();
      final entries = <CachedRoadEta>[];
      for (final r in results) {
        if (!r.isOk) continue;
        entries.add(CachedRoadEta(
          cameraId: r.cameraId,
          distanceM: r.distanceM,
          durationSec: r.durationSec,
          originLat: originLat,
          originLon: originLon,
          fetchedAt: now,
        ));
      }
      cache.putAll(entries);
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

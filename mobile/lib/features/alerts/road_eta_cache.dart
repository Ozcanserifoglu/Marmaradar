import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';

class RoadEtaCache {
  final Map<int, CachedRoadEta> _byCamera = {};

  CachedRoadEta? get(int cameraId) => _byCamera[cameraId];

  void put(CachedRoadEta entry) {
    _byCamera[entry.cameraId] = entry;
  }

  void putAll(Iterable<CachedRoadEta> entries) {
    for (final e in entries) {
      _byCamera[e.cameraId] = e;
    }
  }

  void remove(int cameraId) => _byCamera.remove(cameraId);

  void clear() => _byCamera.clear();

  bool isFresh(
    int cameraId, {
    required double lat,
    required double lon,
    DateTime? now,
  }) {
    final entry = _byCamera[cameraId];
    if (entry == null) return false;
    final clock = now ?? DateTime.now();
    if (clock.difference(entry.fetchedAt) > RoadEtaConstants.cacheTtl) {
      return false;
    }
    final moved = haversineM(entry.originLat, entry.originLon, lat, lon);
    return moved < RoadEtaConstants.moveThresholdM;
  }

  ({double distanceM, double durationSec})? interpolated(
    int cameraId, {
    required double lat,
    required double lon,
    DateTime? now,
  }) {
    final entry = _byCamera[cameraId];
    if (entry == null) return null;

    final clock = now ?? DateTime.now();
    final traveled = haversineM(entry.originLat, entry.originLon, lat, lon);
    final elapsedSec =
        clock.difference(entry.fetchedAt).inMilliseconds / 1000.0;

    final distanceM =
        (entry.distanceM - traveled).clamp(0.0, double.infinity).toDouble();
    final durationSec =
        (entry.durationSec - elapsedSec).clamp(0.0, double.infinity).toDouble();
    return (distanceM: distanceM, durationSec: durationSec);
  }
}

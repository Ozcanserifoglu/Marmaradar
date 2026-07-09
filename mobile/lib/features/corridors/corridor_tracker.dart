import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/local/app_database.dart';

class CorridorSession {
  CorridorSession({
    required this.corridorId,
    required this.enteredAt,
  });

  final int corridorId;
  final DateTime enteredAt;
  double distanceM = 0;
  double? lastLat;
  double? lastLon;
  int lastWarnLevel = 0;
}

class CachedCorridorWithGates {
  CachedCorridorWithGates(this.corridor, this.gates);

  final CachedCorridor corridor;
  final List<CachedCorridorGate> gates;
}

typedef CorridorWarningCallback = void Function(
  CachedCorridor corridor,
  double avgKmh,
  int warnLevel,
);

class CorridorTracker {
  CorridorSession? _active;

  CorridorSession? get activeSession => _active;

  void onLocation(
    DriverSnapshot snap,
    List<CachedCorridorWithGates> corridors,
    CorridorWarningCallback warn,
  ) {
    if (_active != null) {
      _trackActive(snap, corridors, warn);
      return;
    }

    for (final item in corridors) {
      if (_atEntryGate(snap, item.gates)) {
        _active = CorridorSession(
          corridorId: item.corridor.id,
          enteredAt: DateTime.now(),
        );
        return;
      }
    }
  }

  void _trackActive(
    DriverSnapshot snap,
    List<CachedCorridorWithGates> corridors,
    CorridorWarningCallback warn,
  ) {
    final session = _active!;
    final item = corridors.where((c) => c.corridor.id == session.corridorId);
    if (item.isEmpty) {
      _active = null;
      return;
    }
    final corridorItem = item.first;

    _accumulate(session, snap);

    final elapsed = DateTime.now().difference(session.enteredAt).inSeconds;
    if (elapsed > 0) {
      final avgKmh = (session.distanceM / elapsed) * 3.6;
      final limit = corridorItem.corridor.maxspeedKmh;
      final warnLevel = avgKmh >= limit
          ? 2
          : avgKmh >= limit * 0.9
              ? 1
              : 0;
      if (warnLevel > 0 && warnLevel > session.lastWarnLevel) {
        session.lastWarnLevel = warnLevel;
        warn(corridorItem.corridor, avgKmh, warnLevel);
      }
    }

    if (_atExitGate(snap, corridorItem.gates)) {
      _active = null;
    }
  }

  void _accumulate(CorridorSession session, DriverSnapshot snap) {
    if (session.lastLat != null && session.lastLon != null) {
      session.distanceM += haversineM(
        session.lastLat!,
        session.lastLon!,
        snap.lat,
        snap.lon,
      );
    }
    session.lastLat = snap.lat;
    session.lastLon = snap.lon;
  }

  bool _atEntryGate(DriverSnapshot snap, List<CachedCorridorGate> gates) {
    return gates.any((g) {
      if (g.gateType != 'entry') return false;
      return haversineM(snap.lat, snap.lon, g.lat, g.lon) <= g.radiusM;
    });
  }

  bool _atExitGate(DriverSnapshot snap, List<CachedCorridorGate> gates) {
    return gates.any((g) {
      if (g.gateType != 'exit') return false;
      return haversineM(snap.lat, snap.lon, g.lat, g.lon) <= g.radiusM;
    });
  }

  void reset() => _active = null;
}

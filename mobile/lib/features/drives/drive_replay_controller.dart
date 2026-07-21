import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/data/api/auth_models.dart';

/// Animates a car along a recorded drive's trail (Strava-style replay).
///
/// Raw [points] drive relative pacing and speed HUD. Optional [displayRoute]
/// (road-snapped geometry) is used for the polyline and car position so the
/// marker stays on the smoothed path.
class DriveReplayController extends ChangeNotifier {
  DriveReplayController(
    List<DrivePoint> points, {
    List<LatLng>? displayRoute,
  })  : _points = List.unmodifiable(points),
        _route = List.unmodifiable(
          displayRoute != null && displayRoute.length >= 2
              ? displayRoute
              : points.map((p) => LatLng(p.lat, p.lon)),
        ) {
    _buildTimeline();
    _buildRouteDistances();
  }

  final List<DrivePoint> _points;
  final List<LatLng> _route;

  /// Cumulative timeline offsets (ms) matching [_points]; when the drive has
  /// no meaningful timestamps this falls back to even index spacing.
  final List<double> _offsets = [];
  double _total = 0;

  /// Cumulative geodesic distance (m) along [_route].
  final List<double> _routeCumDist = [];
  double _routeLengthM = 0;

  static const double _basePlaybackMs = 28000;
  static const List<double> speedOptions = [1, 2, 4];

  Timer? _timer;
  DateTime? _lastTick;
  bool _playing = false;
  double _speed = 1;

  /// 0..1 fraction along the timeline.
  double _progress = 0;

  bool get isPlaying => _playing;
  double get speed => _speed;
  double get progress => _progress;
  bool get isFinished => _progress >= 1;
  bool get canPlay => _points.length >= 2 && _route.length >= 2;

  List<LatLng> get routePoints => _route;

  LatLng? get start => _route.isEmpty ? null : _route.first;
  LatLng? get end => _route.isEmpty ? null : _route.last;

  void _buildTimeline() {
    _offsets.clear();
    if (_points.isEmpty) {
      _total = 0;
      return;
    }
    final base = _points.first.recordedAt.millisecondsSinceEpoch;
    var cursor = 0.0;
    var last = 0.0;
    var monotonic = true;
    for (final p in _points) {
      final off = (p.recordedAt.millisecondsSinceEpoch - base).toDouble();
      if (off < last) monotonic = false;
      _offsets.add(off);
      last = off;
      cursor = off;
    }
    // Fall back to even spacing if timestamps are missing/backwards/zero-span.
    if (!monotonic || cursor <= 0) {
      _offsets
        ..clear()
        ..addAll(
          List.generate(_points.length, (i) => i.toDouble()),
        );
    }
    _total = _offsets.last;
  }

  void _buildRouteDistances() {
    _routeCumDist.clear();
    _routeLengthM = 0;
    if (_route.isEmpty) return;
    _routeCumDist.add(0);
    for (var i = 1; i < _route.length; i++) {
      final a = _route[i - 1];
      final b = _route[i];
      _routeLengthM += haversineM(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      _routeCumDist.add(_routeLengthM);
    }
  }

  void togglePlay() => _playing ? pause() : play();

  void play() {
    if (!canPlay || _playing) return;
    if (isFinished) _progress = 0;
    _playing = true;
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 40), _tick);
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _playing = false;
    _lastTick = null;
    notifyListeners();
  }

  void setSpeed(double value) {
    _speed = value;
    notifyListeners();
  }

  void seek(double fraction) {
    _progress = fraction.clamp(0.0, 1.0);
    if (_progress >= 1 && _playing) pause();
    notifyListeners();
  }

  void _tick(Timer _) {
    final now = DateTime.now();
    final last = _lastTick ?? now;
    final dtMs = now.difference(last).inMicroseconds / 1000.0;
    _lastTick = now;

    _progress += dtMs * _speed / _basePlaybackMs;
    if (_progress >= 1) {
      _progress = 1;
      pause();
      return;
    }
    notifyListeners();
  }

  /// Interpolated position along the display route at the current [_progress].
  LatLng? get carPosition {
    final seg = _routeSegmentAt(_progress);
    if (seg == null) return null;
    final (a, b, t) = seg;
    return LatLng(
      _route[a].latitude + (_route[b].latitude - _route[a].latitude) * t,
      _route[a].longitude + (_route[b].longitude - _route[a].longitude) * t,
    );
  }

  /// Travel heading (degrees) along the display route at the current [_progress].
  double get carHeading {
    final seg = _routeSegmentAt(_progress);
    if (seg == null) return 0;
    final (a, b, _) = seg;
    return bearingDeg(
      _route[a].latitude,
      _route[a].longitude,
      _route[b].latitude,
      _route[b].longitude,
    );
  }

  /// Interpolated speed (m/s) from raw telemetry at the current [_progress].
  double get carSpeedMps {
    final seg = _rawSegmentAt(_progress);
    if (seg == null) return 0;
    final (a, b, t) = seg;
    return _points[a].speedMps + (_points[b].speedMps - _points[a].speedMps) * t;
  }

  /// Wall-clock timestamp represented by the current [_progress].
  DateTime? get currentTime {
    final seg = _rawSegmentAt(_progress);
    if (seg == null) return null;
    final (a, b, t) = seg;
    final ms = _points[a].recordedAt.millisecondsSinceEpoch +
        (_points[b].recordedAt.millisecondsSinceEpoch -
                _points[a].recordedAt.millisecondsSinceEpoch) *
            t;
    return DateTime.fromMillisecondsSinceEpoch(ms.round());
  }

  /// Segment along the display polyline by distance fraction matching [fraction].
  (int, int, double)? _routeSegmentAt(double fraction) {
    if (_route.length < 2) return null;
    if (_routeLengthM <= 0) return (0, 1, 0);
    final target = fraction.clamp(0.0, 1.0) * _routeLengthM;
    for (var i = 0; i < _routeCumDist.length - 1; i++) {
      final lo = _routeCumDist[i];
      final hi = _routeCumDist[i + 1];
      if (target <= hi) {
        final span = hi - lo;
        final t = span <= 0 ? 0.0 : (target - lo) / span;
        return (i, i + 1, t.clamp(0.0, 1.0));
      }
    }
    final n = _route.length;
    return (n - 2, n - 1, 1);
  }

  /// Returns the bounding index pair and the interpolation factor for a
  /// timeline [fraction] over raw points, or null if there are too few points.
  (int, int, double)? _rawSegmentAt(double fraction) {
    if (_points.length < 2) return null;
    if (_total <= 0) return (0, 1, 0);
    final target = fraction.clamp(0.0, 1.0) * _total;
    for (var i = 0; i < _offsets.length - 1; i++) {
      final lo = _offsets[i];
      final hi = _offsets[i + 1];
      if (target <= hi) {
        final span = hi - lo;
        final t = span <= 0 ? 0.0 : (target - lo) / span;
        return (i, i + 1, t.clamp(0.0, 1.0));
      }
    }
    final n = _points.length;
    return (n - 2, n - 1, 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

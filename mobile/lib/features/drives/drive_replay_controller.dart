import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/data/api/auth_models.dart';

/// Animates a car along a recorded drive's GPS trail (Strava-style replay).
///
/// The recorded timestamps drive the *relative* pacing (the car slows where
/// the driver slowed), but the whole trail is compressed into a watchable
/// [_basePlaybackMs] window, scaled by the chosen [speed] multiplier.
class DriveReplayController extends ChangeNotifier {
  DriveReplayController(List<DrivePoint> points)
      : _points = List.unmodifiable(points) {
    _buildTimeline();
  }

  final List<DrivePoint> _points;

  /// Cumulative timeline offsets (ms) matching [_points]; when the drive has
  /// no meaningful timestamps this falls back to even index spacing.
  final List<double> _offsets = [];
  double _total = 0;

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
  bool get canPlay => _points.length >= 2;

  List<LatLng> get routePoints =>
      _points.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);

  LatLng? get start =>
      _points.isEmpty ? null : LatLng(_points.first.lat, _points.first.lon);
  LatLng? get end =>
      _points.isEmpty ? null : LatLng(_points.last.lat, _points.last.lon);

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

  /// Interpolated position at the current [_progress].
  LatLng? get carPosition {
    final seg = _segmentAt(_progress);
    if (seg == null) return null;
    final (a, b, t) = seg;
    return LatLng(
      _points[a].lat + (_points[b].lat - _points[a].lat) * t,
      _points[a].lon + (_points[b].lon - _points[a].lon) * t,
    );
  }

  /// Travel heading (degrees) at the current [_progress].
  double get carHeading {
    final seg = _segmentAt(_progress);
    if (seg == null) return 0;
    final (a, b, _) = seg;
    return bearingDeg(
      _points[a].lat,
      _points[a].lon,
      _points[b].lat,
      _points[b].lon,
    );
  }

  /// Interpolated speed (m/s) at the current [_progress].
  double get carSpeedMps {
    final seg = _segmentAt(_progress);
    if (seg == null) return 0;
    final (a, b, t) = seg;
    return _points[a].speedMps + (_points[b].speedMps - _points[a].speedMps) * t;
  }

  /// Wall-clock timestamp represented by the current [_progress].
  DateTime? get currentTime {
    final seg = _segmentAt(_progress);
    if (seg == null) return null;
    final (a, b, t) = seg;
    final ms = _points[a].recordedAt.millisecondsSinceEpoch +
        (_points[b].recordedAt.millisecondsSinceEpoch -
                _points[a].recordedAt.millisecondsSinceEpoch) *
            t;
    return DateTime.fromMillisecondsSinceEpoch(ms.round());
  }

  /// Returns the bounding index pair and the interpolation factor for a
  /// timeline [fraction], or null if there are too few points.
  (int, int, double)? _segmentAt(double fraction) {
    if (_points.length < 2) return null;
    if (_total <= 0) return (0, 1, 0);
    final target = fraction.clamp(0.0, 1.0) * _total;
    // Linear scan is fine: drives cap at a few thousand points.
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

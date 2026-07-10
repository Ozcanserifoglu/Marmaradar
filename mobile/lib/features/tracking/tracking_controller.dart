import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' show LocationServiceDisabledException;
import 'package:radar_alert/core/audio/alert_player.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/alerts/alert_engine.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/sync/region_sync_service.dart';

/// Live proximity state for the closest camera ahead of the driver.
class ApproachingCamera {
  const ApproachingCamera({
    required this.camera,
    required this.distanceM,
    required this.ttaSec,
  });

  final CachedCamera camera;
  final double distanceM;
  final double ttaSec;

  /// 0 = far, 1 = inside alert radius, 2 = imminent (<300 m or <15 s).
  int get severity {
    if (distanceM <= 300 || ttaSec <= 15) return 2;
    return 1;
  }
}

/// Live state of the corridor session for the UI panel.
class CorridorStatus {
  const CorridorStatus({
    required this.corridor,
    required this.avgKmh,
    required this.distanceM,
  });

  final CachedCorridor corridor;
  final double avgKmh;
  final double distanceM;

  double get limitRatio =>
      corridor.maxspeedKmh <= 0 ? 0 : avgKmh / corridor.maxspeedKmh;
}

class TrackingController extends ChangeNotifier {
  TrackingController({
    BackgroundLocationService? locationService,
    AppDatabase? database,
    RadarApiClient? apiClient,
    AlertPlayer? alertPlayer,
  })  : _db = database ?? AppDatabase(),
        _location = locationService ?? BackgroundLocationService(),
        _alerts = AlertEngine(),
        _corridors = CorridorTracker(),
        _player = alertPlayer ?? AlertPlayer() {
    _sync = RegionSyncService(_db, apiClient ?? RadarApiClient());
    _loadMapData();
    _initLocation();
  }

  /// ~15 km/h sustained over a few fixes counts as driving.
  static const _driveStartSpeedMps = 4.2;
  static const _driveStartFixCount = 3;

  final BackgroundLocationService _location;
  final AppDatabase _db;
  late final RegionSyncService _sync;
  final AlertEngine _alerts;
  final CorridorTracker _corridors;
  final AlertPlayer _player;

  bool _running = false;
  bool _syncing = false;
  bool _autoDrive = true;
  bool _autoStarted = false;
  // Set after a manual stop so auto-detect doesn't instantly restart the
  // drive while the vehicle is still moving; clears once speed drops.
  bool _autoSuppressed = false;
  int _movingFixCount = 0;
  String _status = 'Konum alınıyor...';
  String? _lastAlert;
  DriverSnapshot? _lastSnapshot;
  ApproachingCamera? _approaching;
  List<CachedCamera> _mapCameras = const [];
  List<CachedCorridorWithGates> _mapCorridors = const [];

  bool get isRunning => _running;
  bool get isSyncing => _syncing;
  bool get autoDriveEnabled => _autoDrive;
  bool get wasAutoStarted => _autoStarted;
  String get status => _status;
  String? get lastAlert => _lastAlert;
  DriverSnapshot? get lastSnapshot => _lastSnapshot;
  ApproachingCamera? get approaching => _approaching;
  List<CachedCamera> get mapCameras => _mapCameras;
  List<CachedCorridorWithGates> get mapCorridors => _mapCorridors;

  double get speedKmh => (_lastSnapshot?.speedMps ?? 0) * 3.6;

  CorridorStatus? get corridorStatus {
    final session = _corridors.activeSession;
    if (session == null) return null;
    final match =
        _mapCorridors.where((c) => c.corridor.id == session.corridorId);
    if (match.isEmpty) return null;
    final elapsed = DateTime.now().difference(session.enteredAt).inSeconds;
    final avgKmh = elapsed > 0 ? (session.distanceM / elapsed) * 3.6 : 0.0;
    return CorridorStatus(
      corridor: match.first.corridor,
      avgKmh: avgKmh,
      distanceM: session.distanceM,
    );
  }

  /// Runs on app launch: gets a first fix so the map centers on the user,
  /// then keeps a lightweight watch running for drive auto-detection.
  Future<void> _initLocation() async {
    final granted = await _location.ensureBasicPermission();
    if (!granted) {
      _status = 'Konum izni gerekli — haritada yerinizi gösteremiyoruz';
      notifyListeners();
      return;
    }

    final snap = await _location.currentSnapshot();
    if (snap != null && _lastSnapshot == null) {
      _lastSnapshot = snap;
    }
    _status = 'Hazır — sürüş algılanınca takip otomatik başlar';
    notifyListeners();

    await _startIdleWatch();
  }

  Future<void> _startIdleWatch() async {
    await _location.startIdleWatch(
      _onIdleLocation,
      onError: (error) {
        _status = error is LocationServiceDisabledException
            ? 'Cihaz konumu kapalı'
            : 'Konum hatası: $error';
        notifyListeners();
      },
    );
  }

  void _onIdleLocation(DriverSnapshot snap) {
    _lastSnapshot = snap;

    if (snap.speedMps < _driveStartSpeedMps) {
      _autoSuppressed = false;
    }

    if (_autoDrive && !_running && !_autoSuppressed) {
      if (snap.speedMps >= _driveStartSpeedMps) {
        _movingFixCount++;
        if (_movingFixCount >= _driveStartFixCount) {
          _movingFixCount = 0;
          start(auto: true);
          return;
        }
      } else {
        _movingFixCount = 0;
      }
    }

    notifyListeners();
  }

  void toggleAutoDrive() {
    _autoDrive = !_autoDrive;
    _movingFixCount = 0;
    if (!_running) {
      _status = _autoDrive
          ? 'Hazır — sürüş algılanınca takip otomatik başlar'
          : 'Otomatik algılama kapalı';
    }
    notifyListeners();
  }

  Future<void> _loadMapData() async {
    _mapCameras = await _db.allCameras();

    final corridors = await _db.allCorridors();
    final withGates = <CachedCorridorWithGates>[];
    for (final c in corridors) {
      withGates.add(CachedCorridorWithGates(c, await _db.gatesFor(c.id)));
    }
    _mapCorridors = withGates;
    notifyListeners();
  }

  Future<void> syncData() async {
    _syncing = true;
    _status = 'Veri senkronize ediliyor...';
    notifyListeners();
    try {
      final count = await _sync.syncBursa();
      _status = '$count kayıt senkronize edildi';
      await _loadMapData();
    } catch (e) {
      _status = 'Senkron hatası: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> start({bool auto = false}) async {
    if (_running) return;

    final granted = await _location.ensurePermissions();
    if (!granted) {
      _status = 'Konum izni gerekli';
      notifyListeners();
      return;
    }

    await _location.stopIdleWatch();
    await _player.init();
    await _loadMapData();
    _running = true;
    _autoStarted = auto;
    _status = auto ? 'Sürüş algılandı — takip başladı' : 'Takip aktif';
    notifyListeners();

    await _location.start(
      _onLocation,
      onError: (error) {
        _status = error is LocationServiceDisabledException
            ? 'Cihaz konumu kapalı — konumu açıp tekrar başlatın'
            : 'Konum hatası: $error';
        _running = false;
        notifyListeners();
        _startIdleWatch();
      },
    );
  }

  Future<void> stop() async {
    await _location.stop();
    _running = false;
    _autoStarted = false;
    _autoSuppressed = true;
    _movingFixCount = 0;
    _status = _autoDrive
        ? 'Durduruldu — sürüş algılanınca yeniden başlar'
        : 'Durduruldu';
    _approaching = null;
    _alerts.reset();
    _corridors.reset();
    notifyListeners();
    await _startIdleWatch();
  }

  Future<void> _onLocation(DriverSnapshot snap) async {
    _lastSnapshot = snap;

    final cameras = await _db.camerasNear(snap.lat, snap.lon, 1500);
    _updateApproaching(snap, cameras);

    _alerts.onLocation(snap, cameras, (cam, dist, tta) async {
      final limit = cam.maxspeedKmh;
      final road = cam.roadName ?? 'Hız kamerası';
      final limitText = limit != null ? ' — limit $limit km/s' : '';
      _lastAlert = '$road: ${dist.round()} m, ~${tta.round()} sn$limitText';
      await _player.showCameraAlert(
        title: 'Hız Kamerası Uyarısı',
        body: _lastAlert!,
      );
      notifyListeners();
    });

    _corridors.onLocation(snap, _mapCorridors, (corridor, avgKmh, level) async {
      final prefix =
          level >= 2 ? 'Hız limiti aşıldı' : 'Hız limitine yaklaşıyorsunuz';
      _lastAlert =
          '$prefix — ${corridor.name}: ${avgKmh.round()} km/s (limit ${corridor.maxspeedKmh})';
      await _player.showCorridorWarning(
        title: 'Hız Koridoru',
        body: _lastAlert!,
      );
      notifyListeners();
    });

    notifyListeners();
  }

  void _updateApproaching(DriverSnapshot snap, List<CachedCamera> cameras) {
    ApproachingCamera? best;
    for (final cam in cameras) {
      final dist = haversineM(snap.lat, snap.lon, cam.lat, cam.lon);
      if (dist > cam.alertRadiusM) continue;
      if (!isAhead(
        snap.headingDeg,
        snap.lat,
        snap.lon,
        cam.lat,
        cam.lon,
        cam.directionDeg,
        cam.directionToleranceDeg,
      )) {
        continue;
      }
      final speed = snap.speedMps < AlertEngine.minSpeedMps
          ? AlertEngine.minSpeedMps
          : snap.speedMps;
      final candidate = ApproachingCamera(
        camera: cam,
        distanceM: dist,
        ttaSec: dist / speed,
      );
      if (best == null || candidate.distanceM < best.distanceM) {
        best = candidate;
      }
    }
    _approaching = best;
  }

  @override
  void dispose() {
    _location.stop();
    _location.stopIdleWatch();
    _db.close();
    super.dispose();
  }
}

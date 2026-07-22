import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' show LocationServiceDisabledException;
import 'package:radar_alert/core/audio/alert_player.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/alerts/alert_engine.dart';
import 'package:radar_alert/features/alerts/eta_repository.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';
import 'package:radar_alert/features/amenities/amenities_repository.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/amenities/amenity_visibility.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/sync/region_sync_service.dart';
import 'package:radar_alert/features/tracking/drive_recorder.dart';

/// Live proximity state for the closest camera ahead of the driver.
class ApproachingCamera {
  const ApproachingCamera({
    required this.camera,
    required this.distanceM,
    required this.ttaSec,
    this.roadDistanceM,
    this.roadDurationSec,
    this.source = RoadEtaSource.haversine,
  });

  final CachedCamera camera;

  /// Effective distance used for display / severity (road when available).
  final double distanceM;

  /// Effective TTA in seconds (road duration when available).
  final double ttaSec;

  final double? roadDistanceM;
  final double? roadDurationSec;
  final RoadEtaSource source;

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
    EtaRepository? etaRepository,
    AmenitiesRepository? amenitiesRepository,
  })  : _db = database ?? AppDatabase(),
        _location = locationService ?? BackgroundLocationService(),
        _alerts = AlertEngine(),
        _corridors = CorridorTracker(),
        _player = alertPlayer ?? AlertPlayer(),
        _api = apiClient ?? RadarApiClient() {
    _sync = RegionSyncService(_db, _api);
    _recorder = DriveRecorder(db: _db, api: _api);
    _eta = etaRepository ?? EtaRepository(api: _api);
    _amenities = amenitiesRepository ?? AmenitiesRepository(api: _api);
    _loadMapData();
    _initLocation();
  }

  /// ~15 km/h sustained over a few fixes counts as driving.
  static const _driveStartSpeedMps = 4.2;
  static const _driveStartFixCount = 3;

  final BackgroundLocationService _location;
  final AppDatabase _db;
  final RadarApiClient _api;
  late final RegionSyncService _sync;
  late final DriveRecorder _recorder;
  late final EtaRepository _eta;
  late final AmenitiesRepository _amenities;
  final AlertEngine _alerts;
  final CorridorTracker _corridors;
  final AlertPlayer _player;
  bool _etaRefreshScheduled = false;
  DateTime? _lastEtaAttemptAt;
  bool _amenityRefreshScheduled = false;
  DateTime? _lastAmenityAttemptAt;

  bool _running = false;
  bool _syncing = false;
  bool _autoDrive = true;
  bool _autoStarted = false;
  // Set after a manual stop so auto-detect doesn't instantly restart the
  // drive while the vehicle is still moving; clears once speed drops.
  bool _autoSuppressed = false;
  bool _amenitiesVisible = true;
  int _movingFixCount = 0;
  String _status = 'Konum alınıyor...';
  String? _lastAlert;
  DriverSnapshot? _lastSnapshot;
  ApproachingCamera? _approaching;
  List<CachedCamera> _mapCameras = const [];
  List<CachedCorridorWithGates> _mapCorridors = const [];
  List<AmenityPlace> _mapAmenities = const [];
  DriveUploadStatus _driveUploadStatus = DriveUploadStatus.idle;

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
  List<AmenityPlace> get mapAmenities =>
      _amenitiesVisible && _running ? _mapAmenities : const [];
  bool get amenitiesVisible => _amenitiesVisible;
  DriveUploadStatus get driveUploadStatus => _driveUploadStatus;

  double get speedKmh => (_lastSnapshot?.speedMps ?? 0) * 3.6;

  void setAmenitiesVisible(bool visible) {
    if (_amenitiesVisible == visible) return;
    _amenitiesVisible = visible;
    final snap = _lastSnapshot;
    if (visible && snap != null && _running) {
      _scheduleAmenityRefresh(snap);
      _refreshVisibleAmenities(snap);
    } else if (!visible) {
      _mapAmenities = const [];
    }
    notifyListeners();
  }

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
      final count = await _sync.syncTurkey();
      _status = '$count kayıt senkronize edildi';
      await _loadMapData();
    } on ApiException catch (e) {
      if (e.isServerWakingUp) {
        _status = 'Sunucu uyanıyor — birazdan tekrar deneyin';
      } else if (e.isNetworkError) {
        _status = 'İnternet bağlantısı yok — bağlantıyı kontrol edin';
      } else {
        _status = 'Sunucu hatası (${e.statusCode}) — daha sonra tekrar deneyin';
      }
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
    await _recorder.begin();
    _driveUploadStatus = DriveUploadStatus.recording;
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
    _approaching = null;
    _alerts.reset();
    _corridors.reset();
    _eta.clear();
    _etaRefreshScheduled = false;
    _lastEtaAttemptAt = null;
    _amenities.clear();
    _amenityRefreshScheduled = false;
    _lastAmenityAttemptAt = null;
    _mapAmenities = const [];

    final canUpload = await _api.tokenStore.hasSession;
    if (canUpload) {
      _driveUploadStatus = DriveUploadStatus.uploading;
      _status = 'Sürüş kaydı gönderiliyor...';
    } else {
      _status = 'Sürüş sonlandırılıyor...';
    }
    notifyListeners();

    final result = await _recorder.finish(upload: canUpload);
    _driveUploadStatus = result;
    switch (result) {
      case DriveUploadStatus.uploaded:
        _status = 'Sürüş kaydedildi';
      case DriveUploadStatus.tooShort:
        _status = _autoDrive
            ? 'Durduruldu — sürüş çok kısa, kayıt yok'
            : 'Durduruldu — sürüş çok kısa';
      case DriveUploadStatus.needsAuth:
        _status = 'Sürüş tamamlandı — kaydetmek için giriş yapın';
      case DriveUploadStatus.failed:
        _status =
            'Kayıt yüklenemedi${_recorder.lastError != null ? ': ${_recorder.lastError}' : ''}';
      default:
        _status = _autoDrive
            ? 'Durduruldu — sürüş algılanınca yeniden başlar'
            : 'Durduruldu';
    }
    notifyListeners();
    await _startIdleWatch();
  }

  /// Debug-only: writes a short fake GPS trail and ends the drive so the
  /// save / login prompt can be exercised without physically moving.
  Future<void> simulateShortDrive() async {
    if (!kDebugMode) return;
    if (_running) {
      await stop();
    }

    final baseLat = _lastSnapshot?.lat ?? 41.0082;
    final baseLon = _lastSnapshot?.lon ?? 28.9784;

    await _location.stopIdleWatch();
    await _player.init();
    await _loadMapData();
    await _recorder.begin();
    _driveUploadStatus = DriveUploadStatus.recording;
    _running = true;
    _autoStarted = false;
    _status = 'Simüle sürüş kaydediliyor...';
    notifyListeners();

    final origin = DateTime.now().toUtc();
    // 6 points, ~33 m and 6 s apart — well above the recorder thresholds.
    for (var i = 0; i < 6; i++) {
      final snap = DriverSnapshot(
        lat: baseLat + i * 0.0003,
        lon: baseLon + i * 0.0001,
        speedMps: 11.0,
        headingDeg: 45,
        recordedAt: origin.add(Duration(seconds: i * 6)),
      );
      await _onLocation(snap);
    }

    await stop();
  }

  /// Uploads a drive that was left pending after a guest session.
  Future<void> uploadPendingDrive() async {
    if (!_recorder.hasPendingUpload) return;

    _driveUploadStatus = DriveUploadStatus.uploading;
    _status = 'Sürüş kaydı gönderiliyor...';
    notifyListeners();

    final result = await _recorder.uploadPending();
    _driveUploadStatus = result;
    switch (result) {
      case DriveUploadStatus.uploaded:
        _status = 'Sürüş kaydedildi';
      case DriveUploadStatus.tooShort:
        _status = 'Sürüş çok kısa, kayıt yok';
      case DriveUploadStatus.failed:
        _status =
            'Kayıt yüklenemedi${_recorder.lastError != null ? ': ${_recorder.lastError}' : ''}';
      default:
        _status = _autoDrive
            ? 'Durduruldu — sürüş algılanınca yeniden başlar'
            : 'Durduruldu';
    }
    notifyListeners();
  }

  Future<void> _onLocation(DriverSnapshot snap) async {
    _lastSnapshot = snap;
    await _recorder.maybeAppend(snap);

    final cameras = await _db.camerasNear(
      snap.lat,
      snap.lon,
      RoadEtaConstants.localQueryRadiusM,
    );
    _updateApproaching(snap, cameras);
    _scheduleRoadEtaRefresh(snap, cameras);
    _scheduleAmenityRefresh(snap);
    _refreshVisibleAmenities(snap);

    _alerts.onLocation(
      snap,
      cameras,
      (cam, dist, tta) async {
        final limit = cam.maxspeedKmh;
        final road = cam.roadName ?? 'Hız kamerası';
        final limitText = limit != null ? ' — limit $limit km/s' : '';
        _lastAlert = '$road: ${dist.round()} m, ~${tta.round()} sn$limitText';
        await _player.showCameraAlert(
          title: 'Hız Kamerası Uyarısı',
          body: _lastAlert!,
        );
        notifyListeners();
      },
      roadMetrics: (cameraId) => _eta.lookup(
        cameraId,
        lat: snap.lat,
        lon: snap.lon,
      ),
    );

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
      final haversineDist = haversineM(snap.lat, snap.lon, cam.lat, cam.lon);
      if (haversineDist > cam.alertRadiusM) continue;
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

      final road = _eta.lookup(cam.id, lat: snap.lat, lon: snap.lon);
      final speed = snap.speedMps < AlertEngine.minSpeedMps
          ? AlertEngine.minSpeedMps
          : snap.speedMps;
      final distanceM = road?.distanceM ?? haversineDist;
      final ttaSec = road?.durationSec ?? (distanceM / speed);
      final candidate = ApproachingCamera(
        camera: cam,
        distanceM: distanceM,
        ttaSec: ttaSec,
        roadDistanceM: road?.distanceM,
        roadDurationSec: road?.durationSec,
        source: road != null ? RoadEtaSource.matrix : RoadEtaSource.haversine,
      );
      if (best == null || candidate.distanceM < best.distanceM) {
        best = candidate;
      }
    }
    _approaching = best;
  }

  /// Fire-and-forget Matrix refresh for cameras inside the gate radius.
  /// Never awaits on the GPS hot path.
  void _scheduleRoadEtaRefresh(
    DriverSnapshot snap,
    List<CachedCamera> cameras,
  ) {
    if (!_running) return;
    if (snap.speedMps < AlertEngine.minSpeedMps) return;
    if (_etaRefreshScheduled) return;
    final failureCooldown = _lastEtaAttemptAt;
    if (failureCooldown != null &&
        DateTime.now().difference(failureCooldown) < RoadEtaConstants.cacheTtl) {
      return;
    }

    final candidates = <({CachedCamera cam, double dist})>[];
    for (final cam in cameras) {
      final dist = haversineM(snap.lat, snap.lon, cam.lat, cam.lon);
      if (dist > RoadEtaConstants.matrixGateRadiusM) continue;
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
      candidates.add((cam: cam, dist: dist));
    }
    if (candidates.isEmpty) return;

    candidates.sort((a, b) => a.dist.compareTo(b.dist));
    final top = candidates.take(RoadEtaConstants.maxDestinations).toList();
    final ids = top.map((c) => c.cam.id);
    if (!_eta.needsRefresh(ids, lat: snap.lat, lon: snap.lon)) return;

    final destinations = top
        .map(
          (c) => RoadEtaDestination(
            cameraId: c.cam.id,
            lat: c.cam.lat,
            lon: c.cam.lon,
          ),
        )
        .toList();

    _etaRefreshScheduled = true;
    final originLat = snap.lat;
    final originLon = snap.lon;
    unawaited(() async {
      try {
        final results = await _eta.refresh(
          originLat: originLat,
          originLon: originLon,
          destinations: destinations,
        );
        if (!_running) return;
        final okCount = results.where((r) => r.isOk).length;
        if (okCount == 0) {
          // Auth missing, Matrix down, or all elements failed — back off.
          _lastEtaAttemptAt = DateTime.now();
          return;
        }
        _lastEtaAttemptAt = null;
        final current = _lastSnapshot;
        if (current == null) return;
        final nearby = await _db.camerasNear(
          current.lat,
          current.lon,
          RoadEtaConstants.localQueryRadiusM,
        );
        _updateApproaching(current, nearby);
        notifyListeners();
      } finally {
        _etaRefreshScheduled = false;
      }
    }());
  }

  /// Fire-and-forget Places cell fetch for the current + look-ahead grid.
  /// Never awaits on the GPS hot path.
  void _scheduleAmenityRefresh(DriverSnapshot snap) {
    if (!_running) return;
    if (!_amenitiesVisible) return;
    if (snap.speedMps < AlertEngine.minSpeedMps) return;
    if (_amenityRefreshScheduled) return;
    final failureCooldown = _lastAmenityAttemptAt;
    if (failureCooldown != null &&
        DateTime.now().difference(failureCooldown) <
            AmenityConstants.failureCooldown) {
      return;
    }

    final needed = amenityCellsAlongHeading(
      lat: snap.lat,
      lon: snap.lon,
      headingDeg: snap.headingDeg,
    );
    final missing = _amenities.missingCells(needed);
    if (missing.isEmpty) return;

    _amenityRefreshScheduled = true;
    unawaited(() async {
      try {
        final results = await _amenities.fetchCells(cells: missing);
        if (!_running) return;
        if (results.isEmpty && _amenities.needsRefresh(missing)) {
          // Auth missing or Places down — back off.
          _lastAmenityAttemptAt = DateTime.now();
          return;
        }
        _lastAmenityAttemptAt = null;
        final current = _lastSnapshot;
        if (current == null) return;
        _refreshVisibleAmenities(current);
        notifyListeners();
      } finally {
        _amenityRefreshScheduled = false;
      }
    }());
  }

  void _refreshVisibleAmenities(DriverSnapshot snap) {
    if (!_running || !_amenitiesVisible) {
      _mapAmenities = const [];
      return;
    }
    _mapAmenities = AmenityVisibility.selectVisible(
      places: _amenities.allPlaces(),
      driverLat: snap.lat,
      driverLon: snap.lon,
      headingDeg: snap.headingDeg,
    );
  }

  @override
  void dispose() {
    _location.stop();
    _location.stopIdleWatch();
    _eta.clear();
    _amenities.clear();
    _db.close();
    super.dispose();
  }
}

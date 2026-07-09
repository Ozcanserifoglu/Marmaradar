import 'package:flutter/foundation.dart';
import 'package:radar_alert/core/audio/alert_player.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/alerts/alert_engine.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/sync/region_sync_service.dart';

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
  }

  final BackgroundLocationService _location;
  final AppDatabase _db;
  late final RegionSyncService _sync;
  final AlertEngine _alerts;
  final CorridorTracker _corridors;
  final AlertPlayer _player;

  bool _running = false;
  bool _syncing = false;
  String _status = 'Hazır';
  String? _lastAlert;
  DriverSnapshot? _lastSnapshot;
  CorridorSession? get activeCorridor => _corridors.activeSession;

  bool get isRunning => _running;
  bool get isSyncing => _syncing;
  String get status => _status;
  String? get lastAlert => _lastAlert;
  DriverSnapshot? get lastSnapshot => _lastSnapshot;

  Future<void> syncData() async {
    _syncing = true;
    _status = 'Veri senkronize ediliyor...';
    notifyListeners();
    try {
      final count = await _sync.syncBursa();
      _status = '$count kayıt senkronize edildi';
    } catch (e) {
      _status = 'Senkron hatası: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> start() async {
    final granted = await _location.ensurePermissions();
    if (!granted) {
      _status = 'Konum izni gerekli';
      notifyListeners();
      return;
    }

    await _player.init();
    _running = true;
    _status = 'Takip aktif';
    notifyListeners();

    await _location.start(_onLocation);
  }

  Future<void> stop() async {
    await _location.stop();
    _running = false;
    _status = 'Durduruldu';
    _alerts.reset();
    _corridors.reset();
    notifyListeners();
  }

  Future<void> _onLocation(DriverSnapshot snap) async {
    _lastSnapshot = snap;

    final cameras = await _db.camerasNear(snap.lat, snap.lon, 1500);
    _alerts.onLocation(snap, cameras, (cam, dist, tta) async {
      final limit = cam.maxspeedKmh;
      final road = cam.roadName ?? 'Hız kamerası';
      final limitText = limit != null ? ' — limit $limit km/s' : '';
      _lastAlert =
          '$road: ${dist.round()} m, ~${tta.round()} sn$limitText';
      await _player.showCameraAlert(
        title: 'Hız Kamerası Uyarısı',
        body: _lastAlert!,
      );
      notifyListeners();
    });

    final corridors = await _db.allCorridors();
    final withGates = <CachedCorridorWithGates>[];
    for (final c in corridors) {
      final gates = await _db.gatesFor(c.id);
      withGates.add(CachedCorridorWithGates(c, gates));
    }

    _corridors.onLocation(snap, withGates, (corridor, avgKmh, level) async {
      final prefix = level >= 2 ? 'Hız limiti aşıldı' : 'Hız limitine yaklaşıyorsunuz';
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

  @override
  void dispose() {
    _location.stop();
    _db.close();
    super.dispose();
  }
}

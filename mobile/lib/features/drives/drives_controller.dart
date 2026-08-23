import 'package:flutter/foundation.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/drives/drive_speed_stats.dart';

enum DrivesLoadState { idle, loading, ready, error }

class DrivesController extends ChangeNotifier {
  DrivesController({
    required RadarApiClient apiClient,
    required AppDatabase db,
  })  : _api = apiClient,
        _db = db;

  final RadarApiClient _api;
  final AppDatabase _db;

  DrivesLoadState _state = DrivesLoadState.idle;
  List<DriveSummary> _drives = const [];
  String? _error;

  DrivesLoadState get state => _state;
  List<DriveSummary> get drives => _drives;
  String? get error => _error;
  bool get isLoading => _state == DrivesLoadState.loading;

  Future<void> load({bool authenticated = false}) async {
    _state = DrivesLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final local = await _loadLocal();
      var remote = <DriveSummary>[];
      if (authenticated) {
        remote = await _api.fetchDrives();
      }
      _drives = [...local, ...remote];
      _state = DrivesLoadState.ready;
    } on ApiException catch (e) {
      _error = e.message;
      _state = DrivesLoadState.error;
    } catch (e) {
      _error = e.toString();
      _state = DrivesLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<List<DriveSummary>> _loadLocal() async {
    final rows = await _db.pendingLocalDrives();
    final out = <DriveSummary>[];
    for (final row in rows) {
      final points = await _db.pointsForDrive(row.id);
      if (points.length < 2) continue;
      var lengthM = 0.0;
      for (var i = 1; i < points.length; i++) {
        lengthM += haversineM(
          points[i - 1].lat,
          points[i - 1].lon,
          points[i].lat,
          points[i].lon,
        );
      }
      final ended = row.endedAt ?? points.last.recordedAt;
      final stats = DriveSpeedStats.fromPoints(
        [for (final p in points) (speedMps: p.speedMps)],
        lengthM: lengthM,
        duration: ended.difference(row.startedAt),
      );
      out.add(
        DriveSummary(
          id: 'local:${row.id}',
          name: 'Yerel kayıt',
          startedAt: row.startedAt.toLocal(),
          endedAt: ended.toLocal(),
          lengthM: lengthM,
          pointCount: points.length,
          avgSpeedKmh: stats.avgKmh,
          minSpeedKmh: stats.minKmh,
          maxSpeedKmh: stats.maxKmh,
          isLocal: true,
        ),
      );
    }
    return out;
  }

  Future<DriveDetail> loadDetail(String id) async {
    if (id.startsWith('local:')) {
      final localId = id.substring(6);
      final drive = await _db.localDriveById(localId);
      if (drive == null) {
        throw const ApiException('drives/local', 404, 'Drive not found');
      }
      final points = await _db.pointsForDrive(localId);
      var lengthM = 0.0;
      for (var i = 1; i < points.length; i++) {
        lengthM += haversineM(
          points[i - 1].lat,
          points[i - 1].lon,
          points[i].lat,
          points[i].lon,
        );
      }
      final ended = drive.endedAt ??
          (points.isEmpty ? drive.startedAt : points.last.recordedAt);
      final stats = DriveSpeedStats.fromPoints(
        [for (final p in points) (speedMps: p.speedMps)],
        lengthM: lengthM,
        duration: ended.difference(drive.startedAt),
      );
      return DriveDetail(
        summary: DriveSummary(
          id: id,
          name: 'Yerel kayıt',
          startedAt: drive.startedAt.toLocal(),
          endedAt: ended.toLocal(),
          lengthM: lengthM,
          pointCount: points.length,
          avgSpeedKmh: stats.avgKmh,
          minSpeedKmh: stats.minKmh,
          maxSpeedKmh: stats.maxKmh,
          isLocal: true,
        ),
        points: [
          for (final p in points)
            DrivePoint(
              lat: p.lat,
              lon: p.lon,
              speedMps: p.speedMps,
              recordedAt: p.recordedAt.toLocal(),
            ),
        ],
      );
    }
    return _api.fetchDrive(id);
  }

  Future<void> rename(String id, String name) async {
    await _api.renameDrive(id, name);
    final trimmed = name.trim();
    _drives = [
      for (final d in _drives)
        if (d.id == id) d.copyWith(name: trimmed.isEmpty ? null : trimmed) else d,
    ];
    notifyListeners();
  }
}

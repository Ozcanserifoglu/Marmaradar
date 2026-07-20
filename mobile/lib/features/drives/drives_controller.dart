import 'package:flutter/foundation.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';

enum DrivesLoadState { idle, loading, ready, error }

/// Loads the signed-in user's recorded drives from the backend.
class DrivesController extends ChangeNotifier {
  DrivesController({required RadarApiClient apiClient}) : _api = apiClient;

  final RadarApiClient _api;

  DrivesLoadState _state = DrivesLoadState.idle;
  List<DriveSummary> _drives = const [];
  String? _error;

  DrivesLoadState get state => _state;
  List<DriveSummary> get drives => _drives;
  String? get error => _error;
  bool get isLoading => _state == DrivesLoadState.loading;

  Future<void> load() async {
    _state = DrivesLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _drives = await _api.fetchDrives();
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

  Future<DriveDetail> loadDetail(String id) => _api.fetchDrive(id);

  /// Renames a drive on the backend and updates the cached list in place.
  Future<void> rename(String id, String name) async {
    await _api.renameDrive(id, name);
    final trimmed = name.trim();
    _drives = [
      for (final d in _drives)
        if (d.id == id)
          DriveSummary(
            id: d.id,
            name: trimmed.isEmpty ? null : trimmed,
            startedAt: d.startedAt,
            endedAt: d.endedAt,
            lengthM: d.lengthM,
            pointCount: d.pointCount,
          )
        else
          d,
    ];
    notifyListeners();
  }
}

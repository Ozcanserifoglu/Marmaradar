import 'package:flutter/foundation.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/features/leaderboard/leaderboard_models.dart';

enum LeaderboardLoadState { idle, loading, ready, error }

class LeaderboardController extends ChangeNotifier {
  LeaderboardController({required RadarApiClient apiClient}) : _api = apiClient;

  final RadarApiClient _api;

  LeaderboardCategory _category = LeaderboardCategory.distance;
  LeaderboardLoadState _state = LeaderboardLoadState.idle;
  LeaderboardResponse? _distance;
  LeaderboardResponse? _reports;
  String? _error;
  bool _refreshing = false;

  LeaderboardCategory get category => _category;
  LeaderboardLoadState get state => _state;
  String? get error => _error;
  bool get isRefreshing => _refreshing;

  LeaderboardResponse? get current =>
      _category == LeaderboardCategory.distance ? _distance : _reports;

  bool get hasCache => current != null;

  String? absolutePictureUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '${_api.baseUrl}$path';
    return '${_api.baseUrl}/$path';
  }

  Future<void> setCategory(LeaderboardCategory next) async {
    if (_category == next) return;
    _category = next;
    notifyListeners();
    if (current == null) {
      await load(forceSpinner: true);
    }
  }

  Future<void> load({bool forceSpinner = false}) async {
    final showSpinner = forceSpinner || current == null;
    if (showSpinner) {
      _state = LeaderboardLoadState.loading;
      _error = null;
      notifyListeners();
    } else {
      _refreshing = true;
      notifyListeners();
    }

    try {
      final next = await _api.fetchLeaderboard(_category);
      if (_category == LeaderboardCategory.distance) {
        _distance = next;
      } else {
        _reports = next;
      }
      _state = LeaderboardLoadState.ready;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (current == null) {
        _state = LeaderboardLoadState.error;
      }
    } catch (e) {
      _error = e.toString();
      if (current == null) {
        _state = LeaderboardLoadState.error;
      }
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(forceSpinner: false);

  void clear() {
    _state = LeaderboardLoadState.idle;
    _distance = null;
    _reports = null;
    _error = null;
    _refreshing = false;
    _category = LeaderboardCategory.distance;
    notifyListeners();
  }
}

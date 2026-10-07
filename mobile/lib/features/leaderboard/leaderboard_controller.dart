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

  LeaderboardResponse? get current {
    final cached =
        _category == LeaderboardCategory.distance ? _distance : _reports;
    // Drop mismatched entries (e.g. a raced distance payload stored under
    // reports) so the UI never formats meters as contributions.
    if (cached == null || cached.category != _category) return null;
    return cached;
  }

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
    // Capture the category this request is for. If the user switches tabs while
    // the request is in flight, we must NOT write the response into the other
    // cache (that previously showed distance meters as "katkı").
    final requested = _category;
    final showSpinner = forceSpinner || _cacheFor(requested) == null;
    if (showSpinner) {
      _state = LeaderboardLoadState.loading;
      _error = null;
      notifyListeners();
    } else {
      _refreshing = true;
      notifyListeners();
    }

    try {
      final next = await _api.fetchLeaderboard(requested);
      _store(next);
      if (_category == requested) {
        _state = LeaderboardLoadState.ready;
        _error = null;
      }
    } on ApiException catch (e) {
      if (_category == requested) {
        _error = e.message;
        if (_cacheFor(requested) == null) {
          _state = LeaderboardLoadState.error;
        }
      }
    } catch (e) {
      if (_category == requested) {
        _error = e.toString();
        if (_cacheFor(requested) == null) {
          _state = LeaderboardLoadState.error;
        }
      }
    } finally {
      if (_category == requested) {
        _refreshing = false;
      }
      notifyListeners();
    }
  }

  LeaderboardResponse? _cacheFor(LeaderboardCategory category) {
    return category == LeaderboardCategory.distance ? _distance : _reports;
  }

  void _store(LeaderboardResponse next) {
    // Prefer the category the API says it returned (must match the request).
    if (next.category == LeaderboardCategory.distance) {
      _distance = next;
    } else {
      _reports = next;
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

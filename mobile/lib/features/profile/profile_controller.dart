import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/features/profile/profile_models.dart';

enum ProfileLoadState { idle, loading, ready, error }

class ProfileController extends ChangeNotifier {
  ProfileController({required RadarApiClient apiClient}) : _api = apiClient;

  final RadarApiClient _api;

  ProfileLoadState _state = ProfileLoadState.idle;
  UserStats? _stats;
  String? _error;
  bool _refreshing = false;

  ProfileLoadState get state => _state;
  UserStats? get stats => _stats;
  String? get error => _error;
  bool get isLoading => _state == ProfileLoadState.loading;
  bool get isRefreshing => _refreshing;
  bool get hasCache => _stats != null;

  Future<void> load({bool forceSpinner = false}) async {
    final showSpinner = forceSpinner || _stats == null;
    if (showSpinner) {
      _state = ProfileLoadState.loading;
      _error = null;
      notifyListeners();
    } else {
      _refreshing = true;
      notifyListeners();
    }

    try {
      final next = await _api.fetchMyStats();
      _stats = next;
      _state = ProfileLoadState.ready;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (_stats == null) {
        _state = ProfileLoadState.error;
      }
    } catch (e) {
      _error = e.toString();
      if (_stats == null) {
        _state = ProfileLoadState.error;
      }
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(forceSpinner: false);

  void invalidate() {
    unawaited(refresh());
  }

  void clear() {
    _state = ProfileLoadState.idle;
    _stats = null;
    _error = null;
    _refreshing = false;
    notifyListeners();
  }
}

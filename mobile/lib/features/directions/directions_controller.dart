import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/api/google_directions_client.dart';
import 'package:radar_alert/data/api/google_places_client.dart';
import 'package:radar_alert/features/directions/directions_models.dart';

class DirectionsController extends ChangeNotifier {
  DirectionsController({
    GooglePlacesClient? placesClient,
    GoogleDirectionsClient? directionsClient,
  })  : _places = placesClient ?? GooglePlacesClient(),
        _directions = directionsClient ?? GoogleDirectionsClient();

  static const _debounce = Duration(milliseconds: 350);
  static const _minQueryLength = 2;

  final GooglePlacesClient _places;
  final GoogleDirectionsClient _directions;

  String _query = '';
  List<PlacePrediction> _predictions = const [];
  bool _isSearching = false;
  bool _isRouting = false;
  String? _destinationName;
  LatLng? _destinationLatLng;
  List<LatLng> _routePoints = const [];
  int? _distanceM;
  int? _durationSec;
  String? _errorMessage;

  /// Increments on each autocomplete request so stale responses are ignored.
  int _searchGen = 0;
  int _routeGen = 0;
  Timer? _debounceTimer;

  /// Last known GPS used to bias autocomplete; updated by the screen.
  LatLng? _locationBias;

  String get query => _query;
  List<PlacePrediction> get predictions => _predictions;
  bool get isSearching => _isSearching;
  bool get isRouting => _isRouting;
  String? get destinationName => _destinationName;
  LatLng? get destinationLatLng => _destinationLatLng;
  List<LatLng> get routePoints => _routePoints;
  int? get distanceM => _distanceM;
  int? get durationSec => _durationSec;
  String? get errorMessage => _errorMessage;

  bool get hasRoute => _routePoints.length >= 2;

  double? get distanceKm =>
      _distanceM == null ? null : _distanceM! / 1000.0;

  int? get durationMin => _durationSec == null
      ? null
      : (_durationSec! / 60).round().clamp(1, 9999);

  void setLocationBias(LatLng? bias) {
    _locationBias = bias;
  }

  void onQueryChanged(String text) {
    _query = text;
    _errorMessage = null;
    notifyListeners();

    _debounceTimer?.cancel();
    final trimmed = text.trim();
    if (trimmed.length < _minQueryLength) {
      _predictions = const [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(_debounce, () => _runAutocomplete(trimmed));
  }

  Future<void> _runAutocomplete(String input) async {
    final gen = ++_searchGen;
    _isSearching = true;
    notifyListeners();

    try {
      final results = await _places.autocomplete(
        input: input,
        bias: _locationBias,
      );
      if (gen != _searchGen) return;
      _predictions = results;
      _errorMessage = null;
    } on DirectionsException catch (e) {
      if (gen != _searchGen) return;
      _predictions = const [];
      _errorMessage = e.message;
    } catch (e) {
      if (gen != _searchGen) return;
      _predictions = const [];
      _errorMessage = 'Arama başarısız';
      debugPrint('Places autocomplete failed: $e');
    } finally {
      if (gen == _searchGen) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectPrediction(
    PlacePrediction prediction, {
    required DriverSnapshot? origin,
  }) async {
    _debounceTimer?.cancel();
    _searchGen++; // cancel in-flight autocomplete
    final gen = ++_routeGen;

    _query = prediction.description;
    _predictions = const [];
    _errorMessage = null;
    _isRouting = true;
    notifyListeners();

    if (origin == null) {
      _isRouting = false;
      _errorMessage = 'Konum bekleniyor';
      notifyListeners();
      return;
    }

    try {
      final place = await _places.details(placeId: prediction.placeId);
      if (gen != _routeGen) return;

      final route = await _directions.route(
        origin: LatLng(origin.lat, origin.lon),
        destination: place.latLng,
      );
      if (gen != _routeGen) return;

      _destinationName = place.name;
      _destinationLatLng = place.latLng;
      _routePoints = route.points;
      _distanceM = route.distanceM;
      _durationSec = route.durationSec;
      _errorMessage = null;
    } on DirectionsException catch (e) {
      if (gen != _routeGen) return;
      _errorMessage = e.message;
      if (e.isMissingGps) {
        // already handled above
      }
    } catch (e) {
      if (gen != _routeGen) return;
      _errorMessage = 'Rota alınamadı';
      debugPrint('Directions failed: $e');
    } finally {
      if (gen == _routeGen) {
        _isRouting = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry({required DriverSnapshot? origin}) async {
    if (_destinationLatLng == null) return;
    final dest = _destinationLatLng!;
    final name = _destinationName ?? 'Hedef';

    if (origin == null) {
      _errorMessage = 'Konum bekleniyor';
      notifyListeners();
      return;
    }

    final gen = ++_routeGen;
    _isRouting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final route = await _directions.route(
        origin: LatLng(origin.lat, origin.lon),
        destination: dest,
      );
      if (gen != _routeGen) return;
      _destinationName = name;
      _routePoints = route.points;
      _distanceM = route.distanceM;
      _durationSec = route.durationSec;
      _errorMessage = null;
    } on DirectionsException catch (e) {
      if (gen != _routeGen) return;
      _errorMessage = e.message;
    } catch (e) {
      if (gen != _routeGen) return;
      _errorMessage = 'Rota alınamadı';
      debugPrint('Directions retry failed: $e');
    } finally {
      if (gen == _routeGen) {
        _isRouting = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchGen++;
    _query = '';
    _predictions = const [];
    _isSearching = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearRoute() {
    _debounceTimer?.cancel();
    _routeGen++;
    _destinationName = null;
    _destinationLatLng = null;
    _routePoints = const [];
    _distanceM = null;
    _durationSec = null;
    _isRouting = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears both the search field and any active route.
  void clearAll() {
    _debounceTimer?.cancel();
    _searchGen++;
    _routeGen++;
    _query = '';
    _predictions = const [];
    _isSearching = false;
    _isRouting = false;
    _destinationName = null;
    _destinationLatLng = null;
    _routePoints = const [];
    _distanceM = null;
    _durationSec = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

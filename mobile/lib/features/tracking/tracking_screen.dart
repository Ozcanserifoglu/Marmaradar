import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/geo/geo_offset.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/directions/directions_controller.dart';
import 'package:radar_alert/features/directions/widgets/destination_search_bar.dart';
import 'package:radar_alert/features/directions/widgets/route_info_banner.dart';
import 'package:radar_alert/features/tracking/drive_recorder.dart';
import 'package:radar_alert/features/tracking/widgets/camera_alert_banner.dart';
import 'package:radar_alert/features/tracking/widgets/corridor_panel.dart';
import 'package:radar_alert/features/tracking/widgets/drive_panel.dart';
import 'package:radar_alert/features/tracking/widgets/radar_map_view.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  static const _headingMinSpeedMps = 1.5;

  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _follow = true;
  bool _centeredOnce = false;
  bool _wasDriving = false;
  bool _programmaticMove = false;
  double _currentZoom = 15.5;
  MapStyle _mapStyle = MapStyle.dark;

  int _fittedRouteLen = 0;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moveCamera(CameraUpdate update) async {
    final controller = _mapController;
    if (controller == null) return;
    _programmaticMove = true;
    try {
      await controller.moveCamera(update);
    } finally {
      // Let the platform deliver move-started before treating the next move as user-driven.
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        _programmaticMove = false;
      });
    }
  }

  Future<void> _animateCamera(CameraUpdate update) async {
    final controller = _mapController;
    if (controller == null) return;
    _programmaticMove = true;
    try {
      await controller.animateCamera(update);
    } finally {
      // Let the platform deliver move-started before treating the next move as user-driven.
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        _programmaticMove = false;
      });
    }
  }

  Future<void> _followDriver() async {
    final controller = ref.read(trackingControllerProvider);
    final snap = controller.lastSnapshot;
    if (snap == null || !_mapReady || _mapController == null) return;

    final driving = controller.isRunning;
    if (driving != _wasDriving) {
      _wasDriving = driving;
      if (!driving) {
        await _moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(snap.lat, snap.lon),
              zoom: _currentZoom,
              bearing: 0,
            ),
          ),
        );
      }
    }

    if (!_centeredOnce) {
      _centeredOnce = true;
      _currentZoom = 15.5;
      await _moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(snap.lat, snap.lon),
            zoom: 15.5,
            bearing: 0,
          ),
        ),
      );
      return;
    }
    if (!_follow) return;

    if (driving && snap.speedMps >= _headingMinSpeedMps) {
      await _driveCamera(snap);
      return;
    }

    final zoom = _currentZoom < 14 ? 15.5 : _currentZoom;
    _currentZoom = zoom;
    await _moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(snap.lat, snap.lon),
          zoom: zoom,
          bearing: 0,
        ),
      ),
    );
  }

  Future<void> _driveCamera(DriverSnapshot snap) async {
    final zoom = _currentZoom < 14 ? 16.5 : _currentZoom;
    _currentZoom = zoom;

    final metersPerPixel = 156543.03392 *
        math.cos(snap.lat * math.pi / 180) /
        math.pow(2, zoom);
    final lookAheadM =
        MediaQuery.sizeOf(context).height * 0.22 * metersPerPixel;

    final target = offsetByMeters(
      LatLng(snap.lat, snap.lon),
      lookAheadM,
      snap.headingDeg,
    );
    await _moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          bearing: snap.headingDeg,
        ),
      ),
    );
  }

  Future<void> _fitRoute(List<LatLng> points) async {
    if (!_mapReady || points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    if ((maxLat - minLat).abs() < 0.001) {
      minLat -= 0.005;
      maxLat += 0.005;
    }
    if ((maxLng - minLng).abs() < 0.001) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    setState(() => _follow = false);
    await _animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  void _recenter() {
    setState(() => _follow = true);
    _followDriver();
  }

  void _toggleMapStyle() {
    setState(() {
      _mapStyle = _mapStyle == MapStyle.dark ? MapStyle.light : MapStyle.dark;
    });
  }

  void _onClearSearch() {
    final directions = ref.read(directionsControllerProvider);
    if (directions.hasRoute) {
      directions.clearAll();
      _fittedRouteLen = 0;
    } else {
      directions.clearSearch();
    }
  }

  void _onClearRoute() {
    ref.read(directionsControllerProvider).clearRoute();
    _fittedRouteLen = 0;
  }

  Future<void> _promptSaveDrive() async {
    if (!mounted) return;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sürüşü kaydet'),
        content: const Text(
          'Sürüşünü buluta kaydetmek için giriş yapman gerekiyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Giriş yap'),
          ),
        ],
      ),
    );
    if (shouldLogin != true || !mounted) return;

    final signedIn = await showAuthModal(context);
    if (!signedIn || !mounted) return;

    await ref.read(trackingControllerProvider).uploadPendingDrive();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trackingControllerProvider, (previous, next) {
      final snap = next.lastSnapshot;
      if (snap != null) {
        ref.read(directionsControllerProvider).setLocationBias(
              LatLng(snap.lat, snap.lon),
            );
      }
      _followDriver();

      final becameNeedsAuth = previous?.driveUploadStatus !=
              DriveUploadStatus.needsAuth &&
          next.driveUploadStatus == DriveUploadStatus.needsAuth;
      if (becameNeedsAuth) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptSaveDrive();
        });
      }
    });

    ref.listen<DirectionsController>(directionsControllerProvider,
        (previous, next) {
      if (next.hasRoute && next.routePoints.length != _fittedRouteLen) {
        _fittedRouteLen = next.routePoints.length;
        _fitRoute(next.routePoints);
      }
      if (!next.hasRoute) {
        _fittedRouteLen = 0;
      }
    });

    final controller = ref.watch(trackingControllerProvider);
    final directions = ref.watch(directionsControllerProvider);
    final approaching = controller.approaching;
    final corridorStatus = controller.corridorStatus;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RadarMapView(
              style: _mapStyle,
              snapshot: controller.lastSnapshot,
              cameras: controller.mapCameras,
              corridors: controller.mapCorridors,
              amenities: controller.mapAmenities,
              approaching: approaching,
              routePoints: directions.hasRoute ? directions.routePoints : null,
              destination: directions.destinationLatLng,
              destinationTitle: directions.destinationName,
              isProgrammaticMove: () => _programmaticMove,
              onMapCreated: (mapController) {
                _mapController = mapController;
                _mapReady = true;
                _followDriver();
              },
              onCameraMoved: (zoom) => _currentZoom = zoom,
              onUserGesture: () {
                if (_follow) setState(() => _follow = false);
              },
            ),
          ),

          Positioned(
            top: padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                DestinationSearchBar(
                  query: directions.query,
                  predictions: directions.predictions,
                  isSearching: directions.isSearching,
                  isRouting: directions.isRouting,
                  errorMessage: directions.errorMessage,
                  onQueryChanged: (q) {
                    final snap = controller.lastSnapshot;
                    if (snap != null) {
                      directions.setLocationBias(
                        LatLng(snap.lat, snap.lon),
                      );
                    }
                    directions.onQueryChanged(q);
                  },
                  onClear: _onClearSearch,
                  onPredictionSelected: (prediction) {
                    FocusScope.of(context).unfocus();
                    directions.selectPrediction(
                      prediction,
                      origin: controller.lastSnapshot,
                    );
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                  child: approaching != null
                      ? Padding(
                          key: ValueKey(approaching.camera.id),
                          padding: const EdgeInsets.only(top: 10),
                          child: CameraAlertBanner(approaching: approaching),
                        )
                      : const SizedBox.shrink(),
                ),
                if (corridorStatus != null) ...[
                  const SizedBox(height: 10),
                  CorridorPanel(status: corridorStatus),
                ],
                if (directions.hasRoute &&
                    directions.distanceKm != null &&
                    directions.durationMin != null) ...[
                  const SizedBox(height: 10),
                  RouteInfoBanner(
                    destinationName:
                        directions.destinationName ?? 'Hedef',
                    distanceKm: directions.distanceKm!,
                    durationMin: directions.durationMin!,
                    onClear: _onClearRoute,
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 200 + padding.bottom,
            child: Column(
              children: [
                _MapButton(
                  icon: _mapStyle == MapStyle.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  tooltip: _mapStyle == MapStyle.dark
                      ? 'Açık harita'
                      : 'Koyu harita',
                  onTap: _toggleMapStyle,
                ),
                if (!_follow) ...[
                  const SizedBox(height: 10),
                  _MapButton(
                    icon: Icons.my_location,
                    tooltip: 'Konumuma dön',
                    highlighted: true,
                    onTap: _recenter,
                  ),
                ],
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: DrivePanel(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted ? AppColors.red : AppColors.night,
        shape: CircleBorder(
          side: BorderSide(
            color: highlighted ? AppColors.white : AppColors.outline,
            width: 1.5,
          ),
        ),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

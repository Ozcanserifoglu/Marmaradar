import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/geo/geo_offset.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
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
  /// GPS headings are noise below walking speed; don't steer the camera with
  /// them or the map would spin while waiting at a light.
  static const _headingMinSpeedMps = 1.5;

  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _follow = true;
  bool _centeredOnce = false;
  bool _wasDriving = false;
  bool _programmaticMove = false;
  double _currentZoom = 15.5;
  MapStyle _mapStyle = MapStyle.dark;

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
      // Allow the platform a beat to deliver move-started for this update
      // before gesture detection treats the next move as user-driven.
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
      // Drive ended: settle back to a north-up map.
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

    // Always jump to the very first fix so the map opens where the user is,
    // then keep following only while follow mode is on.
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

  /// Google Maps-style chase view: the map rotates so the direction of travel
  /// points up, and the camera aims ahead of the car so the driver marker
  /// sits in the lower part of the screen with the road ahead filling it.
  Future<void> _driveCamera(DriverSnapshot snap) async {
    final zoom = _currentZoom < 14 ? 16.5 : _currentZoom;
    _currentZoom = zoom;

    // Meters per logical pixel for 256px web-mercator tiles at this
    // zoom/latitude, used to convert the desired screen offset into a
    // geographic look-ahead distance.
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

  void _recenter() {
    setState(() => _follow = true);
    _followDriver();
  }

  void _toggleMapStyle() {
    setState(() {
      _mapStyle = _mapStyle == MapStyle.dark ? MapStyle.light : MapStyle.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trackingControllerProvider, (previous, next) => _followDriver());

    final controller = ref.watch(trackingControllerProvider);
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
              approaching: approaching,
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

          // Top overlays: alert banner and corridor panel.
          Positioned(
            top: padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
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
                      ? CameraAlertBanner(
                          key: ValueKey(approaching.camera.id),
                          approaching: approaching,
                        )
                      : const SizedBox.shrink(),
                ),
                if (corridorStatus != null) ...[
                  const SizedBox(height: 10),
                  CorridorPanel(status: corridorStatus),
                ],
              ],
            ),
          ),

          // Map controls: style toggle + recenter.
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

          // Bottom control dock.
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

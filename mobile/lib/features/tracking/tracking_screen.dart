import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:radar_alert/app.dart';
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
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _follow = true;
  bool _centeredOnce = false;
  MapStyle _mapStyle = MapStyle.dark;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _followDriver() {
    final controller = ref.read(trackingControllerProvider);
    final snap = controller.lastSnapshot;
    if (snap == null || !_mapReady) return;

    // Always jump to the very first fix so the map opens where the user is,
    // then keep following only while follow mode is on.
    if (!_centeredOnce) {
      _centeredOnce = true;
      _mapController.move(LatLng(snap.lat, snap.lon), 15.5);
      return;
    }
    if (!_follow) return;
    _mapController.move(
      LatLng(snap.lat, snap.lon),
      _mapController.camera.zoom < 14 ? 15.5 : _mapController.camera.zoom,
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
              mapController: _mapController,
              style: _mapStyle,
              snapshot: controller.lastSnapshot,
              cameras: controller.mapCameras,
              corridors: controller.mapCorridors,
              approaching: approaching,
              onMapReady: () {
                _mapReady = true;
                _followDriver();
              },
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

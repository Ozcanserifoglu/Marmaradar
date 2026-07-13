import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';

/// Bursa city center, used before the first GPS fix arrives.
const _fallbackCenter = LatLng(40.1885, 29.0610);

/// Keeps the map centered somewhere over Turkey (with a little slack past the
/// borders) so it can never get "lost" in empty world tiles.
final _turkeyBounds = LatLngBounds(
  const LatLng(35.0, 24.5),
  const LatLng(42.9, 45.5),
);

/// Below this zoom the country-wide camera set is drawn as cheap canvas dots
/// instead of full marker widgets.
const _markerMinZoom = 10.0;

enum MapStyle { dark, light }

class RadarMapView extends StatelessWidget {
  const RadarMapView({
    super.key,
    required this.mapController,
    required this.style,
    required this.snapshot,
    required this.cameras,
    required this.corridors,
    required this.approaching,
    required this.onUserGesture,
    required this.onMapReady,
  });

  final MapController mapController;
  final MapStyle style;
  final DriverSnapshot? snapshot;
  final List<CachedCamera> cameras;
  final List<CachedCorridorWithGates> corridors;
  final ApproachingCamera? approaching;
  final VoidCallback onUserGesture;
  final VoidCallback onMapReady;

  bool get _isDark => style == MapStyle.dark;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: snapshot != null
            ? LatLng(snapshot!.lat, snapshot!.lon)
            : _fallbackCenter,
        initialZoom: 15,
        minZoom: 5,
        maxZoom: 18,
        // containCenter (not contain): it allows zooming out far enough to
        // see the whole country and stays stable while the camera is rotated
        // in the driving chase view.
        cameraConstraint: CameraConstraint.containCenter(bounds: _turkeyBounds),
        backgroundColor: _isDark ? AppColors.night : const Color(0xFFE8E8E6),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.scrollWheelZoom,
          // Default wheel zoom is far too aggressive; one notch should be a
          // gentle zoom step, not a jump across zoom levels.
          scrollWheelVelocity: 0.002,
        ),
        onMapReady: onMapReady,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) onUserGesture();
        },
      ),
      children: [
        if (_isDark)
          // Lift the shadows of CARTO's dark tiles so roads and labels stay
          // readable at night without abandoning the black look.
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.9, 0, 0, 0, 26,
              0, 1.9, 0, 0, 26,
              0, 0, 1.9, 0, 30,
              0, 0, 0, 1, 0,
            ]),
            child: TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.radaralert.radar_alert',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
          )
        else
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.radaralert.radar_alert',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
        PolylineLayer(polylines: _corridorLines()),
        if (approaching != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(
                  approaching!.camera.lat,
                  approaching!.camera.lon,
                ),
                radius: approaching!.camera.alertRadiusM,
                useRadiusInMeter: true,
                color: AppColors.red.withValues(alpha: 0.10),
                borderColor: AppColors.red.withValues(alpha: 0.45),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        // With the country-wide dataset, thousands of marker widgets would
        // jank the map when zoomed out — render cheap canvas dots instead
        // until the user is close enough for individual markers to matter.
        Builder(
          builder: (context) {
            if (MapCamera.of(context).zoom < _markerMinZoom) {
              return CircleLayer(
                circles: [
                  for (final cam in cameras)
                    CircleMarker(
                      point: LatLng(cam.lat, cam.lon),
                      radius: 3,
                      color: AppColors.red.withValues(alpha: 0.75),
                    ),
                ],
              );
            }
            // rotate: keeps speed-limit signs and gate icons upright while
            // the map itself rotates in the driving chase view.
            return MarkerLayer(
              rotate: true,
              markers: [..._gateMarkers(), ..._cameraMarkers()],
            );
          },
        ),
        if (snapshot != null)
          // Deliberately NOT counter-rotated: the arrow is rotated by the
          // geographic heading inside the marker, so when the chase view
          // rotates the map by -heading the arrow always points up-screen.
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(snapshot!.lat, snapshot!.lon),
                width: 52,
                height: 52,
                child: _UserMarker(headingDeg: snapshot!.headingDeg),
              ),
            ],
          ),
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: _Attribution(),
          ),
        ),
      ],
    );
  }

  List<Polyline> _corridorLines() {
    final lines = <Polyline>[];
    for (final item in corridors) {
      final gates = [...item.gates]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final entries = gates.where((g) => g.gateType == 'entry').toList();
      final exits = gates.where((g) => g.gateType == 'exit').toList();
      if (entries.isEmpty || exits.isEmpty) continue;
      lines.add(
        Polyline(
          points: [
            for (final g in entries) LatLng(g.lat, g.lon),
            for (final g in exits) LatLng(g.lat, g.lon),
          ],
          strokeWidth: 4,
          color: AppColors.red.withValues(alpha: 0.55),
          pattern: const StrokePattern.dotted(),
        ),
      );
    }
    return lines;
  }

  List<Marker> _cameraMarkers() {
    return [
      for (final cam in cameras)
        Marker(
          point: LatLng(cam.lat, cam.lon),
          width: 40,
          height: 40,
          child: _CameraMarker(
            camera: cam,
            highlighted: approaching?.camera.id == cam.id,
          ),
        ),
    ];
  }

  List<Marker> _gateMarkers() {
    final markers = <Marker>[];
    for (final item in corridors) {
      for (final gate in item.gates) {
        markers.add(
          Marker(
            point: LatLng(gate.lat, gate.lon),
            width: 30,
            height: 30,
            child: _GateMarker(isEntry: gate.gateType == 'entry'),
          ),
        );
      }
    }
    return markers;
  }
}

/// Driver position: red disc with a white heading arrow.
class _UserMarker extends StatelessWidget {
  const _UserMarker({required this.headingDeg});

  final double headingDeg;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.red,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Transform.rotate(
        angle: headingDeg * math.pi / 180,
        child: const Icon(Icons.navigation, color: AppColors.white, size: 26),
      ),
    );
  }
}

/// Speed camera: looks like a Turkish speed-limit sign when the limit is
/// known, otherwise a camera badge.
class _CameraMarker extends StatelessWidget {
  const _CameraMarker({required this.camera, required this.highlighted});

  final CachedCamera camera;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final limit = camera.maxspeedKmh;

    return AnimatedScale(
      scale: highlighted ? 1.25 : 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: limit != null ? AppColors.white : AppColors.night,
          border: Border.all(
            color: AppColors.red,
            width: limit != null ? 4 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: highlighted
                  ? AppColors.red.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: highlighted ? 14 : 6,
              spreadRadius: highlighted ? 2 : 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: limit != null
            ? Text(
                '$limit',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              )
            : const Icon(Icons.videocam, color: AppColors.white, size: 18),
      ),
    );
  }
}

class _GateMarker extends StatelessWidget {
  const _GateMarker({required this.isEntry});

  final bool isEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEntry ? AppColors.white : AppColors.red,
        border: Border.all(
          color: isEntry ? AppColors.red : AppColors.white,
          width: 2,
        ),
      ),
      child: Icon(
        isEntry ? Icons.login : Icons.logout,
        size: 14,
        color: isEntry ? AppColors.red : AppColors.white,
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.night.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '© OpenStreetMap · © CARTO',
        style: TextStyle(fontSize: 10, color: AppColors.whiteMuted),
      ),
    );
  }
}

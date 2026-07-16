import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/geo/encoded_polyline.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/widgets/camera_detail_sheet.dart';
import 'package:radar_alert/features/tracking/widgets/map_marker_icons.dart';

/// Bursa city center, used before the first GPS fix arrives.
const _fallbackCenter = LatLng(40.1885, 29.0610);

/// Keeps the map centered somewhere over Turkey (with a little slack past the
/// borders) so it can never get "lost" in empty world tiles.
final _turkeyBounds = LatLngBounds(
  southwest: const LatLng(35.0, 24.5),
  northeast: const LatLng(42.9, 45.5),
);

/// Below this zoom the country-wide camera set is drawn as cheap dots
/// instead of full marker icons.
const _markerMinZoom = 10.0;

enum MapStyle { dark, light }

class RadarMapView extends StatefulWidget {
  const RadarMapView({
    super.key,
    required this.style,
    required this.snapshot,
    required this.cameras,
    required this.corridors,
    required this.approaching,
    required this.onMapCreated,
    required this.onUserGesture,
    required this.onCameraMoved,
    required this.isProgrammaticMove,
    this.routePoints,
    this.destination,
    this.destinationTitle,
  });

  final MapStyle style;
  final DriverSnapshot? snapshot;
  final List<CachedCamera> cameras;
  final List<CachedCorridorWithGates> corridors;
  final ApproachingCamera? approaching;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onUserGesture;
  final ValueChanged<double> onCameraMoved;

  /// When true, camera moves come from chase/follow logic — ignore for
  /// breaking follow mode.
  final bool Function() isProgrammaticMove;

  /// Live Directions route (blue). Independent of corridor overlays.
  final List<LatLng>? routePoints;
  final LatLng? destination;
  final String? destinationTitle;

  @override
  State<RadarMapView> createState() => _RadarMapViewState();
}

class _RadarMapViewState extends State<RadarMapView> {
  double _zoom = 15;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  int _overlayGen = 0;

  @override
  void initState() {
    super.initState();
    _rebuildOverlays();
  }

  @override
  void didUpdateWidget(covariant RadarMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot ||
        oldWidget.cameras != widget.cameras ||
        oldWidget.corridors != widget.corridors ||
        oldWidget.approaching != widget.approaching ||
        oldWidget.routePoints != widget.routePoints ||
        oldWidget.destination != widget.destination ||
        oldWidget.destinationTitle != widget.destinationTitle) {
      _rebuildOverlays();
    }
  }

  Future<void> _rebuildOverlays() async {
    final gen = ++_overlayGen;
    final zoom = _zoom;
    final approaching = widget.approaching;
    final cameras = widget.cameras;
    final corridors = widget.corridors;
    final snapshot = widget.snapshot;

    final polylines = <Polyline>{};
    for (final item in corridors) {
      final encoded = item.corridor.polyline;
      if (encoded != null && encoded.isNotEmpty) {
        final points = decodePolyline(encoded);
        if (points.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('corridor_${item.corridor.id}'),
              points: points,
              width: 6,
              color: AppColors.corridor.withValues(alpha: 0.85),
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              zIndex: 1,
            ),
          );
          continue;
        }
      }

      final gates = [...item.gates]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final entries = gates.where((g) => g.gateType == 'entry').toList();
      final exits = gates.where((g) => g.gateType == 'exit').toList();
      if (entries.isEmpty || exits.isEmpty) continue;
      polylines.add(
        Polyline(
          polylineId: PolylineId('corridor_fallback_${item.corridor.id}'),
          points: [
            for (final g in entries) LatLng(g.lat, g.lon),
            for (final g in exits) LatLng(g.lat, g.lon),
          ],
          width: 4,
          color: AppColors.corridor.withValues(alpha: 0.6),
          patterns: [PatternItem.dot, PatternItem.gap(12)],
          zIndex: 1,
        ),
      );
    }

    final routePoints = widget.routePoints;
    if (routePoints != null && routePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('directions_route'),
          points: routePoints,
          width: 6,
          color: AppColors.route.withValues(alpha: 0.95),
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: 2,
        ),
      );
    }

    final circles = <Circle>{};
    if (approaching != null) {
      circles.add(
        Circle(
          circleId: const CircleId('alert'),
          center: LatLng(
            approaching.camera.lat,
            approaching.camera.lon,
          ),
          radius: approaching.camera.alertRadiusM,
          fillColor: AppColors.red.withValues(alpha: 0.10),
          strokeColor: AppColors.red.withValues(alpha: 0.45),
          strokeWidth: 2,
          zIndex: 0,
        ),
      );
    }

    final markers = <Marker>{};
    if (zoom < _markerMinZoom) {
      final dot = await MapMarkerIcons.cameraDot();
      if (gen != _overlayGen) return;
      for (final cam in cameras) {
        markers.add(
          Marker(
            markerId: MarkerId('cam_dot_${cam.id}'),
            position: LatLng(cam.lat, cam.lon),
            icon: dot,
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: true,
            onTap: () {
              if (mounted) showCameraDetailSheet(context, cam);
            },
          ),
        );
      }
    } else {
      final entryIcon = await MapMarkerIcons.gate(isEntry: true);
      final exitIcon = await MapMarkerIcons.gate(isEntry: false);
      if (gen != _overlayGen) return;

      for (final item in corridors) {
        for (final gate in item.gates) {
          final isEntry = gate.gateType == 'entry';
          markers.add(
            Marker(
              markerId: MarkerId('gate_${gate.id}'),
              position: LatLng(gate.lat, gate.lon),
              icon: isEntry ? entryIcon : exitIcon,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 2,
            ),
          );
        }
      }

      for (final cam in cameras) {
        final highlighted = approaching?.camera.id == cam.id;
        final icon = await MapMarkerIcons.camera(
          maxspeedKmh: cam.maxspeedKmh,
          highlighted: highlighted,
        );
        if (gen != _overlayGen) return;
        markers.add(
          Marker(
            markerId: MarkerId('cam_${cam.id}'),
            position: LatLng(cam.lat, cam.lon),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: highlighted ? 4 : 3,
            consumeTapEvents: true,
            onTap: () {
              if (mounted) showCameraDetailSheet(context, cam);
            },
          ),
        );
      }
    }

    if (snapshot != null) {
      final userIcon = await MapMarkerIcons.user();
      if (gen != _overlayGen) return;
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(snapshot.lat, snapshot.lon),
          icon: userIcon,
          anchor: const Offset(0.5, 0.5),
          // Flat + rotation: geographic heading; chase bearing keeps it
          // pointing up-screen while driving.
          flat: true,
          rotation: snapshot.headingDeg,
          zIndexInt: 10,
        ),
      );
    }

    final destination = widget.destination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('directions_destination'),
          position: destination,
          infoWindow: InfoWindow(
            title: widget.destinationTitle ?? 'Hedef',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 9,
        ),
      );
    }

    if (!mounted || gen != _overlayGen) return;
    setState(() {
      _markers = markers;
      _polylines = polylines;
      _circles = circles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.snapshot != null
        ? LatLng(widget.snapshot!.lat, widget.snapshot!.lon)
        : _fallbackCenter;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: 15),
      mapType: MapType.normal,
      style: widget.style == MapStyle.dark ? googleMapsDarkStyleJson : null,
      minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
      cameraTargetBounds: CameraTargetBounds(_turkeyBounds),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: false,
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      onMapCreated: widget.onMapCreated,
      onCameraMoveStarted: () {
        if (!widget.isProgrammaticMove()) {
          widget.onUserGesture();
        }
      },
      onCameraMove: (position) {
        final crossed =
            (_zoom < _markerMinZoom) != (position.zoom < _markerMinZoom);
        _zoom = position.zoom;
        widget.onCameraMoved(position.zoom);
        if (crossed) _rebuildOverlays();
      },
    );
  }
}

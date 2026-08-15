import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/geo/encoded_polyline.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/corridors/corridor_tracker.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/widgets/amenity_detail_sheet.dart';
import 'package:radar_alert/features/tracking/widgets/camera_detail_sheet.dart';
import 'package:radar_alert/features/tracking/widgets/map_marker_icons.dart';

const _fallbackCenter = LatLng(40.1885, 29.0610);

final _turkeyBounds = LatLngBounds(
  southwest: const LatLng(35.0, 24.5),
  northeast: const LatLng(42.9, 45.5),
);

const _markerMinZoom = 10.0;

const _amenityMinZoom = AmenityConstants.minZoom;

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
    this.amenities = const [],
    this.routePoints,
    this.destination,
    this.destinationTitle,
  });

  final MapStyle style;
  final DriverSnapshot? snapshot;
  final List<CachedCamera> cameras;
  final List<CachedCorridorWithGates> corridors;
  final ApproachingCamera? approaching;
  final List<AmenityPlace> amenities;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onUserGesture;
  final ValueChanged<double> onCameraMoved;

  final bool Function() isProgrammaticMove;

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
        oldWidget.amenities != widget.amenities ||
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

    if (zoom >= _amenityMinZoom && widget.amenities.isNotEmpty) {
      final gasIcon = await MapMarkerIcons.gasStation();
      final restIcon = await MapMarkerIcons.restStop();
      if (gen != _overlayGen) return;
      for (final place in widget.amenities) {
        final isGas = place.category == AmenityCategory.gasStation;
        markers.add(
          Marker(
            markerId: MarkerId('amenity_${place.placeId}'),
            position: LatLng(place.lat, place.lon),
            icon: isGas ? gasIcon : restIcon,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
            consumeTapEvents: true,
            onTap: () {
              if (mounted) showAmenityDetailSheet(context, place);
            },
          ),
        );
      }
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
        final crossedCamera =
            (_zoom < _markerMinZoom) != (position.zoom < _markerMinZoom);
        final crossedAmenity =
            (_zoom < _amenityMinZoom) != (position.zoom < _amenityMinZoom);
        _zoom = position.zoom;
        widget.onCameraMoved(position.zoom);
        if (crossedCamera || crossedAmenity) _rebuildOverlays();
      },
    );
  }
}

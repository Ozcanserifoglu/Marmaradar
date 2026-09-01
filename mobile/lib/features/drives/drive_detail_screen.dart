import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/tracking/widgets/radar_map_view.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drive_replay_controller.dart';
import 'package:radar_alert/features/drives/drive_speed_stats.dart';
import 'package:radar_alert/features/drives/drive_video_download.dart';
import 'package:radar_alert/features/drives/rename_drive_dialog.dart';
import 'package:radar_alert/features/tracking/widgets/map_marker_icons.dart';

class DriveDetailScreen extends ConsumerStatefulWidget {
  const DriveDetailScreen({super.key, required this.driveId});

  final String driveId;

  @override
  ConsumerState<DriveDetailScreen> createState() => _DriveDetailScreenState();
}

class _DriveDetailScreenState extends ConsumerState<DriveDetailScreen> {
  late final Future<DriveDetail> _future;
  DriveReplayController? _replay;
  DriveDetail? _detail;
  BitmapDescriptor? _carIcon;
  GoogleMapController? _mapController;

  String? _nameOverride;
  bool _nameOverridden = false;
  bool _exporting = false;
  final GlobalKey _shareButtonKey = GlobalKey();

  String? get _effectiveName =>
      _nameOverridden ? _nameOverride : _detail?.summary.name;

  Future<void> _rename() async {
    final result = await showRenameDriveDialog(
      context,
      ref,
      driveId: widget.driveId,
      currentName: _effectiveName,
    );
    if (result != null && mounted) {
      setState(() {
        _nameOverride = result.isEmpty ? null : result;
        _nameOverridden = true;
      });
    }
  }

  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _exportVideo(DriveDetail detail, DriveVideoIntent intent) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final vehicle = ref.read(vehicleCustomizationControllerProvider);
    await exportDriveVideo(
      context,
      detail: detail,
      intent: intent,
      nameOverride: _effectiveName,
      vehicleType: vehicle.vehicleType,
      vehicleColor: vehicle.vehicleColor,
      sharePositionOrigin:
          intent == DriveVideoIntent.share ? _shareOrigin() : null,
    );
    if (mounted) setState(() => _exporting = false);
  }

  @override
  void initState() {
    super.initState();
    _future = ref.read(drivesControllerProvider).loadDetail(widget.driveId);
    _future.then((detail) {
      if (mounted) setState(() => _detail = detail);
    }, onError: (_) {});
    _loadCarIcon();
  }

  void _loadCarIcon() {
    final vehicle = ref.read(vehicleCustomizationControllerProvider);
    MapMarkerIcons.vehicle(
      type: vehicle.vehicleType,
      color: vehicle.vehicleColor,
    ).then((icon) {
      if (mounted) setState(() => _carIcon = icon);
    });
  }

  @override
  void dispose() {
    _replay?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  DriveReplayController _controllerFor(DriveDetail detail) {
    return _replay ??= DriveReplayController(
      detail.points,
      displayRoute: [
        for (final p in detail.displayPoints) LatLng(p.lat, p.lon),
      ],
    );
  }

  Future<void> _fitToRoute(List<LatLng> points) async {
    final controller = _mapController;
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLon = points.first.longitude, maxLon = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLon = p.longitude < minLon ? p.longitude : minLon;
      maxLon = p.longitude > maxLon ? p.longitude : maxLon;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vehicleCustomizationControllerProvider, (prev, next) {
      if (prev?.vehicleType != next.vehicleType ||
          prev?.vehicleColor != next.vehicleColor) {
        _loadCarIcon();
      }
    });
    return PopScope(
      canPop: !_exporting,
      child: FutureBuilder<DriveDetail>(
        future: _future,
        builder: (context, snapshot) {
          final detail = snapshot.data ?? _detail;
          if (snapshot.hasData) {
            _detail = snapshot.data;
          }
          final title = detail == null
              ? 'Sürüş kaydı'
              : driveDisplayName(_effectiveName, detail.summary.startedAt);

          return Scaffold(
            appBar: AppBar(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                if (detail != null && detail.points.length >= 2) ...[
                  IconButton(
                    tooltip: 'Videoyu indir',
                    icon: const Icon(Icons.download_rounded),
                    onPressed: _exporting
                        ? null
                        : () => _exportVideo(
                              detail,
                              DriveVideoIntent.saveToGallery,
                            ),
                  ),
                  IconButton(
                    key: _shareButtonKey,
                    tooltip: 'Paylaş',
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _exporting
                        ? null
                        : () => _exportVideo(detail, DriveVideoIntent.share),
                  ),
                ],
                if (detail != null && !detail.summary.isLocal)
                  IconButton(
                    tooltip: 'Yeniden adlandır',
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: _exporting ? null : _rename,
                  ),
              ],
            ),
            body: _detailBody(snapshot, detail),
          );
        },
      ),
    );
  }

  Widget _detailBody(
    AsyncSnapshot<DriveDetail> snapshot,
    DriveDetail? detail,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.red),
      );
    }
    if (snapshot.hasError || detail == null) {
      return _error(snapshot.error);
    }
    if (detail.points.length < 2) {
      return _tooShort(detail);
    }
    final replay = _controllerFor(detail);
    return _content(detail, replay);
  }

  Widget _content(DriveDetail detail, DriveReplayController replay) {
    final route = replay.routePoints;
    return Column(
      children: [
        _SummaryBar(summary: detail.summary, points: detail.points),
        Expanded(
          child: _ReplayMap(
            replay: replay,
            route: route,
            carIcon: _carIcon,
            style: ref.watch(appearanceControllerProvider).resolvedMapStyle,
            onCreated: (c) {
              _mapController = c;
              _fitToRoute(route);
            },
            markersFor: _markers,
          ),
        ),
        _PlaybackBar(replay: replay),
      ],
    );
  }

  Set<Marker> _markers(DriveReplayController replay) {
    final markers = <Marker>{};
    final start = replay.start;
    final end = replay.end;
    if (start != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: start,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          anchor: const Offset(0.5, 1),
          zIndexInt: 1,
        ),
      );
    }
    if (end != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: end,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
          anchor: const Offset(0.5, 1),
          zIndexInt: 1,
        ),
      );
    }
    final car = replay.carPosition;
    if (car != null && _carIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('car'),
          position: car,
          icon: _carIcon!,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: replay.carHeading,
          zIndexInt: 10,
        ),
      );
    }
    return markers;
  }

  Widget _error(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.whiteMuted),
            const SizedBox(height: 16),
            Text(
              'Sürüş yüklenemedi.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.whiteMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tooShort(DriveDetail detail) {
    return Column(
      children: [
        _SummaryBar(summary: detail.summary, points: detail.points),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Bu sürüşte tekrar oynatmak için yeterli konum verisi yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.whiteMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.summary, required this.points});

  final DriveSummary summary;
  final List<DrivePoint> points;

  @override
  Widget build(BuildContext context) {
    final computed = DriveSpeedStats.fromPoints(
      [for (final p in points) (speedMps: p.speedMps)],
      lengthM: summary.lengthM,
      duration: summary.duration,
    );
    final avg = summary.avgSpeedKmh ?? computed.avgKmh;
    final minV = summary.minSpeedKmh ?? computed.minKmh;
    final maxV = summary.maxSpeedKmh ?? computed.maxKmh;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDriveDate(summary.startedAt),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(label: 'Mesafe', value: formatDistance(summary.lengthM)),
              _Stat(label: 'Süre', value: formatDuration(summary.duration)),
              _Stat(label: 'Ort', value: formatSpeedKmh(avg)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(label: 'Min', value: formatSpeedKmh(minV)),
              _Stat(label: 'Max', value: formatSpeedKmh(maxV)),
              _Stat(label: 'Nokta', value: '${summary.pointCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.whiteMuted),
          ),
        ],
      ),
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({required this.replay});

  final DriveReplayController replay;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: replay,
      builder: (context, _) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            8 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.red,
                  inactiveTrackColor: AppColors.outline,
                  thumbColor: AppColors.red,
                  overlayColor: AppColors.red.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: replay.progress,
                  onChanged: replay.canPlay ? replay.seek : null,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    iconSize: 40,
                    color: AppColors.red,
                    onPressed: replay.canPlay ? replay.togglePlay : null,
                    icon: Icon(
                      replay.isFinished
                          ? Icons.replay_circle_filled_rounded
                          : replay.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${speedKmh(replay.carSpeedMps)} km/s',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          '${formatDistance(replay.traveledM)} / ${formatDistance(replay.routeLengthM)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.whiteMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final option in DriveReplayController.speedOptions)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _SpeedChip(
                        label: '${option.toStringAsFixed(0)}x',
                        selected: replay.speed == option,
                        onTap: () => replay.setSpeed(option),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.red : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.whiteMuted,
          ),
        ),
      ),
    );
  }
}

class _ReplayMap extends StatefulWidget {
  const _ReplayMap({
    required this.replay,
    required this.route,
    required this.carIcon,
    required this.style,
    required this.onCreated,
    required this.markersFor,
  });

  final DriveReplayController replay;
  final List<LatLng> route;
  final BitmapDescriptor? carIcon;
  final MapStyle style;
  final void Function(GoogleMapController controller) onCreated;
  final Set<Marker> Function(DriveReplayController replay) markersFor;

  @override
  State<_ReplayMap> createState() => _ReplayMapState();
}

class _ReplayMapState extends State<_ReplayMap> {
  late final Set<Polyline> _polylines = {
    Polyline(
      polylineId: const PolylineId('drive_route'),
      points: widget.route,
      width: 6,
      color: AppColors.red.withValues(alpha: 0.9),
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ),
  };

  @override
  void initState() {
    super.initState();
    widget.replay.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _ReplayMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replay != widget.replay) {
      oldWidget.replay.removeListener(_onTick);
      widget.replay.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.replay.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.replay.start ?? const LatLng(40.1885, 29.0610),
        zoom: 13,
      ),
      style: widget.style == MapStyle.dark ? googleMapsDarkStyleJson : null,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: widget.onCreated,
      polylines: _polylines,
      markers: widget.markersFor(widget.replay),
    );
  }
}

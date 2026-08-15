import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drive_replay_controller.dart';
import 'package:radar_alert/features/drives/drive_video_exporter.dart';
import 'package:radar_alert/features/drives/rename_drive_dialog.dart';
import 'package:radar_alert/features/tracking/widgets/map_marker_icons.dart';
import 'package:share_plus/share_plus.dart';

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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _downloadVideo(DriveDetail detail) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final progress = ValueNotifier<double>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportProgressDialog(progress: progress),
    );

    String? path;
    Object? error;
    try {
      path = await DriveVideoExporter.export(
        points: detail.points,
        displayPoints: detail.displayPoints,
        title: driveDisplayName(_effectiveName, detail.summary.startedAt),
        lengthM: detail.summary.lengthM,
        duration: detail.summary.duration,
        onProgress: (p) => progress.value = p,
      );
    } catch (e) {
      error = e;
    }

    if (!mounted) {
      progress.dispose();
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _exporting = false);
    progress.dispose();

    if (error != null || path == null) {
      _snack('Video oluşturulamadı.');
      return;
    }

    try {
      await Gal.requestAccess();
      await Gal.putVideo(path);
      _snack('Galeriye kaydedildi');
    } catch (_) {
    }

    if (!mounted) return;
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Marmaradar sürüş kaydı',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    } catch (_) {
    }
  }

  @override
  void initState() {
    super.initState();
    _future = ref.read(drivesControllerProvider).loadDetail(widget.driveId);
    MapMarkerIcons.car().then((icon) {
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
    final detail = _detail;
    final title = detail == null
        ? 'Sürüş kaydı'
        : driveDisplayName(_effectiveName, detail.summary.startedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.night,
        foregroundColor: AppColors.white,
        actions: [
          if (detail != null && detail.points.length >= 2)
            IconButton(
              tooltip: 'Videoyu indir',
              icon: const Icon(Icons.download_rounded),
              onPressed: _exporting ? null : () => _downloadVideo(detail),
            ),
          if (detail != null)
            IconButton(
              tooltip: 'Yeniden adlandır',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _rename,
            ),
        ],
      ),
      body: FutureBuilder<DriveDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _error(snapshot.error);
          }
          final detail = _detail ??= snapshot.data!;
          if (detail.points.length < 2) {
            return _tooShort(detail);
          }
          final replay = _controllerFor(detail);
          return _content(detail, replay);
        },
      ),
    );
  }

  Widget _content(DriveDetail detail, DriveReplayController replay) {
    final route = replay.routePoints;
    return Column(
      children: [
        _SummaryBar(summary: detail.summary),
        Expanded(
          child: ListenableBuilder(
            listenable: replay,
            builder: (context, _) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: replay.start ?? const LatLng(40.1885, 29.0610),
                  zoom: 13,
                ),
                style: googleMapsDarkStyleJson,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (c) {
                  _mapController = c;
                  _fitToRoute(route);
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('drive_route'),
                    points: route,
                    width: 6,
                    color: AppColors.red.withValues(alpha: 0.9),
                    jointType: JointType.round,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                  ),
                },
                markers: _markers(replay),
              );
            },
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
        _SummaryBar(summary: detail.summary),
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
  const _SummaryBar({required this.summary});

  final DriveSummary summary;

  @override
  Widget build(BuildContext context) {
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
              _Stat(
                label: 'Mesafe',
                value: formatDistance(summary.lengthM),
              ),
              _Stat(
                label: 'Süre',
                value: formatDuration(summary.duration),
              ),
              _Stat(
                label: 'Nokta',
                value: '${summary.pointCount}',
              ),
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
          color: AppColors.night,
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
                    child: Text(
                      '${speedKmh(replay.carSpeedMps)} km/s',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
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

class _ExportProgressDialog extends StatelessWidget {
  const _ExportProgressDialog({required this.progress});

  final ValueNotifier<double> progress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Video hazırlanıyor...',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              children: [
                LinearProgressIndicator(
                  value: value == 0 ? null : value,
                  color: AppColors.red,
                  backgroundColor: AppColors.outline,
                ),
                const SizedBox(height: 10),
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(color: AppColors.whiteMuted),
                ),
              ],
            ),
          ),
        ],
      ),
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

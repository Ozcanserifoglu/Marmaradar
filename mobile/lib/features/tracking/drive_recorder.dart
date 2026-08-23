import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/api/google_geocoding_client.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:uuid/uuid.dart';

enum DriveUploadStatus {
  idle,
  recording,
  uploading,
  uploaded,
  failed,
  tooShort,
  needsAuth,
}

class DriveRecorder {
  DriveRecorder({
    required AppDatabase db,
    required RadarApiClient api,
    GoogleGeocodingClient? geocoding,
  })  : _db = db,
        _api = api,
        _geocoding = geocoding ?? GoogleGeocodingClient();

  static const sampleDistanceM = 20.0;
  static const sampleInterval = Duration(seconds: 5);

  final AppDatabase _db;
  final RadarApiClient _api;
  final GoogleGeocodingClient _geocoding;
  final _uuid = const Uuid();

  String? _activeDriveId;
  String? _pendingUploadDriveId;
  DriverSnapshot? _lastStored;
  int _sequence = 0;
  DriveUploadStatus _uploadStatus = DriveUploadStatus.idle;
  String? _lastError;

  String? get activeDriveId => _activeDriveId;
  String? get pendingUploadDriveId => _pendingUploadDriveId;
  DriveUploadStatus get uploadStatus => _uploadStatus;
  String? get lastError => _lastError;
  bool get isRecording => _activeDriveId != null;
  bool get hasPendingUpload => _pendingUploadDriveId != null;

  double get tripDistanceM => _tripDistanceM;
  double? get tripMinSpeedMps => _tripMinMps;
  double? get tripMaxSpeedMps => _tripMaxMps;
  DateTime? get tripStartedAt => _tripStartedAt;

  double _tripDistanceM = 0;
  double? _tripMinMps;
  double? _tripMaxMps;
  DateTime? _tripStartedAt;

  Future<void> begin() async {
    if (_activeDriveId != null) return;

    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.insertDrive(
      LocalDrivesCompanion.insert(
        id: id,
        startedAt: now,
        status: 'recording',
      ),
    );
    _activeDriveId = id;
    _lastStored = null;
    _sequence = 0;
    _uploadStatus = DriveUploadStatus.recording;
    _lastError = null;
    _tripDistanceM = 0;
    _tripMinMps = null;
    _tripMaxMps = null;
    _tripStartedAt = now;
  }

  Future<void> maybeAppend(DriverSnapshot snap) async {
    final driveId = _activeDriveId;
    if (driveId == null) return;

    final last = _lastStored;
    if (last != null) {
      final dist = haversineM(last.lat, last.lon, snap.lat, snap.lon);
      final elapsed = snap.recordedAt.difference(last.recordedAt);
      if (dist < sampleDistanceM && elapsed < sampleInterval) {
        return;
      }
      _tripDistanceM += dist;
    }
    final speed = snap.speedMps;
    if (speed >= 1 && speed <= 70) {
      _tripMinMps = _tripMinMps == null ? speed : math.min(_tripMinMps!, speed);
      _tripMaxMps = _tripMaxMps == null ? speed : math.max(_tripMaxMps!, speed);
    }

    await _db.insertDrivePoint(
      LocalDrivePointsCompanion.insert(
        driveId: driveId,
        lat: snap.lat,
        lon: snap.lon,
        speedMps: snap.speedMps,
        recordedAt: snap.recordedAt.toUtc(),
        sequence: _sequence,
      ),
    );
    _sequence += 1;
    _lastStored = snap;
  }

  Future<DriveUploadStatus> finish({bool upload = true}) async {
    final driveId = _activeDriveId;
    if (driveId == null) {
      _uploadStatus = DriveUploadStatus.idle;
      return _uploadStatus;
    }

    final endedAt = DateTime.now().toUtc();
    await _db.updateDrive(
      LocalDrivesCompanion(
        id: Value(driveId),
        endedAt: Value(endedAt),
        status: const Value('pending_upload'),
      ),
    );

    final points = await _db.pointsForDrive(driveId);
    _activeDriveId = null;
    _lastStored = null;
    _sequence = 0;

    if (points.length < 2) {
      await _db.deleteDriveCascade(driveId);
      _pendingUploadDriveId = null;
      _uploadStatus = DriveUploadStatus.tooShort;
      return _uploadStatus;
    }

    if (!upload) {
      _pendingUploadDriveId = driveId;
      _uploadStatus = DriveUploadStatus.needsAuth;
      _lastError = null;
      return _uploadStatus;
    }

    return _uploadDrive(driveId, endedAt, points);
  }

  Future<DriveUploadStatus> uploadPending() async {
    final driveId = _pendingUploadDriveId;
    if (driveId == null) {
      _uploadStatus = DriveUploadStatus.idle;
      return _uploadStatus;
    }

    final drive = await (_db.select(_db.localDrives)
          ..where((d) => d.id.equals(driveId)))
        .getSingleOrNull();
    if (drive == null) {
      _pendingUploadDriveId = null;
      _uploadStatus = DriveUploadStatus.idle;
      return _uploadStatus;
    }

    final endedAt = drive.endedAt ?? DateTime.now().toUtc();
    final points = await _db.pointsForDrive(driveId);
    if (points.length < 2) {
      await _db.deleteDriveCascade(driveId);
      _pendingUploadDriveId = null;
      _uploadStatus = DriveUploadStatus.tooShort;
      return _uploadStatus;
    }

    return _uploadDrive(driveId, endedAt, points);
  }

  Future<DriveUploadStatus> _uploadDrive(
    String driveId,
    DateTime endedAt,
    List<LocalDrivePoint> points,
  ) async {
    final drive = await (_db.select(_db.localDrives)
          ..where((d) => d.id.equals(driveId)))
        .getSingle();

    _uploadStatus = DriveUploadStatus.uploading;
    try {
      final first = points.first;
      final name = await _geocoding.reverseGeocodeDriveTitle(
        lat: first.lat,
        lon: first.lon,
      );

      final result = await _api.uploadDrive(
        startedAt: drive.startedAt,
        endedAt: endedAt,
        name: name,
        points: points
            .map(
              (p) => DrivePointPayload(
                lat: p.lat,
                lon: p.lon,
                speedMps: p.speedMps,
                recordedAt: p.recordedAt,
              ),
            )
            .toList(),
      );
      await _db.updateDrive(
        LocalDrivesCompanion(
          id: Value(driveId),
          status: const Value('uploaded'),
          remoteId: Value(result.id),
        ),
      );
      await _db.deleteDriveCascade(driveId);
      _pendingUploadDriveId = null;
      _uploadStatus = DriveUploadStatus.uploaded;
      _lastError = null;
    } on ApiException catch (e) {
      _pendingUploadDriveId = driveId;
      _uploadStatus = DriveUploadStatus.failed;
      _lastError = e.message;
    } catch (e) {
      _pendingUploadDriveId = driveId;
      _uploadStatus = DriveUploadStatus.failed;
      _lastError = e.toString();
    }
    return _uploadStatus;
  }
}

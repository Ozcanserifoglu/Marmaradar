import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/core/audio/voice_phrases.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/features/alerts/live_report_alert_engine.dart';
import 'package:radar_alert/features/reports/live_report_models.dart';

void main() {
  group('VoicePhrases.bucketDistance', () {
    test('ceils to standard buckets', () {
      expect(VoicePhrases.bucketDistance(0), 100);
      expect(VoicePhrases.bucketDistance(80), 100);
      expect(VoicePhrases.bucketDistance(101), 200);
      expect(VoicePhrases.bucketDistance(437), 500);
      expect(VoicePhrases.bucketDistance(750), 1000);
      expect(VoicePhrases.bucketDistance(1200), 1000);
    });
  });

  group('VoicePhrases.cameraPhraseKey', () {
    test('maps camera types and crowd ids', () {
      expect(
        VoicePhrases.cameraPhraseKey('fixed', isCrowd: false),
        'camera.fixed',
      );
      expect(
        VoicePhrases.cameraPhraseKey('mobile', isCrowd: false),
        'camera.mobile',
      );
      expect(
        VoicePhrases.cameraPhraseKey('fixed', isCrowd: true),
        'camera.mobile',
      );
      expect(
        VoicePhrases.cameraPhraseKey('other', isCrowd: false),
        'camera.unknown',
      );
    });
  });

  group('LiveReportAlertEngine', () {
    test('fires once for confirmed ahead report within TTA', () {
      final engine = LiveReportAlertEngine();
      final report = LiveReport(
        id: 'r1',
        lat: 40.2,
        lng: 29.1,
        type: LiveReportType.police,
        createdAt: DateTime.now(),
        verificationState: 'confirmed',
      );
      // ~278 m north of report at ~20 m/s → TTA ~14s
      final snap = DriverSnapshot(
        lat: 40.1975,
        lon: 29.1,
        speedMps: 20,
        headingDeg: 0,
        recordedAt: DateTime.now(),
      );

      var fires = 0;
      engine.onLocation(snap, [report], (_, _, _) => fires++);
      engine.onLocation(snap, [report], (_, _, _) => fires++);
      expect(fires, 1);
    });

    test('ignores pending and optimistic reports', () {
      final engine = LiveReportAlertEngine();
      final pending = LiveReport(
        id: 'p1',
        lat: 40.2,
        lng: 29.1,
        type: LiveReportType.accident,
        createdAt: DateTime.now(),
        verificationState: 'pending',
      );
      final optimistic = LiveReport(
        id: 'o1',
        lat: 40.2,
        lng: 29.1,
        type: LiveReportType.police,
        createdAt: DateTime.now(),
        verificationState: 'confirmed',
        isOptimistic: true,
      );
      final snap = DriverSnapshot(
        lat: 40.1975,
        lon: 29.1,
        speedMps: 20,
        headingDeg: 0,
        recordedAt: DateTime.now(),
      );

      var fires = 0;
      engine.onLocation(snap, [pending, optimistic], (_, _, _) => fires++);
      expect(fires, 0);
    });
  });
}

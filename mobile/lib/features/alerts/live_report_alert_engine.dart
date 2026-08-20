import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/features/alerts/alert_engine.dart';
import 'package:radar_alert/features/reports/live_report_models.dart';

/// Proximity / TTA alerts for confirmed community live reports.
class LiveReportAlertEngine {
  final Set<String> _alertedIds = {};

  static const alertRadiusM = 1000.0;
  static const leaveRadiusFactor = 1.2;
  static const aheadToleranceDeg = 75;
  static const ttaThresholdSec = AlertEngine.ttaThresholdSec;
  static const minSpeedMps = AlertEngine.minSpeedMps;

  void onLocation(
    DriverSnapshot snap,
    List<LiveReport> reports,
    void Function(LiveReport report, double distanceM, double ttaSec) fire,
  ) {
    for (final report in reports) {
      if (report.isOptimistic) continue;
      if (!report.isConfirmed) continue;

      final dist = haversineM(snap.lat, snap.lon, report.lat, report.lng);
      if (dist > alertRadiusM) {
        if (dist > alertRadiusM * leaveRadiusFactor) {
          _alertedIds.remove(report.id);
        }
        continue;
      }

      if (!isAhead(
        snap.headingDeg,
        snap.lat,
        snap.lon,
        report.lat,
        report.lng,
        null,
        aheadToleranceDeg,
      )) {
        continue;
      }

      final speed = snap.speedMps < minSpeedMps ? minSpeedMps : snap.speedMps;
      final tta = dist / speed;
      if (tta <= ttaThresholdSec && !_alertedIds.contains(report.id)) {
        _alertedIds.add(report.id);
        fire(report, dist, tta);
      }
    }
  }

  void reset() => _alertedIds.clear();
}

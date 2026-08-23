/// Phrase keys and distance buckets shared with the backend TTS catalog.
class VoicePhrases {
  VoicePhrases._();

  static const distanceBuckets = [100, 200, 300, 500, 1000];

  static const cameraFixed = 'camera.fixed';
  static const cameraMobile = 'camera.mobile';
  static const cameraRedLight = 'camera.red_light';
  static const cameraUnknown = 'camera.unknown';
  static const reportPolice = 'report.police';
  static const reportAccident = 'report.accident';
  static const corridorWarn = 'corridor.warn';
  static const corridorOver = 'corridor.over';

  /// Ceil to the next standard spoken distance bucket.
  static int bucketDistance(double distanceM) {
    if (distanceM <= 0) return distanceBuckets.first;
    for (final b in distanceBuckets) {
      if (distanceM <= b) return b;
    }
    return distanceBuckets.last;
  }

  static String cameraPhraseKey(String cameraType, {required bool isCrowd}) {
    if (isCrowd) return cameraMobile;
    switch (cameraType) {
      case 'fixed':
        return cameraFixed;
      case 'mobile':
        return cameraMobile;
      case 'red_light':
        return cameraRedLight;
      default:
        return cameraUnknown;
    }
  }

  static String reportPhraseKey(String reportType) {
    switch (reportType) {
      case 'accident':
        return reportAccident;
      case 'police':
      default:
        return reportPolice;
    }
  }

  static String spokenText(String phraseKey, Map<String, dynamic> params) {
    final dist = params['distance_m'];
    final meters = dist is num ? dist.round() : dist;
    switch (phraseKey) {
      case cameraFixed:
        return 'Dikkat, sabit hız kamerası, $meters metre ileride.';
      case cameraMobile:
        return 'Dikkat, mobil radar, $meters metre ileride.';
      case cameraRedLight:
        return 'Dikkat, kırmızı ışık kamerası, $meters metre ileride.';
      case cameraUnknown:
        return 'Dikkat, hız kamerası, $meters metre ileride.';
      case reportPolice:
        return 'Dikkat, polis kontrolü, $meters metre ileride.';
      case reportAccident:
        return 'Dikkat, kaza, $meters metre ileride.';
      case corridorWarn:
        return 'Hız limitine yaklaşıyorsunuz.';
      case corridorOver:
        return 'Hız limiti aşıldı.';
      default:
        return 'Dikkat, hız kamerası uyarısı.';
    }
  }

  static String localCacheKey(String phraseKey, Map<String, dynamic> params) {
    final dist = params['distance_m'];
    if (dist != null) return '$phraseKey:$dist';
    return phraseKey;
  }
}

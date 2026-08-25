import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/features/drives/drive_video_exporter.dart';

void main() {
  test('brand mark sits below HUD and above Stories/Reels chrome', () {
    final canvas = DriveVideoExporter.size.toDouble();
    final brandTop = canvas * DriveVideoExporter.brandTopFraction;
    expect(brandTop, greaterThan(DriveVideoExporter.hudBottomY + 40));

    const storiesChrome = 0.14;
    const estimatedMarkHeight = 46.0;
    final brandBottom = brandTop + estimatedMarkHeight;
    expect(brandBottom, lessThan(canvas * (1 - storiesChrome) + 8));
  });
}

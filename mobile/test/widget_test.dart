import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';

void main() {
  testWidgets('Radar Alert app renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RadarAlertApp()),
    );
    expect(find.text('Radar Alert'), findsOneWidget);
    expect(find.text('Takibi Başlat'), findsOneWidget);
  });
}

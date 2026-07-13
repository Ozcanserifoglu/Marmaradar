import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/app.dart';

void main() {
  testWidgets('Radar Alert app renders', (tester) async {
    await tester.pumpWidget(const RadarAlertApp());
    await tester.pump();

    expect(find.text('Sürüşe Başla'), findsOneWidget);
    expect(find.text('km/s'), findsOneWidget);
    expect(find.text('Otomatik'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/app.dart';

void main() {
  testWidgets('Marmaradar app renders', (tester) async {
    await tester.pumpWidget(const MarmaradarApp());
    await tester.pump();

    expect(find.text('Sürüşe Başla'), findsOneWidget);
    expect(find.text('km/s'), findsOneWidget);
    expect(find.text('Otomatik'), findsOneWidget);
  });
}

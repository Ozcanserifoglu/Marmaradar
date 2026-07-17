import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/app.dart';

void main() {
  testWidgets('Auth gate renders login', (tester) async {
    await tester.pumpWidget(const MarmaradarRoot());
    await tester.pump();
    // Bootstrap may complete async; allow a frame for auth gate.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MARMARADAR'), findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);
  });
}

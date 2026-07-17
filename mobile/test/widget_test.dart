import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/auth/auth_controller.dart';

void main() {
  testWidgets('Auth gate renders login', (tester) async {
    // Avoid flutter_secure_storage (hangs on CI Linux without plugins).
    final store = MemoryTokenStore();
    final api = RadarApiClient(tokenStore: store);
    final auth = AuthController(tokenStore: store, apiClient: api);
    await auth.bootstrap();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
        ],
        child: const MarmaradarApp(),
      ),
    );
    await tester.pump();

    expect(find.text('MARMARADAR'), findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);
  });
}

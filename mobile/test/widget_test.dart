import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/auth/auth_controller.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';

void main() {
  testWidgets('Guest boot skips full-screen auth gate', (tester) async {
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

    // Guest-first: auth copy must not be the root home screen.
    expect(
      find.text('Sürüş kayıtlarını kaydetmek için hesabınıza giriş yapın.'),
      findsNothing,
    );
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('Auth modal shows login form', (tester) async {
    final store = MemoryTokenStore();
    final api = RadarApiClient(tokenStore: store);
    final auth = AuthController(tokenStore: store, apiClient: api);
    await auth.bootstrap();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
        ],
        child: const MaterialApp(
          home: AuthScreen(asModal: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MARMARADAR'), findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}

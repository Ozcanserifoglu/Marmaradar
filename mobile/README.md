# Marmaradar (mobile)

Flutter client for Marmaradar — EDS and corridor warnings for drivers in Turkey.

Package IDs: Android `com.radaralert.radar_alert`, iOS `com.radaralert.radarAlert`.

Public legal copy: [Gizlilik](https://www.marmaradar.com/gizlilik), [Kullanım Şartları](https://www.marmaradar.com/kullanim-sartlari).

## Google Maps API key

The tracking map uses the Google Maps SDK. Destination search and routing also call **Places** (Autocomplete + Details) and **Directions** over REST with the **same** key.

Enable:

1. **Maps SDK for Android**
2. **Maps SDK for iOS**
3. **Places API** (Autocomplete + Place Details)
4. **Directions API**

Restrict by Android package `com.radaralert.radar_alert` / iOS bundle `com.radaralert.radarAlert` (and SHA-1 for Android).

### Android

`android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_key_here
```

Injected into the Maps SDK manifest and Dart at startup — no extra `--dart-define` for a normal `flutter run`.

### iOS

Copy `ios/Flutter/MapsSecrets.xcconfig.example` to `ios/Flutter/MapsSecrets.xcconfig`:

```
MAPS_API_KEY=your_key_here
```

### Optional override

```bash
flutter run --dart-define=MAPS_API_KEY=your_key_here
```

Without a key, map tiles and destination search fail.

## API URL

- **Release** builds always use `_productionBaseUrl` in `lib/data/api/radar_api_client.dart`.
- **Debug/profile** default:
  - Android emulator: `http://10.0.2.2:8081`
  - iOS simulator / desktop: `http://127.0.0.1:8081`

Override:

```bash
flutter run --dart-define=RADAR_API_URL=http://10.0.2.2:8081
```

For repeat use, copy `dart_defines.json.example` → `dart_defines.json` (gitignored) and pass `--dart-define-from-file=dart_defines.json`.

From the repo root, copy `scripts/run-local-mobile.sh.example` to `scripts/run-local-mobile.sh` (gitignored) to start Docker + Flutter.

## Google Sign-In (OAuth Web client ID)

Web OAuth client ID (`GOOGLE_SERVER_CLIENT_ID`) lives in committed [`dart_defines.oauth.json`](dart_defines.oauth.json). Local run and release scripts inject it:

```bash
# from repo root
./scripts/run-local-mobile.sh
./scripts/build-release-mobile.sh appbundle
./scripts/build-release-mobile.sh apk
```

Plain Flutter:

```bash
flutter run --dart-define-from-file=dart_defines.oauth.json
flutter build apk --dart-define-from-file=dart_defines.oauth.json
```

iOS also needs `GOOGLE_IOS_CLIENT_ID` and `ios/Flutter/GoogleSignInSecrets.xcconfig` (from the `.example` file).

Site beta: copy the APK to `web/public/downloads/marmaradar-beta.apk`.

## Background location

See [docs/BACKGROUND_LOCATION.md](docs/BACKGROUND_LOCATION.md).

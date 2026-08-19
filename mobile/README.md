# Marmaradar (mobile)

Flutter client for Marmaradar — speed camera and corridor warnings for Marmara region drivers.

## Google Maps API key

The tracking map uses the Google Maps SDK. Destination search and routing also call **Places** (Autocomplete + Details) and **Directions** over REST, using the **same** key.

Create a key in Google Cloud with these APIs enabled:

1. **Maps SDK for Android**
2. **Maps SDK for iOS**
3. **Places API** (classic Autocomplete + Place Details)
4. **Directions API**

Restrict the key by Android package (`com.radaralert.radar_alert`) / iOS bundle id (and SHA-1 for Android).

### Android

Add to `android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_key_here
```

That value is injected into the Maps SDK manifest entry and exposed to Dart at startup — no extra `--dart-define` is required for a normal `flutter run`.

### iOS

Copy `ios/Flutter/MapsSecrets.xcconfig.example` to `ios/Flutter/MapsSecrets.xcconfig` and set:

```
MAPS_API_KEY=your_key_here
```

Same key is used for the Maps SDK and Places/Directions REST.

### Optional override

For CI or one-off runs you can still pass:

```bash
flutter run --dart-define=MAPS_API_KEY=your_key_here
```

Without a key the map will not render tiles, and destination search will report that the API key is missing.

## API URL

API base URL selection is environment-aware:

- Release builds always use production gateway (`_productionBaseUrl` in `lib/data/api/radar_api_client.dart`).
- Debug/profile builds default to local API:
  - Android emulator: `http://10.0.2.2:8081`
  - iOS simulator / desktop: `http://127.0.0.1:8081`

For debug/profile one-off runs you can still override it (for example, to test staging or a LAN host):

```bash
flutter run --dart-define=RADAR_API_URL=http://10.0.2.2:8081
```

`10.0.2.2` is how the Android emulator reaches your machine's `localhost`. For repeat use, copy `dart_defines.json.example` to `dart_defines.json` (gitignored) and pass `--dart-define-from-file=dart_defines.json`.

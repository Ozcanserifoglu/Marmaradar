# radar_alert

Flutter client for Radar Alert — speed camera and corridor warnings for Marmara region drivers.

## Google Maps API key

The tracking map uses the Google Maps SDK. Destination search and routing also call **Places** (Autocomplete + Details) and **Directions** from Dart over REST.

Create a key in Google Cloud with these APIs enabled:

1. **Maps SDK for Android**
2. **Maps SDK for iOS**
3. **Places API** (classic Autocomplete + Place Details)
4. **Directions API**

Restrict the key by Android package (`com.radaralert.radar_alert`) / iOS bundle id (and SHA-1 for Android).

### Native Maps SDK

**Android** — add to `android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_key_here
```

**iOS** — copy `ios/Flutter/MapsSecrets.xcconfig.example` to `ios/Flutter/MapsSecrets.xcconfig` and set:

```
MAPS_API_KEY=your_key_here
```

Without a key the map will not render tiles.

### Places + Directions (Dart)

Pass the same (or a sibling) key at run/build time so REST clients can call Google:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
```

Without `GOOGLE_MAPS_API_KEY`, the destination search bar will report that the API key is missing / denied.

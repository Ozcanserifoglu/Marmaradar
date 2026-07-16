# radar_alert

Flutter client for Radar Alert — speed camera and corridor warnings for Marmara region drivers.

## Google Maps API key

The tracking map uses the Google Maps SDK. Create a key in Google Cloud with **Maps SDK for Android** and **Maps SDK for iOS** enabled, then restrict it by package (`com.radaralert.radar_alert`) / iOS bundle id.

**Android** — add to `android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_key_here
```

**iOS** — copy `ios/Flutter/MapsSecrets.xcconfig.example` to `ios/Flutter/MapsSecrets.xcconfig` and set:

```
MAPS_API_KEY=your_key_here
```

Without a key the map will not render tiles.

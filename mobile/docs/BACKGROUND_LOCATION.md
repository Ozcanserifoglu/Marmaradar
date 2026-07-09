# Background Location — Testing & Hardening

## Current implementation

- **Package:** `geolocator` with `ForegroundNotificationConfig` on Android
- **iOS:** `AppleSettings` with `ActivityType.automotiveNavigation` and `UIBackgroundModes: location`
- **Alerts:** `flutter_local_notifications` for audio/visual warnings when screen is off

## Recommended soak test (2+ hours)

1. Install debug build on a physical Android device (Samsung/Xiaomi/Redmi preferred — aggressive battery killers).
2. Grant **Always** location + notification permissions.
3. Disable battery optimization for Radar Alert (Settings → Apps → Radar Alert → Battery → Unrestricted).
4. Start tracking, open Google Maps navigation, turn screen off.
5. Drive or simulate route through known Bursa EDS points.
6. Log every 15 minutes: is foreground notification visible? Are GPS updates arriving?

### Pass criteria

- Foreground notification remains for full test duration
- Camera alerts fire within 45s TTA at known points
- Corridor session starts at entry gate and ends at exit gate

## If geolocator is unreliable

Evaluate migrating to **tracelet** (open-source, production-grade background geolocation):

- Polygon geofences for corridor gates
- Headless Dart execution when app is killed
- SQLite persistence + HTTP sync built-in

Migration path:

1. Replace `BackgroundLocationService` with `Tracelet.onLocation` stream
2. Register corridor gates as polygon/circle geofences
3. Keep `AlertEngine` / `CorridorTracker` logic unchanged

## Android checklist

- [x] `ACCESS_FINE_LOCATION`
- [x] `ACCESS_BACKGROUND_LOCATION`
- [x] `FOREGROUND_SERVICE_LOCATION`
- [x] `POST_NOTIFICATIONS`
- [x] `WAKE_LOCK`
- [ ] Request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in settings flow (future)

## iOS checklist

- [x] `NSLocationWhenInUseUsageDescription`
- [x] `NSLocationAlwaysAndWhenInUseUsageDescription`
- [x] `UIBackgroundModes: location`
- [ ] App Store review notes explaining navigation-adjacent safety use case

## Tracelet evaluation summary

**Decision:** Stay on `geolocator` for MVP. Tracelet is documented as the upgrade path if soak tests fail on target OEM devices. No tracelet dependency added yet to keep the initial scaffold simple and license-free.

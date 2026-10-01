# Location (foreground only)

Display name **Marmaradar**. Implementation: `mobile/lib/core/location/background_location_service.dart`.

Background / always-on location was removed to avoid Google Play policy complications. The app requests and uses location **only while in use** (foreground).

## Current implementation

- **Package:** `geolocator` with foreground `AndroidSettings` / `AppleSettings`
- **iOS:** `allowBackgroundLocationUpdates: false`; no `UIBackgroundModes: location`
- **Permissions:** while-in-use only (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`, `NSLocationWhenInUseUsageDescription`)

## Android checklist

- [x] `ACCESS_FINE_LOCATION`
- [x] `ACCESS_COARSE_LOCATION`
- [x] `POST_NOTIFICATIONS`
- [x] `WAKE_LOCK` (screen wakelock during an active drive — not for background GPS)
- [x] No `ACCESS_BACKGROUND_LOCATION`
- [x] No `FOREGROUND_SERVICE_LOCATION`

## iOS checklist

- [x] `NSLocationWhenInUseUsageDescription`
- [x] No `NSLocationAlwaysAndWhenInUseUsageDescription`
- [x] No `UIBackgroundModes: location` (`audio` may remain for voice alerts)

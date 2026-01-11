# Strava Like Flutter Tracker

This is a minimal Flutter app that tracks a ride/run and draws a polyline on an OpenStreetMap-based map. It uses background location tracking so the route keeps updating when the screen is off.

## What works
- Live polyline drawing on a map.
- Background tracking via a foreground service (Android).
- High-accuracy GPS settings for directionally accurate tracks.

## Setup
1) Install Flutter SDK and run `flutter doctor`.
2) From this project root, run:

```bash
flutter pub get
flutter run
```

## Android notes
- Background tracking requires location permissions and a foreground service notification.
- If the build complains about the background service class name, check the `background_locator_2` Android manifest and update the service name in `android/app/src/main/AndroidManifest.xml`.
- For Android 10+, the user must grant "Allow all the time" location permission.

## iOS notes
- iOS requires `NSLocationAlwaysAndWhenInUseUsageDescription` in `Info.plist` and the Background Modes capability (Location updates). This project only includes Android config scaffolding.
# Running-tracker
# Running-tracker

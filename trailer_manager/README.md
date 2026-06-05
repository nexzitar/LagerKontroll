# Trailer Manager — Flutter App

The Flutter client for Trailer Manager. It logs depot trailers from a single camera
capture: on-device license-plate OCR, GPS capture, and terminal geofencing, with an
interactive map, status/history tracking, role-based access, and Shorebird OTA updates.

For the full project overview (app + backend) see the [repository README](../README.md).

## Architecture

Clean Architecture with a feature-first layout. Each feature is split into `data`,
`domain`, and `presentation`:

```
lib/
├── core/        # config, network (Dio + JWT), services, theme, utils
├── features/    # auth, browse, capture, detail, map, module_tracking, settings
└── shared/      # shared models and utilities
```

- **State:** `flutter_riverpod` (providers / `StateNotifier`)
- **Networking:** `dio` with JWT auth, a token-expiry interceptor, and retry logic
- **Storage:** `hive` + `shared_preferences`
- **OCR:** `google_mlkit_text_recognition` (on-device, in `core/services/license_plate_service.dart`)
- **Geofencing:** ray-casting point-in-polygon in `core/services/terminal_geofence_service.dart`
- **Maps & location:** `google_maps_flutter`, `geolocator`, `geocoding`
- **Errors:** `dartz` `Either`-based failures

## Setup

```bash
flutter pub get

# Google Maps key (git-ignored; templates are committed)
cp .env.example .env                                  # Android reads MAPS_API_KEY at build time
cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig   # iOS reads it at build time

flutter run
```

The API base URL is set in `lib/core/config/environment.dart` (`EnvironmentConfig.current`).
See [`GOOGLE_MAPS_SETUP.md`](GOOGLE_MAPS_SETUP.md) for obtaining/restricting the Maps key and
[`CLAUDE.md`](CLAUDE.md) for an in-depth architecture and API reference.

## Common commands

```bash
flutter analyze
flutter test
flutter build apk --release      # or: flutter build appbundle --release
```

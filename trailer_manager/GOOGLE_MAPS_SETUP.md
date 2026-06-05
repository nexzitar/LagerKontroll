# Google Maps API Key Setup

The map view and Google Maps SDK require an API key. The key is **not** committed to the
repository — it's provided locally through git-ignored files (`*.example` templates are
committed):

- **Android** reads `MAPS_API_KEY` from `trailer_manager/.env` at build time (via Gradle)
  and injects it into `AndroidManifest.xml` as `${MAPS_API_KEY}`.
- **iOS** reads `MAPS_API_KEY` from `trailer_manager/ios/Flutter/Secrets.xcconfig`, which
  feeds `Info.plist` (`GMSApiKey`); `AppDelegate.swift` passes it to `GMSServices`.

## 1. Get a Google Maps API key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a project (or select an existing one).
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
4. Go to **Credentials → Create Credentials → API Key** and copy the key.
5. Restrict the key (recommended):
   - **Android apps**: package name `com.lagerkontroll.trailer_manager` + your signing
     SHA-1. Get the debug SHA-1 with:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - **iOS apps**: your bundle identifier.
   - **API restrictions**: limit to the Maps SDKs.

## 2. Add the key to the project

From `trailer_manager/`:

```bash
# Android (and the canonical source of the key)
cp .env.example .env
# edit .env and set: MAPS_API_KEY=your_actual_key

# iOS
cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig
# edit Secrets.xcconfig and set: MAPS_API_KEY = your_actual_key
```

Then rebuild:

```bash
flutter clean
flutter run
```

Both `.env` and `Secrets.xcconfig` are listed in `.gitignore`, so the real key stays local.
For CI, the Android build also falls back to a `MAPS_API_KEY` environment variable if `.env`
is absent.

## Troubleshooting

**"API key not found" / gray map**
- Confirm `MAPS_API_KEY` is set in `trailer_manager/.env` (Android) and
  `ios/Flutter/Secrets.xcconfig` (iOS), with no surrounding quotes or spaces.
- Make sure the relevant Maps SDK is enabled in Google Cloud Console.
- Run `flutter clean` then rebuild so the new value is picked up.

**"This API project is not authorized to use this API"**
- The corresponding Maps SDK (Android/iOS) is not enabled for the project.

**Permission errors**
- Location/camera permissions are declared in the manifest / `Info.plist`; grant them when
  prompted on device.

## Cost

Google Maps includes a monthly free tier that this low-traffic app is expected to stay
within. Create separate, restricted keys for development and production.

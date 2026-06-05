# Trailer Manager (LagerKontroll)

A mobile app and backend for keeping a live database of the trailers in a logistics
depot. A trailer is logged with a single camera capture: the app reads the license plate
from the photo with on-device OCR, records the GPS position, and uses geofencing to detect
which terminal the trailer is standing in. It replaces a paper-based logging process that
was always out of date.

This repository is a monorepo:

- **`trailer_manager/`** — the Flutter app (Android, with iOS build support).
- **`trailer_manager/backend/`** — the Node.js + Express + PostgreSQL REST API.

## The Problem

Tracking which trailers are in the depot, where they are, and what state they're in was
done on paper and whiteboards: stale the moment it was written, not searchable, with no
location data and no history of who changed what. Finding a trailer meant walking the
terminal and reading plates by eye.

## What It Does

- **One-capture entry** — take one photo and the record is created with image, license
  plate, GPS coordinates, detected terminal, and status.
- **License plate OCR** — `google_mlkit_text_recognition` reads the plate on-device and
  auto-fills the trailer number. Recognizes Norwegian, Swedish (classic `ABC 123` and new
  `ABC 12D`), and Dutch plate formats.
- **GPS + terminal geofencing** — every entry stores exact coordinates; a ray-casting
  point-in-polygon test maps the position to a terminal (`B1`–`B5`, `ØT`) automatically.
- **Interactive map** — all trailers on a Google Maps satellite view with status-colored
  markers, filterable by terminal.
- **Status & history** — statuses `Empty`, `Loaded`, and `In Ramp` (with ramp number),
  plus a timestamped, append-only history with user attribution.
- **Roles & onboarding** — `Guest` / `User` / `Admin` access, an admin panel, and
  SMS-based onboarding for new users.
- **Over-the-air updates** — Shorebird code push ships fixes without an app-store release.

## Tech Stack

### App (`trailer_manager/`)

- **Flutter / Dart**, organized with **Clean Architecture** and a feature-first layout
  (`features/auth`, `browse`, `capture`, `detail`, `map`, `module_tracking`, `settings`).
- **State management:** `flutter_riverpod` (providers / `StateNotifier`).
- **Networking:** `dio` with a JWT auth header, a token-expiry interceptor, and retry logic.
- **Local storage:** `hive` / `hive_flutter` and `shared_preferences`.
- **Camera & OCR:** `camera`, `image_picker`, `image`, `google_mlkit_text_recognition`.
- **Location & maps:** `geolocator`, `geocoding`, `google_maps_flutter`, `permission_handler`.
- **Error handling:** `dartz` (`Either`-based failures).
- **Updates:** Shorebird code push.

### Backend (`trailer_manager/backend/`)

- **Node.js + Express** REST API, versioned under `/api/v1`.
- **PostgreSQL** via `pg`, with append-only history tracking.
- **Image pipeline:** `multer` uploads + `sharp` compression/thumbnails.
- **Auth & security:** `bcrypt`, `jsonwebtoken`, `helmet`, `express-rate-limit`, `cors`.
- **Config:** `dotenv`.

## Repository Layout

```
LagerKontroll/
├── README.md
└── trailer_manager/
    ├── lib/                 # Flutter app source (Clean Architecture, feature-first)
    │   ├── core/            # config, network, services, theme, utils
    │   ├── features/        # auth, browse, capture, detail, map, module_tracking, settings
    │   └── shared/          # shared models and utilities
    ├── android/ · ios/      # native platform projects
    ├── backend/             # Node.js + Express + PostgreSQL API
    │   ├── src/             # routes, controllers, middleware, services, config
    │   └── migrations/      # SQL migrations + schema
    ├── CLAUDE.md            # in-depth developer/architecture guide
    └── GOOGLE_MAPS_SETUP.md # how to obtain and configure the Maps API key
```

## Getting Started

### Prerequisites

- Flutter SDK (Dart SDK `^3.10.1`)
- Node.js 18+ and PostgreSQL 13+ (for the backend)
- A Google Maps API key (see [`trailer_manager/GOOGLE_MAPS_SETUP.md`](trailer_manager/GOOGLE_MAPS_SETUP.md))

### 1. Backend

```bash
cd trailer_manager/backend
npm install
cp .env.example .env        # then fill in DB credentials and JWT secret
# create the database and run trailer_manager/backend/database_schema.sql + migrations/
npm run dev                 # or: npm start
```

### 2. App

```bash
cd trailer_manager
flutter pub get
cp .env.example .env        # then add your Google Maps API key (see Configuration)
flutter run
```

The app's API base URL is configured in `lib/core/config/environment.dart`
(`EnvironmentConfig.current`).

## Configuration & Secrets

No API keys or secrets are committed to the repository. They are provided locally through
`.env` files (and an iOS xcconfig), all of which are git-ignored. Each has a committed
`*.example` template.

| Secret | Where it's used | Provide it in |
|--------|-----------------|---------------|
| Google Maps API key | Android manifest + iOS `AppDelegate` | `trailer_manager/.env` (`MAPS_API_KEY`) for Android; `trailer_manager/ios/Flutter/Secrets.xcconfig` for iOS |
| DB credentials, JWT secret, etc. | Backend | `trailer_manager/backend/.env` |

**App (Maps key):**

```bash
cd trailer_manager
cp .env.example .env
# set MAPS_API_KEY=your_google_maps_api_key   (Android reads this at build time)

cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig
# set MAPS_API_KEY=your_google_maps_api_key   (iOS reads this at build time)
```

On Android, the Gradle build reads `MAPS_API_KEY` from `trailer_manager/.env` and injects it
into the manifest via a manifest placeholder. On iOS, `Secrets.xcconfig` feeds the key into
`Info.plist` (`GMSApiKey`), which `AppDelegate.swift` passes to `GMSServices`.

**Backend:** copy `trailer_manager/backend/.env.example` to `.env` and fill in the values;
the server loads them via `dotenv`.

## Building & Releasing

```bash
# Android release
cd trailer_manager
flutter build apk --release        # or: flutter build appbundle --release

# Over-the-air patch (after a Shorebird release)
shorebird patch android
```

See [`trailer_manager/CLAUDE.md`](trailer_manager/CLAUDE.md) for a deeper architecture and
API reference, and [`trailer_manager/backend/README.md`](trailer_manager/backend/README.md)
for backend setup and endpoints.

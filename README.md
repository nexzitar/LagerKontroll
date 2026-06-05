# Trailer Management App - Flutter

A professional trailer management application built with Flutter, featuring camera capture, GPS tracking, and real-time updates.

## Features

### 1. Capture View
- Camera integration for license plate and contents photos
- Manual license plate entry
- Terminal selection (B1/B3)
- GPS location capture
- Empty trailer checkbox
- Real-time image preview

### 2. Browse View
- List all trailers with pagination
- Sort by date, name, or status
- Filter by terminal, status, date range
- Search functionality
- Pull-to-refresh

### 3. Detail View
- Photo gallery viewer
- Interactive map with location
- Timestamp information
- History of last 5-10 entries
- Mark trailer as empty
- Update location

### 4. Settings View
- Configurable history count
- Cache settings
- Location accuracy settings
- Image quality settings
- Theme preferences

### 5. Over-the-Air Updates
- Shorebird integration for instant updates
- No app store submission required for small fixes
- Automatic background updates

## Architecture

This project follows **Clean Architecture** principles with a **feature-first** folder structure.

### Key Principles
- **Separation of Concerns**: Clear boundaries between layers
- **Testability**: Easy to unit test business logic
- **Maintainability**: Scalable and organized code structure
- **Type Safety**: Compile-time error checking with Riverpod
- **No Magic Numbers**: All configuration centralized

### Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│   (UI, Widgets, State Management)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Application Layer               │
│   (Use Cases, Business Logic)           │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Domain Layer                    │
│   (Entities, Repository Interfaces)     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Data Layer                      │
│   (Repository Impl, API, Local Storage) │
└─────────────────────────────────────────┘
```

## Technology Stack

### State Management
- **Riverpod 2.x** with code generation
  - Compile-time safety
  - No BuildContext required
  - Excellent testability

### Navigation
- **go_router** for declarative routing
- Deep linking support
- Type-safe navigation

### Networking
- **Dio** for HTTP requests
- **Retrofit** for type-safe API clients
- Interceptors for auth and logging

### Local Storage
- **Hive** for fast NoSQL storage
- **SharedPreferences** for simple settings

### Camera & Images
- **camera** package for camera access
- **image_picker** for gallery selection
- **image** for manipulation

### Location & Maps
- **geolocator** for GPS tracking
- **google_maps_flutter** for maps
- **geocoding** for address conversion

### Error Handling
- **dartz** for functional error handling
- Either type for explicit error handling
- Custom Failure and Exception classes

### Updates
- **Shorebird** for over-the-air updates

## Project Structure

```
lib/
├── core/                    # Shared functionality
│   ├── config/             # Configuration & constants
│   ├── theme/              # App theme
│   ├── utils/              # Utilities
│   ├── errors/             # Error handling
│   └── network/            # Network setup
│
├── features/               # Feature modules
│   ├── capture/           # Trailer capture
│   ├── browse/            # Trailer list
│   ├── detail/            # Trailer detail
│   └── settings/          # App settings
│
└── shared/                # Shared UI components
    ├── widgets/
    └── dialogs/
```

Each feature follows the same structure:
```
feature/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

## Getting Started

### Prerequisites
- Flutter SDK 3.16.0+
- Dart SDK 3.2.0+
- iOS development: Xcode 14.0+
- Android development: Android Studio or Android SDK

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd LagerKontroll
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Configure API keys**

Create `.env` file:
```
API_BASE_URL=https://api.example.com
GOOGLE_MAPS_API_KEY_ANDROID=your_android_key
GOOGLE_MAPS_API_KEY_IOS=your_ios_key
```

5. **Setup platform-specific configurations**

#### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

#### iOS: `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture trailer photos</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to track trailer locations</string>
```

6. **Run the app**
```bash
flutter run
```

### Run with environments
```bash
# Development
flutter run --dart-define=ENV=development

# Production
flutter run --dart-define=ENV=production --release
```

## Development

### Code Generation
When you modify models, providers, or add new generated code:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/unit/features/capture/domain/usecases/capture_trailer_test.dart
```

### Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Auto-fix issues
dart fix --apply
```

## Building

### Android
```bash
# APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### With Shorebird (OTA Updates)
```bash
# Install Shorebird CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Initialize
shorebird init

# Create release
shorebird release android
shorebird release ios

# Create patch (OTA update)
shorebird patch android
```

## Documentation

Detailed documentation is available in the following files:

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete architecture overview, patterns, and decisions
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Detailed folder structure and file organization
- **[IMPLEMENTATION_EXAMPLES.md](IMPLEMENTATION_EXAMPLES.md)** - Code examples for all major components
- **[QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)** - Step-by-step setup and development guide

## Key Concepts

### State Management with Riverpod

```dart
// Define provider with code generation
@riverpod
class TrailerList extends _$TrailerList {
  @override
  Future<List<Trailer>> build() async {
    return await _fetchTrailers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTrailers());
  }
}

// Use in widget
class TrailerListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailers = ref.watch(trailerListProvider);

    return trailers.when(
      data: (list) => ListView.builder(...),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorView(error: error),
    );
  }
}
```

### Error Handling

```dart
// Repository returns Either<Failure, Success>
Future<Either<Failure, Trailer>> getTrailer(String id) async {
  try {
    final trailer = await api.getTrailer(id);
    return Right(trailer);
  } on ServerException {
    return Left(ServerFailure());
  } catch (e) {
    return Left(UnexpectedFailure(e.toString()));
  }
}

// Use case handles business logic
Future<Either<Failure, Trailer>> call(String id) async {
  if (id.isEmpty) {
    return Left(ValidationFailure('ID cannot be empty'));
  }
  return await repository.getTrailer(id);
}
```

### Configuration Management

```dart
// All configuration in one place - NO MAGIC NUMBERS
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const int imageQuality = 85;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const List<String> availableTerminals = ['B1', 'B3'];
}

// Use throughout the app
final timeout = AppConfig.apiTimeout;
```

## Best Practices

1. **Follow Clean Architecture** - Keep layers separated
2. **Write Tests** - Aim for >80% coverage
3. **Use Code Generation** - Reduce boilerplate
4. **No Magic Numbers** - Use configuration
5. **Handle Errors Explicitly** - Use Either type
6. **Document Public APIs** - Use documentation comments
7. **Keep Files Small** - Under 300 lines
8. **One Class Per File** - Easy to navigate

## Contributing

1. Create a feature branch
2. Implement your feature following the architecture
3. Write tests for your changes
4. Ensure all tests pass: `flutter test`
5. Format code: `dart format lib/ test/`
6. Run analysis: `flutter analyze`
7. Submit a pull request

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat(capture): add camera functionality

- Implemented camera preview
- Added photo capture
- Integrated with provider

Closes #123
```

## Troubleshooting

### Common Issues

1. **Code generation not working**
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Permission issues**
   - Check AndroidManifest.xml and Info.plist
   - Request permissions at runtime with permission_handler

3. **Maps not showing**
   - Verify API keys are correct
   - Check platform-specific configuration
   - Enable Maps SDK in Google Cloud Console

4. **Build failures**
   ```bash
   flutter clean
   cd ios && pod deintegrate && pod install && cd ..
   flutter pub get
   ```

## Performance

- **Image optimization**: Images compressed to 85% quality, max 1920x1080
- **Lazy loading**: Lists use ListView.builder for efficient rendering
- **Caching**: Network images cached, API responses cached for 24h
- **Offline support**: Local storage with background sync

## Security

- **No hardcoded secrets**: Use environment variables
- **HTTPS only**: All API calls use HTTPS
- **Input validation**: All user inputs validated
- **Permission checks**: Runtime permission requests

## License

[Your License Here]

## Support

For questions or issues, please:
1. Check the documentation files
2. Search existing issues
3. Create a new issue with details

## Roadmap

- [ ] Offline mode with background sync
- [ ] Push notifications
- [ ] Barcode scanning for license plates
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Export functionality (PDF, CSV)
- [ ] Analytics dashboard

## Credits

Built with:
- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev)
- [Shorebird](https://shorebird.dev)

---

**Version**: 1.0.0
**Last Updated**: 2025-12-10

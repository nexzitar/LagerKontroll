# Trailer Management App - Architecture Documentation

## 1. Architecture Overview

This application follows **Clean Architecture** principles with a feature-first folder structure, ensuring separation of concerns, testability, and maintainability.

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

## 2. State Management: Riverpod

**Recommendation: Riverpod 2.x**

### Why Riverpod?

1. **Compile-time safety**: Catches errors during compilation, not at runtime
2. **No BuildContext**: Can be used anywhere in the code
3. **Testability**: Easy to mock and test
4. **Scalability**: Works well for small to large apps
5. **Modern**: Built by the creator of Provider with lessons learned
6. **Code generation**: Reduces boilerplate with riverpod_generator
7. **Better DevTools**: Excellent debugging experience

### Alternative Considerations:
- **Bloc**: Good for complex state machines, but more boilerplate
- **Provider**: Simpler but less powerful than Riverpod
- **GetX**: Fast but not recommended due to service locator pattern

## 3. Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # Root widget with router & theme
│
├── core/                              # Shared across features
│   ├── config/
│   │   ├── app_config.dart           # All configuration constants
│   │   ├── env_config.dart           # Environment-specific config
│   │   └── routes.dart               # Route definitions
│   │
│   ├── constants/
│   │   ├── api_constants.dart        # API endpoints
│   │   ├── ui_constants.dart         # UI dimensions, durations
│   │   └── asset_constants.dart      # Asset paths
│   │
│   ├── theme/
│   │   ├── app_theme.dart            # Theme definitions
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_text_styles.dart      # Text styles
│   │
│   ├── utils/
│   │   ├── logger.dart               # Logging utility
│   │   ├── validators.dart           # Input validators
│   │   └── formatters.dart           # Data formatters
│   │
│   ├── errors/
│   │   ├── failures.dart             # Failure classes
│   │   └── exceptions.dart           # Exception classes
│   │
│   └── network/
│       ├── api_client.dart           # HTTP client wrapper
│       ├── api_interceptor.dart      # Request/response interceptor
│       └── network_info.dart         # Network connectivity checker
│
├── features/                          # Feature-first organization
│   │
│   ├── capture/                      # Trailer capture feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── trailer_capture_model.dart
│   │   │   │   └── terminal_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── capture_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── capture_remote_datasource.dart
│   │   │       └── capture_local_datasource.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── trailer_capture.dart
│   │   │   │   └── terminal.dart
│   │   │   ├── repositories/
│   │   │   │   └── capture_repository.dart
│   │   │   └── usecases/
│   │   │       ├── capture_trailer.dart
│   │   │       ├── capture_location.dart
│   │   │       └── upload_images.dart
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── capture_provider.dart
│   │       │   ├── camera_provider.dart
│   │       │   └── location_provider.dart
│   │       ├── screens/
│   │       │   └── capture_screen.dart
│   │       └── widgets/
│   │           ├── camera_view.dart
│   │           ├── terminal_selector.dart
│   │           ├── license_plate_input.dart
│   │           └── location_display.dart
│   │
│   ├── browse/                       # Trailer list feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── trailer_model.dart
│   │   │   │   └── filter_options_model.dart
│   │   │   └── repositories/
│   │   │       └── browse_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── trailer.dart
│   │   │   │   ├── trailer_status.dart
│   │   │   │   └── filter_options.dart
│   │   │   ├── repositories/
│   │   │   │   └── browse_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_trailers.dart
│   │   │       ├── filter_trailers.dart
│   │   │       └── sort_trailers.dart
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── browse_provider.dart
│   │       │   ├── filter_provider.dart
│   │       │   └── sort_provider.dart
│   │       ├── screens/
│   │       │   └── browse_screen.dart
│   │       └── widgets/
│   │           ├── trailer_list_item.dart
│   │           ├── filter_bottom_sheet.dart
│   │           └── sort_menu.dart
│   │
│   ├── detail/                       # Trailer detail feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── trailer_detail_model.dart
│   │   │   │   └── history_entry_model.dart
│   │   │   └── repositories/
│   │   │       └── detail_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── trailer_detail.dart
│   │   │   │   └── history_entry.dart
│   │   │   ├── repositories/
│   │   │   │   └── detail_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_trailer_detail.dart
│   │   │       ├── mark_trailer_empty.dart
│   │   │       └── update_trailer_location.dart
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── detail_provider.dart
│   │       ├── screens/
│   │       │   └── detail_screen.dart
│   │       └── widgets/
│   │           ├── trailer_photo_viewer.dart
│   │           ├── location_map.dart
│   │           ├── history_list.dart
│   │           └── action_buttons.dart
│   │
│   └── settings/                     # Settings feature
│       ├── data/
│       │   ├── models/
│       │   │   └── settings_model.dart
│       │   └── repositories/
│       │       └── settings_repository_impl.dart
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   └── app_settings.dart
│       │   ├── repositories/
│       │   │   └── settings_repository.dart
│       │   └── usecases/
│       │       ├── get_settings.dart
│       │       └── update_settings.dart
│       │
│       └── presentation/
│           ├── providers/
│           │   └── settings_provider.dart
│           ├── screens/
│           │   └── settings_screen.dart
│           └── widgets/
│               ├── settings_section.dart
│               └── settings_item.dart
│
└── shared/                           # Shared UI components
    ├── widgets/
    │   ├── loading_indicator.dart
    │   ├── error_view.dart
    │   ├── empty_state.dart
    │   └── custom_button.dart
    └── dialogs/
        ├── confirmation_dialog.dart
        └── error_dialog.dart
```

## 4. Key Dependencies

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Navigation
  go_router: ^13.0.0

  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3
  json_annotation: ^4.8.1

  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Camera & Images
  camera: ^0.10.5+7
  image_picker: ^1.0.7
  image: ^4.1.3
  path_provider: ^2.1.1

  # Location & Maps
  geolocator: ^11.0.0
  geocoding: ^2.1.1
  google_maps_flutter: ^2.5.2
  permission_handler: ^11.1.0

  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0
  logger: ^2.0.2
  connectivity_plus: ^5.0.2

  # Code Over Air Updates
  shorebird_code_push: ^1.1.3

  # UI
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  retrofit_generator: ^8.0.6
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1

  # Linting
  flutter_lints: ^3.0.1
  very_good_analysis: ^5.1.0

  # Testing
  mockito: ^5.4.4
  mocktail: ^1.0.2
  fake_async: ^1.3.1
```

## 5. Configuration Management

### core/config/app_config.dart

```dart
/// Central configuration file - NO MAGIC NUMBERS
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Image Configuration
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 200;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const int maxImageSizeMB = 10;

  // Location Configuration
  static const double locationAccuracyMeters = 10.0;
  static const Duration locationTimeout = Duration(seconds: 10);
  static const bool enableBackgroundLocation = false;

  // History Configuration
  static const int defaultHistoryCount = 5;
  static const int maxHistoryCount = 20;
  static const int minHistoryCount = 3;

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const int itemsPerPage = 20;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // Terminal Options
  static const List<String> availableTerminals = ['B1', 'B3'];

  // Map Configuration
  static const double defaultMapZoom = 15.0;
  static const double detailMapZoom = 18.0;
  static const double mapMarkerSize = 40.0;

  // Logging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
  static const bool enableCrashReporting = true;

  // Shorebird
  static const bool enableShorebirdUpdates = true;
  static const Duration updateCheckInterval = Duration(hours: 6);
}
```

### core/config/env_config.dart

```dart
enum Environment { development, staging, production }

class EnvConfig {
  static Environment get environment {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return Environment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => Environment.development,
    );
  }

  static bool get isDevelopment => environment == Environment.development;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProduction => environment == Environment.production;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://dev-api.example.com';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }
}
```

## 6. Navigation Structure

### Using go_router with Riverpod

```dart
// core/config/routes.dart
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String browse = '/browse';
  static const String capture = '/capture';
  static const String detail = '/detail/:id';
  static const String settings = '/settings';
}

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.browse,
    routes: [
      GoRoute(
        path: AppRoutes.browse,
        name: 'browse',
        builder: (context, state) => const BrowseScreen(),
      ),
      GoRoute(
        path: AppRoutes.capture,
        name: 'capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.detail,
        name: 'detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetailScreen(trailerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
```

## 7. Data Models & Entities

### Domain Entity (Pure Dart)

```dart
// features/capture/domain/entities/trailer_capture.dart
class TrailerCapture {
  final String id;
  final String licensePlate;
  final String terminal;
  final Location location;
  final DateTime timestamp;
  final List<String> photoUrls;
  final bool isEmpty;
  final String? notes;

  const TrailerCapture({
    required this.id,
    required this.licensePlate,
    required this.terminal,
    required this.location,
    required this.timestamp,
    required this.photoUrls,
    this.isEmpty = false,
    this.notes,
  });
}

class Location {
  final double latitude;
  final double longitude;
  final double accuracy;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}
```

### Data Model (with JSON serialization)

```dart
// features/capture/data/models/trailer_capture_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trailer_capture.dart';

part 'trailer_capture_model.g.dart';

@JsonSerializable()
class TrailerCaptureModel {
  final String id;
  @JsonKey(name: 'license_plate')
  final String licensePlate;
  final String terminal;
  final LocationModel location;
  final DateTime timestamp;
  @JsonKey(name: 'photo_urls')
  final List<String> photoUrls;
  @JsonKey(name: 'is_empty')
  final bool isEmpty;
  final String? notes;

  TrailerCaptureModel({
    required this.id,
    required this.licensePlate,
    required this.terminal,
    required this.location,
    required this.timestamp,
    required this.photoUrls,
    this.isEmpty = false,
    this.notes,
  });

  factory TrailerCaptureModel.fromJson(Map<String, dynamic> json) =>
      _$TrailerCaptureModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrailerCaptureModelToJson(this);

  // Convert to domain entity
  TrailerCapture toEntity() {
    return TrailerCapture(
      id: id,
      licensePlate: licensePlate,
      terminal: terminal,
      location: location.toEntity(),
      timestamp: timestamp,
      photoUrls: photoUrls,
      isEmpty: isEmpty,
      notes: notes,
    );
  }

  // Create from domain entity
  factory TrailerCaptureModel.fromEntity(TrailerCapture entity) {
    return TrailerCaptureModel(
      id: entity.id,
      licensePlate: entity.licensePlate,
      terminal: entity.terminal,
      location: LocationModel.fromEntity(entity.location),
      timestamp: entity.timestamp,
      photoUrls: entity.photoUrls,
      isEmpty: entity.isEmpty,
      notes: entity.notes,
    );
  }
}
```

## 8. Repository Pattern

### Domain Repository Interface

```dart
// features/capture/domain/repositories/capture_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trailer_capture.dart';

abstract class CaptureRepository {
  Future<Either<Failure, TrailerCapture>> captureTrailer(
    TrailerCapture capture,
    List<String> imagePaths,
  );

  Future<Either<Failure, Location>> getCurrentLocation();

  Future<Either<Failure, List<String>>> uploadImages(List<String> imagePaths);
}
```

### Data Repository Implementation

```dart
// features/capture/data/repositories/capture_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trailer_capture.dart';
import '../../domain/repositories/capture_repository.dart';
import '../datasources/capture_local_datasource.dart';
import '../datasources/capture_remote_datasource.dart';
import '../models/trailer_capture_model.dart';

class CaptureRepositoryImpl implements CaptureRepository {
  final CaptureRemoteDataSource remoteDataSource;
  final CaptureLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CaptureRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TrailerCapture>> captureTrailer(
    TrailerCapture capture,
    List<String> imagePaths,
  ) async {
    try {
      // Upload images first
      final imageUrls = await remoteDataSource.uploadImages(imagePaths);

      // Create capture with image URLs
      final captureWithImages = TrailerCapture(
        id: capture.id,
        licensePlate: capture.licensePlate,
        terminal: capture.terminal,
        location: capture.location,
        timestamp: capture.timestamp,
        photoUrls: imageUrls,
        isEmpty: capture.isEmpty,
        notes: capture.notes,
      );

      final model = TrailerCaptureModel.fromEntity(captureWithImages);

      if (await networkInfo.isConnected) {
        // Save to remote
        final result = await remoteDataSource.createCapture(model);
        // Cache locally
        await localDataSource.cacheCapture(result);
        return Right(result.toEntity());
      } else {
        // Save locally for later sync
        await localDataSource.saveForSync(model);
        return Right(captureWithImages);
      }
    } on ServerException {
      return Left(ServerFailure());
    } on CacheException {
      return Left(CacheFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    try {
      final location = await remoteDataSource.getCurrentLocation();
      return Right(location.toEntity());
    } on LocationException {
      return Left(LocationFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadImages(
    List<String> imagePaths,
  ) async {
    try {
      final urls = await remoteDataSource.uploadImages(imagePaths);
      return Right(urls);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

## 9. Error Handling Strategy

### Failures (Domain Layer)

```dart
// core/errors/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = '']);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Failed to get location']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error occurred']);
}
```

### Exceptions (Data Layer)

```dart
// core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, [this.statusCode]);
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class LocationException implements Exception {
  final String message;

  LocationException(this.message);
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}
```

### Error Handling in UI

```dart
// Presenting errors to users
void _handleFailure(Failure failure) {
  String message;

  switch (failure.runtimeType) {
    case ServerFailure:
      message = 'Server error. Please try again later.';
      break;
    case NetworkFailure:
      message = 'No internet connection. Please check your network.';
      break;
    case LocationFailure:
      message = 'Failed to get your location. Please enable GPS.';
      break;
    case ValidationFailure:
      message = failure.message;
      break;
    default:
      message = 'An unexpected error occurred.';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

## 10. Provider Examples

### Riverpod with Code Generation

```dart
// features/capture/presentation/providers/capture_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trailer_capture.dart';
import '../../domain/usecases/capture_trailer.dart';

part 'capture_provider.g.dart';

@riverpod
class CaptureNotifier extends _$CaptureNotifier {
  @override
  AsyncValue<TrailerCapture?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> captureTrailer(
    TrailerCapture capture,
    List<String> imagePaths,
  ) async {
    state = const AsyncValue.loading();

    final useCase = ref.read(captureTrailerUseCaseProvider);
    final result = await useCase(
      CaptureTrailerParams(
        capture: capture,
        imagePaths: imagePaths,
      ),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (capture) => AsyncValue.data(capture),
    );
  }
}

// Usage in widget
class CaptureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(captureNotifierProvider);

    return captureState.when(
      data: (capture) => _buildSuccess(capture),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        failure: error as Failure,
        onRetry: () => ref.invalidate(captureNotifierProvider),
      ),
    );
  }
}
```

## 11. Testing Strategy

### Test Structure
```
test/
├── unit/
│   ├── core/
│   ├── features/
│   │   ├── capture/
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   └── data/
│   │   │       └── repositories/
│   │   └── browse/
│   └── shared/
├── widget/
│   └── features/
│       ├── capture/
│       └── browse/
└── integration/
    └── app_test.dart
```

### Example Unit Test

```dart
// test/unit/features/capture/domain/usecases/capture_trailer_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late CaptureTrailer useCase;
  late MockCaptureRepository mockRepository;

  setUp(() {
    mockRepository = MockCaptureRepository();
    useCase = CaptureTrailer(mockRepository);
  });

  test('should capture trailer and return success', () async {
    // Arrange
    final capture = TrailerCapture(/* ... */);
    when(mockRepository.captureTrailer(any, any))
        .thenAnswer((_) async => Right(capture));

    // Act
    final result = await useCase(CaptureTrailerParams(
      capture: capture,
      imagePaths: ['path1.jpg', 'path2.jpg'],
    ));

    // Assert
    expect(result, Right(capture));
    verify(mockRepository.captureTrailer(capture, ['path1.jpg', 'path2.jpg']));
  });
}
```

## 12. Shorebird Integration

```dart
// main.dart
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Shorebird
  final shorebirdCodePush = ShorebirdCodePush();

  // Check for updates
  if (AppConfig.enableShorebirdUpdates) {
    final isUpdateAvailable =
        await shorebirdCodePush.isNewPatchAvailableForDownload();

    if (isUpdateAvailable) {
      // Download update in background
      await shorebirdCodePush.downloadUpdateIfAvailable();
    }
  }

  runApp(
    const ProviderScope(
      child: TrailerManagementApp(),
    ),
  );
}
```

## 13. Summary

### Key Architectural Decisions

1. **Clean Architecture**: Separation of concerns with clear layer boundaries
2. **Feature-First Structure**: Easy to navigate and scale
3. **Riverpod for State Management**: Modern, type-safe, testable
4. **Either Type for Error Handling**: Explicit error handling with dartz
5. **Repository Pattern**: Abstraction over data sources
6. **Code Generation**: Reduced boilerplate with build_runner
7. **Configuration Management**: Centralized, no magic numbers
8. **go_router for Navigation**: Declarative routing with deep linking support

### Benefits

- **Maintainable**: Clear structure and separation of concerns
- **Testable**: Pure functions, dependency injection via Riverpod
- **Scalable**: Easy to add new features without affecting existing code
- **Type-Safe**: Compile-time checks with Riverpod and code generation
- **Offline-First**: Local caching with sync capabilities
- **Professional**: Follows industry best practices and Flutter guidelines

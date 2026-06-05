# Quick Start Guide

This guide will help you set up and start developing the Trailer Management Flutter app.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Package Dependencies](#package-dependencies)
4. [Development Workflow](#development-workflow)
5. [Key Commands](#key-commands)
6. [Best Practices](#best-practices)
7. [Common Issues](#common-issues)

---

## Prerequisites

### Required Software
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher (comes with Flutter)
- **IDE**: VS Code or Android Studio with Flutter/Dart plugins
- **Git**: For version control

### Recommended VS Code Extensions
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "alexisvt.flutter-snippets",
    "nash.awesome-flutter-snippets",
    "usernamehw.errorlens"
  ]
}
```

### Platform-Specific Requirements

#### iOS Development
- macOS with Xcode 14.0 or higher
- CocoaPods installed
- iOS device or simulator

#### Android Development
- Android Studio or Android SDK
- Java JDK 17
- Android device or emulator

---

## Project Setup

### 1. Create Flutter Project
```bash
flutter create --org com.yourcompany lagerkontroll
cd lagerkontroll
```

### 2. Configure pubspec.yaml

Create or update your `pubspec.yaml` with the following dependencies:

```yaml
name: lagerkontroll
description: A trailer management application with capture, browse, and tracking features.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: '>=3.16.0'

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

  # Functional Programming
  dartz: ^0.10.1
  equatable: ^2.0.5

  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Camera & Images
  camera: ^0.10.5+7
  image_picker: ^1.0.7
  image: ^4.1.3
  path_provider: ^2.1.1
  path: ^1.8.3

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
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/

  # fonts:
  #   - family: CustomFont
  #     fonts:
  #       - asset: assets/fonts/CustomFont-Regular.ttf
  #       - asset: assets/fonts/CustomFont-Bold.ttf
  #         weight: 700
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Linting

Create `analysis_options.yaml`:
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

  errors:
    invalid_annotation_target: ignore

  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    # Customize rules as needed
    public_member_api_docs: false
    lines_longer_than_80_chars: false
    prefer_single_quotes: true
    always_use_package_imports: true
```

### 5. Setup Shorebird (for OTA updates)

Install Shorebird CLI:
```bash
# macOS/Linux
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Windows (PowerShell)
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
iwr -UseBasicParsing 'https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1'|iex
```

Initialize Shorebird in project:
```bash
shorebird init
```

Create `shorebird.yaml`:
```yaml
app_id: your-app-id-here
flavors:
  development:
    app_id: your-dev-app-id
  production:
    app_id: your-prod-app-id
```

---

## Package Dependencies Explained

### Core Packages

#### State Management
- **flutter_riverpod**: Modern, type-safe state management
- **riverpod_annotation**: Code generation for providers

#### Navigation
- **go_router**: Declarative routing with deep linking support

#### Networking
- **dio**: Powerful HTTP client with interceptors
- **retrofit**: Type-safe REST client generator
- **json_annotation**: JSON serialization support

#### Functional Programming
- **dartz**: Functional programming (Either type for error handling)
- **equatable**: Value equality without boilerplate

#### Local Storage
- **shared_preferences**: Simple key-value storage
- **hive**: Fast, lightweight NoSQL database
- **hive_flutter**: Hive Flutter integration

#### Camera & Images
- **camera**: Access device cameras
- **image_picker**: Pick images from gallery/camera
- **image**: Image manipulation
- **path_provider**: Access file system paths

#### Location & Maps
- **geolocator**: Get device location
- **geocoding**: Convert coordinates to addresses
- **google_maps_flutter**: Display Google Maps
- **permission_handler**: Request runtime permissions

#### Utilities
- **uuid**: Generate unique identifiers
- **intl**: Internationalization and date formatting
- **logger**: Logging utility
- **connectivity_plus**: Check network connectivity

#### Updates
- **shorebird_code_push**: Over-the-air updates

#### UI
- **cached_network_image**: Cached network images
- **flutter_svg**: SVG rendering
- **shimmer**: Loading shimmer effect

---

## Development Workflow

### Step-by-Step Feature Development

#### 1. Create Domain Layer (Pure Dart)
```bash
# Create entity
lib/features/my_feature/domain/entities/my_entity.dart

# Create repository interface
lib/features/my_feature/domain/repositories/my_repository.dart

# Create use case
lib/features/my_feature/domain/usecases/my_usecase.dart
```

#### 2. Create Data Layer
```bash
# Create model with JSON serialization
lib/features/my_feature/data/models/my_model.dart

# Create data sources
lib/features/my_feature/data/datasources/my_remote_datasource.dart
lib/features/my_feature/data/datasources/my_local_datasource.dart

# Create repository implementation
lib/features/my_feature/data/repositories/my_repository_impl.dart
```

#### 3. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. Create Presentation Layer
```bash
# Create providers
lib/features/my_feature/presentation/providers/my_provider.dart

# Create screen
lib/features/my_feature/presentation/screens/my_screen.dart

# Create widgets
lib/features/my_feature/presentation/widgets/my_widget.dart
```

#### 5. Write Tests
```bash
# Unit tests
test/unit/features/my_feature/domain/usecases/my_usecase_test.dart

# Widget tests
test/widget/features/my_feature/presentation/screens/my_screen_test.dart
```

#### 6. Run Tests
```bash
flutter test
```

---

## Key Commands

### Development
```bash
# Run in debug mode
flutter run

# Run with environment variables
flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=https://dev-api.example.com

# Hot reload
# Press 'r' in terminal while app is running

# Hot restart
# Press 'R' in terminal while app is running

# Run on specific device
flutter run -d <device-id>

# List devices
flutter devices
```

### Code Generation
```bash
# Generate code once
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (recommended during development)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter pub run build_runner clean
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/features/capture/domain/usecases/capture_trailer_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Building
```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android - for Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build with Shorebird (OTA updates)
shorebird release android
shorebird release ios
```

### Shorebird Commands
```bash
# Create new release
shorebird release android --flavor production

# Create patch (OTA update)
shorebird patch android --release-version 1.0.0+1

# Preview patch
shorebird preview

# Check patch status
shorebird patch list
```

### Linting & Formatting
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Fix auto-fixable issues
dart fix --apply
```

### Clean & Reset
```bash
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Best Practices

### 1. Code Organization
- Follow the feature-first structure
- Keep files small and focused (under 300 lines)
- One class per file
- Group related files in folders

### 2. Naming Conventions
```dart
// Files: snake_case
my_feature_screen.dart

// Classes: PascalCase
class MyFeatureScreen {}

// Variables & functions: camelCase
final myVariable = '';
void myFunction() {}

// Constants: SCREAMING_SNAKE_CASE or camelCase
const int MAX_RETRIES = 3;
const Duration apiTimeout = Duration(seconds: 30);

// Private members: prefix with _
String _privateVariable;
void _privateMethod() {}
```

### 3. Comments & Documentation
```dart
/// Public API should have documentation comments
///
/// Use triple slash for documentation
class MyClass {
  /// Describes what this method does
  ///
  /// Returns [String] with the result
  String myMethod() {
    // Regular comments for implementation details
    return 'result';
  }
}
```

### 4. Error Handling
```dart
// Always use Either for operations that can fail
Future<Either<Failure, Success>> myOperation() async {
  try {
    // operation
    return Right(success);
  } on SpecificException {
    return Left(SpecificFailure());
  } catch (e) {
    return Left(UnexpectedFailure(e.toString()));
  }
}
```

### 5. State Management
```dart
// Use code generation for providers
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  AsyncValue<MyData> build() {
    return const AsyncValue.data(null);
  }

  Future<void> myAction() async {
    state = const AsyncValue.loading();
    // perform action
    state = AsyncValue.data(result);
  }
}
```

### 6. Testing
```dart
// Every use case should have tests
void main() {
  late MyUseCase useCase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    useCase = MyUseCase(mockRepository);
  });

  test('should return success when operation succeeds', () async {
    // Arrange
    when(mockRepository.operation()).thenAnswer((_) async => Right(data));

    // Act
    final result = await useCase(params);

    // Assert
    expect(result, Right(data));
    verify(mockRepository.operation());
  });
}
```

### 7. Configuration Management
```dart
// Never hardcode values
// BAD
const timeout = 30;

// GOOD
const timeout = AppConfig.apiTimeout;
```

### 8. Asset Management
```dart
// Use constants for assets
// BAD
Image.asset('assets/images/logo.png')

// GOOD
Image.asset(AssetConstants.logo)
```

---

## Common Issues

### Issue 1: Code Generation Not Working
```bash
# Solution: Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue 2: Permission Issues (Camera/Location)

#### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE"/>
    </application>
</manifest>
```

#### iOS: `ios/Runner/Info.plist`
```xml
<dict>
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to capture trailer photos</string>

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need location access to track trailer locations</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need location access to track trailer locations</string>
</dict>
```

### Issue 3: Google Maps Not Showing

#### Android: Add API key
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

#### iOS: Add API key
```swift
// ios/Runner/AppDelegate.swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Issue 4: Build Failures After Dependency Updates
```bash
# Clean everything
flutter clean
cd ios && pod deintegrate && pod install && cd ..
cd android && ./gradlew clean && cd ..
flutter pub get
```

### Issue 5: Riverpod Provider Not Found
```dart
// Make sure you've run code generation
flutter pub run build_runner build --delete-conflicting-outputs

// Make sure you're watching the provider correctly
final value = ref.watch(myProvider); // ✓ Correct
final value = myProvider; // ✗ Wrong
```

---

## Environment Setup

### .env File (Create at project root)
```bash
# API Configuration
API_BASE_URL=https://api.example.com
API_TIMEOUT=30000

# Google Maps
GOOGLE_MAPS_API_KEY_ANDROID=your_android_key
GOOGLE_MAPS_API_KEY_IOS=your_ios_key

# Feature Flags
ENABLE_LOGGING=true
ENABLE_CRASH_REPORTING=true
```

### Load Environment Variables
```dart
// core/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}
```

---

## Git Setup

### .gitignore (Add to existing .gitignore)
```
# Environment files
.env
.env.*

# Generated files
*.g.dart
*.freezed.dart

# IDE
.vscode/
.idea/

# Build
build/
.dart_tool/

# Coverage
coverage/
```

### Recommended Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Example:
```
feat(capture): add camera functionality for trailer photos

- Implemented camera preview widget
- Added photo capture capability
- Integrated with capture provider

Closes #123
```

---

## Next Steps

1. **Set up the project structure** following `PROJECT_STRUCTURE.md`
2. **Implement core configuration** from `ARCHITECTURE.md`
3. **Start with one feature** (recommended: Capture feature)
4. **Write tests** as you implement features
5. **Set up CI/CD** for automated testing and deployment
6. **Configure Shorebird** for OTA updates

For detailed implementation examples, refer to `IMPLEMENTATION_EXAMPLES.md`.

For architecture decisions and patterns, refer to `ARCHITECTURE.md`.

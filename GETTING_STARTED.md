# Getting Started - Trailer Management App

Welcome! This guide will get you started with the Trailer Management Flutter app in under 30 minutes.

## What You'll Build

A professional trailer management app with:
- Camera capture for license plates and contents
- GPS location tracking
- Terminal selection (B1/B3)
- Browse and filter trailers
- Detailed trailer history
- Offline support with sync
- Over-the-air updates via Shorebird

## Prerequisites Check

Before starting, ensure you have:

- [ ] Flutter SDK 3.16.0 or higher
- [ ] Dart SDK 3.2.0 or higher
- [ ] VS Code or Android Studio with Flutter plugins
- [ ] Git installed
- [ ] For iOS: Xcode 14.0+ (macOS only)
- [ ] For Android: Android Studio or Android SDK

### Verify Installation

```bash
flutter --version
dart --version
git --version
```

Expected output:
```
Flutter 3.16.0 • channel stable
Dart 3.2.0
git version 2.x.x
```

## 5-Minute Quick Start

### 1. Review Documentation (5 min)

You have **11 documentation files** at your disposal:

```
📚 Documentation Suite (282 KB total)
├── 📖 README.md (12K) - Start here!
├── 📖 DOCUMENTATION_INDEX.md (12K) - Navigation guide
├── 📖 QUICK_START_GUIDE.md (16K) - Detailed setup
├── 📖 ARCHITECTURE.md (27K) - Architecture decisions
├── 📖 PROJECT_STRUCTURE.md (16K) - Folder organization
├── 📖 IMPLEMENTATION_EXAMPLES.md (34K) - Code examples
├── 📖 API_INTEGRATION_GUIDE.md (29K) - Networking guide
└── 📖 ARCHITECTURE_DIAGRAMS.md (32K) - Visual diagrams
```

**Read in this order**:
1. **README.md** (you are here!) - 5 minutes
2. **DOCUMENTATION_INDEX.md** - Quick navigation reference
3. **QUICK_START_GUIDE.md** - When ready to code

### 2. Understand the Architecture (5 min)

```
Clean Architecture with Feature-First Structure

┌─────────────────────────────────────┐
│  Presentation (UI + State)          │  ← Riverpod providers, screens, widgets
├─────────────────────────────────────┤
│  Application (Use Cases)            │  ← Business logic
├─────────────────────────────────────┤
│  Domain (Entities + Interfaces)     │  ← Pure Dart, no dependencies
├─────────────────────────────────────┤
│  Data (Repositories + DataSources)  │  ← API calls, local storage
└─────────────────────────────────────┘
```

**Key Principles**:
- ✅ Separation of concerns
- ✅ No magic numbers (all in config)
- ✅ Testable (every layer)
- ✅ Type-safe (Riverpod + code generation)
- ✅ Offline-first (local caching + sync)

### 3. Key Technology Decisions (5 min)

| Aspect | Technology | Why? |
|--------|-----------|------|
| **State Management** | Riverpod 2.x | Type-safe, testable, modern |
| **Navigation** | go_router | Declarative, deep linking |
| **Networking** | Dio + Retrofit | Type-safe API clients |
| **Local Storage** | Hive | Fast, lightweight NoSQL |
| **Error Handling** | dartz (Either) | Explicit error handling |
| **Camera** | camera package | Native camera access |
| **Location** | geolocator | GPS tracking |
| **Maps** | google_maps_flutter | Map integration |
| **Updates** | Shorebird | OTA updates |

### 4. Project Structure (5 min)

```
lib/
├── core/                    # Shared functionality
│   ├── config/             # All configuration (NO MAGIC NUMBERS)
│   ├── theme/              # App theme
│   ├── utils/              # Utilities
│   ├── errors/             # Error handling
│   └── network/            # Network setup
│
├── features/               # Feature modules (feature-first!)
│   ├── capture/           # Capture trailers
│   │   ├── data/          # API, cache, models
│   │   ├── domain/        # Entities, interfaces, use cases
│   │   └── presentation/  # Screens, widgets, providers
│   │
│   ├── browse/            # List trailers
│   ├── detail/            # Trailer details
│   └── settings/          # App settings
│
└── shared/                # Shared UI components
    ├── widgets/
    └── dialogs/
```

### 5. Your First Feature (10 min reading)

Let's understand how a feature works using the **Capture** feature:

```
User Action: Tap "Capture Trailer"
    ↓
CaptureScreen (Presentation)
    ↓ calls
CaptureProvider (Riverpod)
    ↓ calls
CaptureTrailer UseCase (Application)
    ↓ calls
CaptureRepository Interface (Domain)
    ↓ implemented by
CaptureRepositoryImpl (Data)
    ↓ uses
RemoteDataSource (API) + LocalDataSource (Cache)
    ↓ returns
Either<Failure, TrailerCapture>
    ↓ handled by
CaptureProvider (updates state)
    ↓ triggers
CaptureScreen rebuild (shows success/error)
```

**Key Pattern**: Every operation returns `Either<Failure, Success>`
- `Left(Failure)` = Error occurred
- `Right(Success)` = Operation succeeded

## Next Steps

### Option 1: Read Documentation (Recommended)

**Total time: 1-2 hours for complete understanding**

1. ✅ **README.md** (you are here!)
2. **QUICK_START_GUIDE.md** - Setup instructions
3. **ARCHITECTURE.md** - Deep dive into architecture
4. **IMPLEMENTATION_EXAMPLES.md** - Code examples

### Option 2: Jump to Code (For Experienced Developers)

**Prerequisites**: Familiar with Flutter, Clean Architecture, Riverpod

1. ✅ **README.md** (you are here!)
2. **PROJECT_STRUCTURE.md** - Know where files go
3. **IMPLEMENTATION_EXAMPLES.md** - Copy/paste examples
4. Start coding!

### Option 3: Watch and Learn (Visual Learners)

1. ✅ **README.md** (you are here!)
2. **ARCHITECTURE_DIAGRAMS.md** - Visual flow diagrams
3. **IMPLEMENTATION_EXAMPLES.md** - See the code
4. Start implementing!

## Essential Concepts

### 1. No Magic Numbers

**❌ Bad**:
```dart
const timeout = 30;
const imageQuality = 85;
```

**✅ Good**:
```dart
const timeout = AppConfig.apiTimeout;
const imageQuality = AppConfig.imageQuality;
```

All configuration lives in `core/config/app_config.dart`

### 2. Error Handling

**All operations return `Either<Failure, Success>`**:

```dart
// Use case
Future<Either<Failure, Trailer>> call(String id) async {
  return await repository.getTrailer(id);
}

// In UI
final result = await useCase(id);
result.fold(
  (failure) => showError(failure),
  (trailer) => showSuccess(trailer),
);
```

### 3. State Management with Riverpod

```dart
// Define provider
@riverpod
class TrailerList extends _$TrailerList {
  @override
  Future<List<Trailer>> build() async {
    return await _fetchTrailers();
  }
}

// Watch in UI
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final trailers = ref.watch(trailerListProvider);

    return trailers.when(
      data: (list) => ListView(...),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorView(error),
    );
  }
}
```

### 4. Feature Development Workflow

When adding a new feature:

1. **Domain Layer** (Pure Dart)
   - Create entities
   - Define repository interface
   - Write use cases

2. **Data Layer** (Implementation)
   - Create models with JSON serialization
   - Implement repository
   - Create data sources (remote + local)

3. **Generate Code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Presentation Layer** (UI)
   - Create providers
   - Build screens
   - Create widgets

5. **Test**
   - Unit test use cases
   - Widget test screens
   - Integration test flows

## Quick Commands Reference

```bash
# Setup
flutter pub get

# Generate code (models, providers, etc.)
flutter pub run build_runner watch --delete-conflicting-outputs

# Run app
flutter run

# Run with environment
flutter run --dart-define=ENV=development

# Test
flutter test

# Build
flutter build apk --release
flutter build ios --release

# Format
dart format lib/ test/

# Analyze
flutter analyze

# Clean
flutter clean
```

## Common Patterns

### Creating a New Screen

```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: state.when(
        data: (data) => _buildContent(data),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(error: error),
      ),
    );
  }
}
```

### Creating a Provider

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  AsyncValue<MyData> build() {
    return const AsyncValue.data(null);
  }

  Future<void> loadData() async {
    state = const AsyncValue.loading();

    final useCase = ref.read(myUseCaseProvider);
    final result = await useCase(params);

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (data) => AsyncValue.data(data),
    );
  }
}
```

### Making API Calls

```dart
class MyRemoteDataSource {
  final ApiClient apiClient;

  Future<MyModel> getData() async {
    try {
      final response = await apiClient.get('/endpoint');

      if (response.statusCode == 200) {
        return MyModel.fromJson(response.data);
      } else {
        throw ServerException('Failed', response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

## Environment Variables

Create `.env` file (gitignored):

```bash
API_BASE_URL=https://api.example.com
GOOGLE_MAPS_API_KEY_ANDROID=your_key
GOOGLE_MAPS_API_KEY_IOS=your_key
ENABLE_LOGGING=true
```

## Troubleshooting

### Build fails
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Permission issues
- Check `AndroidManifest.xml` for Android
- Check `Info.plist` for iOS

### Code generation not working
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## File Checklist

Before you start coding, verify you have:

- [x] All documentation files (11 files)
- [ ] Flutter SDK installed
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] Code generation working
- [ ] IDE with Flutter plugins
- [ ] Git configured

## Resources

### Documentation Files
- **README.md** - Project overview
- **DOCUMENTATION_INDEX.md** - Navigation guide
- **QUICK_START_GUIDE.md** - Detailed setup
- **ARCHITECTURE.md** - Architecture deep dive
- **PROJECT_STRUCTURE.md** - Folder structure
- **IMPLEMENTATION_EXAMPLES.md** - Code examples
- **API_INTEGRATION_GUIDE.md** - Networking
- **ARCHITECTURE_DIAGRAMS.md** - Visual diagrams

### External Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [go_router Documentation](https://pub.dev/packages/go_router)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Shorebird Documentation](https://shorebird.dev)

## Getting Help

1. Check documentation files (listed above)
2. Search existing issues
3. Ask in team chat
4. Create a new issue with:
   - What you're trying to do
   - What you expected
   - What actually happened
   - Steps to reproduce

## Success Checklist

You're ready to code when you can answer:

- [ ] What is Clean Architecture? *(See ARCHITECTURE.md)*
- [ ] Why do we use Riverpod? *(Type-safe, testable, modern)*
- [ ] Where do configuration values go? *(core/config/app_config.dart)*
- [ ] How do we handle errors? *(Either<Failure, Success>)*
- [ ] What's the feature folder structure? *(data/domain/presentation)*
- [ ] How do we make API calls? *(See API_INTEGRATION_GUIDE.md)*

## What's Next?

### Immediate Next Steps (Choose One)

**Path A: Deep Dive** (2 hours)
1. Read ARCHITECTURE.md
2. Read IMPLEMENTATION_EXAMPLES.md
3. Start coding!

**Path B: Quick Start** (30 minutes)
1. Skim ARCHITECTURE.md
2. Review IMPLEMENTATION_EXAMPLES.md
3. Start with a simple feature

**Path C: Visual Learning** (1 hour)
1. Review ARCHITECTURE_DIAGRAMS.md
2. Check IMPLEMENTATION_EXAMPLES.md
3. Follow the patterns

### Recommended First Task

**Implement a simple feature**:
1. Create a new widget in `shared/widgets/`
2. Use it in an existing screen
3. Write a widget test
4. Submit a PR

This will help you:
- Understand the codebase structure
- Learn the development workflow
- Get familiar with testing
- Experience the review process

## Remember

- **No magic numbers** - Use AppConfig
- **Explicit errors** - Use Either type
- **Test everything** - Write tests as you code
- **Follow patterns** - Check IMPLEMENTATION_EXAMPLES.md
- **Ask questions** - Better to ask than guess

## Summary

You now have:
- ✅ Complete architecture documentation
- ✅ Step-by-step guides
- ✅ Code examples for every layer
- ✅ Visual diagrams
- ✅ Best practices
- ✅ Troubleshooting help

**Time to start building!**

Read next: **[QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)** for detailed setup instructions.

---

**Questions?** Check [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for navigation help.

Good luck! 🚀

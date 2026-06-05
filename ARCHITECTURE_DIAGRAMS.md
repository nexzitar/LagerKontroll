# Architecture Diagrams

Visual representations of the Trailer Management App architecture.

## Table of Contents
1. [Overall Architecture](#overall-architecture)
2. [Feature Architecture](#feature-architecture)
3. [Data Flow](#data-flow)
4. [State Management](#state-management)
5. [Navigation Flow](#navigation-flow)
6. [Error Handling Flow](#error-handling-flow)
7. [Offline Sync Flow](#offline-sync-flow)

---

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Capture    │  │    Browse    │  │    Detail    │          │
│  │   Screen     │  │   Screen     │  │   Screen     │  ...     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│  ┌──────▼──────────────────▼──────────────────▼───────┐         │
│  │            Riverpod Providers (State)              │         │
│  └──────────────────────┬─────────────────────────────┘         │
└─────────────────────────┼───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                      APPLICATION LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Capture    │  │   Get        │  │   Update     │          │
│  │   Trailer    │  │   Trailers   │  │   Location   │  ...     │
│  │   UseCase    │  │   UseCase    │  │   UseCase    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼──────────────────┐
│                         DOMAIN LAYER                             │
│  ┌────────────────────────────────────────────────────┐          │
│  │              Repository Interfaces                 │          │
│  │  (CaptureRepository, BrowseRepository, etc.)      │          │
│  └────────────────────────────────────────────────────┘          │
│  ┌────────────────────────────────────────────────────┐          │
│  │                    Entities                        │          │
│  │  (TrailerCapture, Trailer, Location, etc.)        │          │
│  └────────────────────────────────────────────────────┘          │
└─────────────────────────┬────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                         DATA LAYER                               │
│  ┌────────────────────────────────────────────────────┐          │
│  │          Repository Implementations                │          │
│  └──────┬───────────────────────────────────┬─────────┘          │
│         │                                   │                    │
│  ┌──────▼───────────┐              ┌───────▼──────────┐         │
│  │ Remote DataSource│              │ Local DataSource │         │
│  │  (API Client)    │              │   (Hive/Cache)   │         │
│  └──────┬───────────┘              └───────┬──────────┘         │
└─────────┼──────────────────────────────────┼────────────────────┘
          │                                   │
    ┌─────▼──────┐                    ┌──────▼─────┐
    │  Backend   │                    │   Device   │
    │    API     │                    │  Storage   │
    └────────────┘                    └────────────┘
```

---

## Feature Architecture

### Capture Feature Structure

```
features/capture/
│
├── PRESENTATION (UI Layer)
│   │
│   ├── Screens
│   │   └── CaptureScreen
│   │       ├── Displays UI
│   │       ├── Watches providers
│   │       └── Handles user input
│   │
│   ├── Widgets
│   │   ├── CameraView
│   │   ├── TerminalSelector
│   │   └── LocationDisplay
│   │
│   └── Providers (Riverpod)
│       ├── CaptureProvider
│       │   ├── Holds state
│       │   ├── Calls use cases
│       │   └── Updates UI
│       │
│       └── LocationProvider
│           └── Manages location state
│
├── DOMAIN (Business Logic)
│   │
│   ├── Entities (Pure Dart)
│   │   ├── TrailerCapture
│   │   ├── Location
│   │   └── Terminal
│   │
│   ├── Repository Interface
│   │   └── CaptureRepository (abstract)
│   │       ├── captureTrailer()
│   │       ├── getCurrentLocation()
│   │       └── uploadImages()
│   │
│   └── Use Cases
│       ├── CaptureTrailer
│       │   ├── Validates input
│       │   ├── Calls repository
│       │   └── Returns Either<Failure, Success>
│       │
│       └── GetCurrentLocation
│           └── Business logic for location
│
└── DATA (Implementation)
    │
    ├── Models (JSON Serialization)
    │   ├── TrailerCaptureModel
    │   │   ├── toJson()
    │   │   ├── fromJson()
    │   │   ├── toEntity()
    │   │   └── fromEntity()
    │   │
    │   └── LocationModel
    │
    ├── Repository Implementation
    │   └── CaptureRepositoryImpl
    │       ├── Implements interface
    │       ├── Coordinates data sources
    │       └── Handles errors
    │
    └── Data Sources
        ├── Remote (API)
        │   ├── API calls
        │   ├── Image upload
        │   └── Error handling
        │
        └── Local (Cache)
            ├── Hive storage
            ├── Offline queue
            └── Cache management
```

---

## Data Flow

### Happy Path: Capturing a Trailer

```
┌─────────────┐
│    User     │
│  Interacts  │
└──────┬──────┘
       │ 1. Taps "Capture"
       ▼
┌─────────────────────┐
│  CaptureScreen      │
│  (Presentation)     │
└──────┬──────────────┘
       │ 2. Calls provider method
       ▼
┌─────────────────────┐
│  CaptureProvider    │
│  (State Manager)    │
└──────┬──────────────┘
       │ 3. Sets loading state
       │ 4. Calls use case
       ▼
┌─────────────────────┐
│  CaptureTrailer     │
│  (Use Case)         │
└──────┬──────────────┘
       │ 5. Validates input
       │ 6. Calls repository
       ▼
┌─────────────────────┐
│  CaptureRepository  │
│  Implementation     │
└──────┬──────────────┘
       │ 7. Checks network
       ├─── Online ────────┐
       │                   ▼
       │         ┌────────────────────┐
       │         │ RemoteDataSource   │
       │         │ - Upload images    │
       │         │ - Post to API      │
       │         └─────────┬──────────┘
       │                   │ 8. Success
       │                   ▼
       │         ┌────────────────────┐
       │         │ LocalDataSource    │
       │         │ - Cache result     │
       │         └─────────┬──────────┘
       │                   │
       ├───────────────────┘
       │
       └─── Offline ──────┐
                          ▼
                ┌────────────────────┐
                │ LocalDataSource    │
                │ - Save for sync    │
                └─────────┬──────────┘
                          │ 9. Return Either
                          ▼
                ┌─────────────────────┐
                │  CaptureProvider    │
                │  Updates state      │
                └──────┬──────────────┘
                       │ 10. Notify listeners
                       ▼
                ┌─────────────────────┐
                │  CaptureScreen      │
                │  Rebuilds UI        │
                └──────┬──────────────┘
                       │ 11. Show success
                       ▼
                ┌─────────────┐
                │    User     │
                │  Sees       │
                │  Feedback   │
                └─────────────┘
```

### Error Path

```
┌─────────────────────┐
│  Use Case           │
│  Validates input    │
└──────┬──────────────┘
       │ Validation fails
       ▼
┌─────────────────────┐
│  Returns            │
│  Left(ValidationFailure)
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Provider           │
│  state = error      │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Screen             │
│  Shows error UI     │
└─────────────────────┘
```

---

## State Management

### Riverpod Provider Lifecycle

```
┌──────────────────────────────────────────────────────────────┐
│                    Provider Definition                        │
│                                                               │
│  @riverpod                                                    │
│  class CaptureNotifier extends _$CaptureNotifier {          │
│    @override                                                  │
│    AsyncValue<TrailerCapture?> build() {                     │
│      return const AsyncValue.data(null);                     │
│    }                                                          │
│  }                                                            │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                  Initial State: data(null)                    │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ User action triggers captureTrailer()
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              State: AsyncValue.loading()                      │
│  ┌──────────────────────────────────────────────────┐        │
│  │  Screen shows loading indicator                  │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ Operation completes
                       │
        ┌──────────────┴────────────────┐
        │                               │
        ▼                               ▼
┌───────────────────┐          ┌───────────────────┐
│  State: data()    │          │  State: error()   │
│  ┌──────────────┐ │          │  ┌──────────────┐ │
│  │ Show success │ │          │  │ Show error   │ │
│  └──────────────┘ │          │  │ UI with      │ │
└───────────────────┘          │  │ retry button │ │
                               │  └──────────────┘ │
                               └───────────────────┘
```

### Widget Consumption Pattern

```
┌─────────────────────────────────────────┐
│         ConsumerWidget                  │
│                                         │
│  Widget build(context, ref) {          │
│    final state = ref.watch(provider);  │
│                                         │
│    return state.when(                  │
│      data: (value) => SuccessUI(),     │
│      loading: () => LoadingUI(),       │
│      error: (e, s) => ErrorUI(),       │
│    );                                   │
│  }                                      │
└─────────────────────────────────────────┘
```

---

## Navigation Flow

```
┌──────────────┐
│  App Start   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  BrowseScreen    │ (Default route)
│  /browse         │
└────┬─────┬───┬───┘
     │     │   │
     │     │   └─────────────┐
     │     │                 │
     │     └────────┐        │
     │              │        │
     ▼              ▼        ▼
┌────────────┐  ┌──────────────┐  ┌──────────────┐
│  Capture   │  │   Detail     │  │   Settings   │
│  Screen    │  │   Screen     │  │   Screen     │
│  /capture  │  │  /detail/:id │  │  /settings   │
└────────────┘  └──────────────┘  └──────────────┘

Navigation Actions:
- BrowseScreen → CaptureScreen: FAB button
- BrowseScreen → DetailScreen: Tap list item
- BrowseScreen → SettingsScreen: AppBar action
- DetailScreen → BrowseScreen: Back button
- CaptureScreen → BrowseScreen: After success
```

### Navigation with go_router

```dart
// Route definition
GoRoute(
  path: '/detail/:id',
  name: 'detail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return DetailScreen(trailerId: id);
  },
)

// Navigate
context.go('/detail/$id')           // Replace current route
context.push('/detail/$id')         // Push on stack
context.pop()                       // Go back
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Operation Starts                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Try Block Executes                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴────────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐              ┌────────────────────┐
│   Success     │              │   Exception        │
└───────┬───────┘              └─────────┬──────────┘
        │                                │
        │                      ┌─────────┴──────────┐
        │                      │                    │
        │                      ▼                    ▼
        │              ┌───────────────┐   ┌──────────────┐
        │              │ Known         │   │ Unknown      │
        │              │ Exception     │   │ Exception    │
        │              └───────┬───────┘   └──────┬───────┘
        │                      │                  │
        │                      ▼                  ▼
        │              ┌───────────────┐   ┌──────────────┐
        │              │ Specific      │   │ Generic      │
        │              │ Failure       │   │ Failure      │
        │              └───────┬───────┘   └──────┬───────┘
        │                      │                  │
        ▼                      ▼                  ▼
┌───────────────────────────────────────────────────────┐
│          Return Either<Failure, Success>              │
└──────────────────────┬────────────────────────────────┘
                       │
        ┌──────────────┴────────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐              ┌────────────────────┐
│  Right(data)  │              │  Left(failure)     │
└───────┬───────┘              └─────────┬──────────┘
        │                                │
        ▼                                ▼
┌───────────────┐              ┌────────────────────┐
│  Show         │              │  Show              │
│  Success UI   │              │  Error UI          │
└───────────────┘              └────────────────────┘

Exception Types → Failure Types:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ServerException      → ServerFailure
NetworkException     → NetworkFailure
CacheException       → CacheFailure
LocationException    → LocationFailure
ValidationError      → ValidationFailure
Unknown Exception    → UnexpectedFailure
```

---

## Offline Sync Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    User Creates Capture                       │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              Check Network Connectivity                       │
└──────────────────────┬───────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌───────────────┐            ┌────────────────────┐
│   ONLINE      │            │   OFFLINE          │
└───────┬───────┘            └─────────┬──────────┘
        │                              │
        ▼                              ▼
┌───────────────────┐        ┌──────────────────────┐
│ 1. Upload images  │        │ 1. Save locally      │
│ 2. Post to API    │        │ 2. Queue for sync    │
│ 3. Cache locally  │        │ 3. Return success    │
│ 4. Return success │        └──────────┬───────────┘
└───────────────────┘                   │
                                        │
                                        ▼
                              ┌──────────────────────┐
                              │  Sync Queue          │
                              │  ┌────────────────┐  │
                              │  │ Pending Item 1 │  │
                              │  │ Pending Item 2 │  │
                              │  │ Pending Item 3 │  │
                              │  └────────────────┘  │
                              └──────────┬───────────┘
                                        │
                                        │ Network restored
                                        ▼
                              ┌──────────────────────┐
                              │  Background Sync     │
                              │                      │
                              │  For each pending:   │
                              │  1. Upload images    │
                              │  2. Post to API      │
                              │  3. Remove from queue│
                              │  4. Cache result     │
                              └──────────────────────┘

Sync Triggers:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Network connectivity restored
2. App comes to foreground
3. Manual refresh
4. Periodic background sync (if enabled)
```

---

## Component Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                              │
│                                                              │
│  Screen → Provider → UseCase → Repository → DataSource      │
│    ↑         ↑          ↑           ↑            ↑          │
│    │         │          │           │            │          │
│    │         │          │           │            │          │
│  Depends  Depends   Depends     Depends      Depends        │
│    on        on         on          on           on         │
│    │         │          │           │            │          │
│    ▼         ▼          ▼           ▼            ▼          │
│                                                              │
│  Widget  Riverpod   UseCase   Repository    API/Cache       │
│  Tree    Provider   Interface Interface                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Dependency Flow (Bottom to Top):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 5: DataSources (API, Cache)
   ↓
Layer 4: Repository Implementation
   ↓
Layer 3: Repository Interface (Domain)
   ↓
Layer 2: Use Cases
   ↓
Layer 1: Providers (State Management)
   ↓
Layer 0: UI (Screens, Widgets)

Each layer only knows about the layer below it!
```

---

## Testing Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Testing Pyramid                         │
│                                                              │
│                         ▲                                    │
│                        ╱ ╲                                   │
│                       ╱   ╲                                  │
│                      ╱     ╲                                 │
│                     ╱  E2E  ╲   Few, slow, expensive        │
│                    ╱  Tests  ╲  (Integration tests)         │
│                   ╱___________╲                              │
│                  ╱             ╲                             │
│                 ╱   Widget      ╲  Some, medium speed       │
│                ╱     Tests       ╲ (UI component tests)     │
│               ╱___________________╲                          │
│              ╱                     ╲                         │
│             ╱     Unit Tests        ╲  Many, fast, cheap    │
│            ╱   (Logic, Use Cases)    ╲ (Isolated tests)     │
│           ╱___________________________╲                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Test Coverage by Layer:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Unit Tests (70%):
- Domain entities
- Use cases
- Repository implementations
- Data models
- Utilities

Widget Tests (20%):
- Individual widgets
- Screen layouts
- User interactions

Integration Tests (10%):
- Full user flows
- End-to-end scenarios
```

This architecture ensures:
- **Testability**: Each layer can be tested in isolation
- **Maintainability**: Clear boundaries and responsibilities
- **Scalability**: Easy to add new features without affecting existing code
- **Type Safety**: Compile-time checks with Riverpod and strong typing
- **Error Handling**: Explicit error handling at every layer

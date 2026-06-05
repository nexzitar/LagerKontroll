# Implementation Examples

This document provides concrete code examples for implementing key parts of the trailer management app.

## Table of Contents
1. [Main Entry Point](#1-main-entry-point)
2. [Configuration Files](#2-configuration-files)
3. [Data Models](#3-data-models)
4. [Repository Pattern](#4-repository-pattern)
5. [Use Cases](#5-use-cases)
6. [Riverpod Providers](#6-riverpod-providers)
7. [Screen Implementation](#7-screen-implementation)
8. [Widget Examples](#8-widget-examples)
9. [API Client](#9-api-client)
10. [Error Handling](#10-error-handling)

---

## 1. Main Entry Point

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();

  // Initialize Shorebird for OTA updates
  if (AppConfig.enableShorebirdUpdates) {
    await _checkForUpdates();
  }

  // Run app with Riverpod
  runApp(
    const ProviderScope(
      child: TrailerManagementApp(),
    ),
  );
}

Future<void> _checkForUpdates() async {
  try {
    final shorebirdCodePush = ShorebirdCodePush();
    final isUpdateAvailable =
        await shorebirdCodePush.isNewPatchAvailableForDownload();

    if (isUpdateAvailable) {
      AppLogger.info('New update available, downloading...');
      await shorebirdCodePush.downloadUpdateIfAvailable();
      AppLogger.info('Update downloaded successfully');
    }
  } catch (e) {
    AppLogger.error('Failed to check for updates: $e');
  }
}
```

### app.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';

class TrailerManagementApp extends ConsumerWidget {
  const TrailerManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Trailer Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## 2. Configuration Files

### core/config/app_config.dart
```dart
/// Central configuration file - NO MAGIC NUMBERS
class AppConfig {
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
}
```

### core/constants/api_constants.dart
```dart
class ApiConstants {
  ApiConstants._();

  // Base paths
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiVersion = AppConfig.apiVersion;

  // Endpoints
  static const String trailers = '/trailers';
  static const String capture = '/trailers/capture';
  static const String upload = '/upload';
  static const String history = '/trailers/:id/history';

  // Query parameters
  static const String sortParam = 'sort';
  static const String filterParam = 'filter';
  static const String pageParam = 'page';
  static const String limitParam = 'limit';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';

  // Full endpoint builders
  static String get trailersEndpoint => '$baseUrl/$apiVersion$trailers';
  static String get captureEndpoint => '$baseUrl/$apiVersion$capture';
  static String get uploadEndpoint => '$baseUrl/$apiVersion$upload';
  static String trailerDetailEndpoint(String id) =>
      '$baseUrl/$apiVersion$trailers/$id';
  static String trailerHistoryEndpoint(String id) =>
      '$baseUrl/$apiVersion$trailers/$id/history';
}
```

---

## 3. Data Models

### features/capture/domain/entities/trailer_capture.dart
```dart
import 'package:equatable/equatable.dart';

/// Domain entity - Pure Dart, no dependencies
class TrailerCapture extends Equatable {
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

  TrailerCapture copyWith({
    String? id,
    String? licensePlate,
    String? terminal,
    Location? location,
    DateTime? timestamp,
    List<String>? photoUrls,
    bool? isEmpty,
    String? notes,
  }) {
    return TrailerCapture(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      terminal: terminal ?? this.terminal,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      photoUrls: photoUrls ?? this.photoUrls,
      isEmpty: isEmpty ?? this.isEmpty,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        terminal,
        location,
        timestamp,
        photoUrls,
        isEmpty,
        notes,
      ];
}

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  @override
  List<Object> get props => [latitude, longitude, accuracy];
}
```

### features/capture/data/models/trailer_capture_model.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trailer_capture.dart';
import 'location_model.dart';

part 'trailer_capture_model.g.dart';

@JsonSerializable()
class TrailerCaptureModel {
  final String id;
  @JsonKey(name: 'license_plate')
  final String licensePlate;
  final String terminal;
  final LocationModel location;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
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

  static DateTime _dateTimeFromJson(String json) => DateTime.parse(json);
  static String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();
}
```

---

## 4. Repository Pattern

### features/capture/domain/repositories/capture_repository.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trailer_capture.dart';

/// Repository interface - defines the contract
abstract class CaptureRepository {
  Future<Either<Failure, TrailerCapture>> captureTrailer(
    TrailerCapture capture,
    List<String> imagePaths,
  );

  Future<Either<Failure, Location>> getCurrentLocation();

  Future<Either<Failure, List<String>>> uploadImages(List<String> imagePaths);

  Future<Either<Failure, bool>> validateLicensePlate(String licensePlate);
}
```

### features/capture/data/repositories/capture_repository_impl.dart
```dart
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
      final captureWithImages = capture.copyWith(photoUrls: imageUrls);
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    try {
      final location = await remoteDataSource.getCurrentLocation();
      return Right(location.toEntity());
    } on LocationException catch (e) {
      return Left(LocationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadImages(
    List<String> imagePaths,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final urls = await remoteDataSource.uploadImages(imagePaths);
      return Right(urls);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateLicensePlate(
    String licensePlate,
  ) async {
    try {
      final isValid = await remoteDataSource.validateLicensePlate(licensePlate);
      return Right(isValid);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
```

---

## 5. Use Cases

### features/capture/domain/usecases/capture_trailer.dart
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trailer_capture.dart';
import '../repositories/capture_repository.dart';

/// Use case for capturing a trailer
/// Follows single responsibility principle
class CaptureTrailer implements UseCase<TrailerCapture, CaptureTrailerParams> {
  final CaptureRepository repository;

  CaptureTrailer(this.repository);

  @override
  Future<Either<Failure, TrailerCapture>> call(
    CaptureTrailerParams params,
  ) async {
    // Business logic validation
    if (params.imagePaths.isEmpty) {
      return const Left(
        ValidationFailure('At least one image is required'),
      );
    }

    if (params.capture.licensePlate.isEmpty) {
      return const Left(
        ValidationFailure('License plate is required'),
      );
    }

    // Delegate to repository
    return await repository.captureTrailer(
      params.capture,
      params.imagePaths,
    );
  }
}

class CaptureTrailerParams extends Equatable {
  final TrailerCapture capture;
  final List<String> imagePaths;

  const CaptureTrailerParams({
    required this.capture,
    required this.imagePaths,
  });

  @override
  List<Object> get props => [capture, imagePaths];
}
```

### core/usecases/usecase.dart (Base class)
```dart
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use case interface
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// For use cases that don't need parameters
class NoParams {}
```

---

## 6. Riverpod Providers

### Dependency Injection Setup

```dart
// features/capture/presentation/providers/capture_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/capture_local_datasource.dart';
import '../../data/datasources/capture_remote_datasource.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/repositories/capture_repository.dart';
import '../../domain/usecases/capture_trailer.dart';
import '../../../../core/network/network_info.dart';

part 'capture_providers.g.dart';

// Network Info Provider
@riverpod
NetworkInfo networkInfo(NetworkInfoRef ref) {
  return NetworkInfoImpl();
}

// Data Sources
@riverpod
CaptureRemoteDataSource captureRemoteDataSource(
  CaptureRemoteDataSourceRef ref,
) {
  return CaptureRemoteDataSourceImpl();
}

@riverpod
CaptureLocalDataSource captureLocalDataSource(
  CaptureLocalDataSourceRef ref,
) {
  return CaptureLocalDataSourceImpl();
}

// Repository
@riverpod
CaptureRepository captureRepository(CaptureRepositoryRef ref) {
  return CaptureRepositoryImpl(
    remoteDataSource: ref.watch(captureRemoteDataSourceProvider),
    localDataSource: ref.watch(captureLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
}

// Use Cases
@riverpod
CaptureTrailer captureTrailerUseCase(CaptureTrailerUseCaseRef ref) {
  return CaptureTrailer(ref.watch(captureRepositoryProvider));
}
```

### State Management Provider

```dart
// features/capture/presentation/providers/capture_state_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trailer_capture.dart';
import '../../domain/usecases/capture_trailer.dart';
import 'capture_providers.dart';

part 'capture_state_provider.g.dart';

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

  void reset() {
    state = const AsyncValue.data(null);
  }
}
```

### Location Provider Example

```dart
// features/capture/presentation/providers/location_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trailer_capture.dart';
import 'capture_providers.dart';

part 'location_provider.g.dart';

@riverpod
class LocationNotifier extends _$LocationNotifier {
  @override
  AsyncValue<Location?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();

    final repository = ref.read(captureRepositoryProvider);
    final result = await repository.getCurrentLocation();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (location) => AsyncValue.data(location),
    );
  }

  void clearLocation() {
    state = const AsyncValue.data(null);
  }
}
```

---

## 7. Screen Implementation

### features/capture/presentation/screens/capture_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/trailer_capture.dart';
import '../providers/capture_state_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/license_plate_input.dart';
import '../widgets/terminal_selector.dart';
import '../widgets/location_display.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _licensePlateController = TextEditingController();
  String _selectedTerminal = AppConfig.availableTerminals.first;
  bool _isEmpty = false;
  final List<String> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    // Get current location on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureNotifierProvider);
    final locationState = ref.watch(locationNotifierProvider);

    // Listen to capture state changes
    ref.listen<AsyncValue<TrailerCapture?>>(
      captureNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (capture) {
            if (capture != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trailer captured successfully')),
              );
              Navigator.of(context).pop();
            }
          },
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.toString()}')),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Trailer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(locationNotifierProvider.notifier).getCurrentLocation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // License Plate Input
              LicensePlateInput(
                controller: _licensePlateController,
              ),
              const SizedBox(height: AppConfig.defaultPadding),

              // Terminal Selector
              TerminalSelector(
                selectedTerminal: _selectedTerminal,
                onChanged: (terminal) {
                  setState(() => _selectedTerminal = terminal);
                },
              ),
              const SizedBox(height: AppConfig.defaultPadding),

              // Location Display
              locationState.when(
                data: (location) => LocationDisplay(location: location),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: 'Failed to get location',
                  onRetry: () {
                    ref
                        .read(locationNotifierProvider.notifier)
                        .getCurrentLocation();
                  },
                ),
              ),
              const SizedBox(height: AppConfig.defaultPadding),

              // Camera View
              CameraView(
                onImageCaptured: (imagePath) {
                  setState(() {
                    _capturedImages.add(imagePath);
                  });
                },
              ),
              const SizedBox(height: AppConfig.defaultPadding),

              // Empty Checkbox
              CheckboxListTile(
                title: const Text('Trailer is empty'),
                value: _isEmpty,
                onChanged: (value) {
                  setState(() => _isEmpty = value ?? false);
                },
              ),
              const SizedBox(height: AppConfig.defaultPadding * 2),

              // Submit Button
              captureState.isLoading
                  ? const LoadingIndicator()
                  : ElevatedButton(
                      onPressed: _canSubmit() ? _handleSubmit : null,
                      child: const Text('Capture Trailer'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _licensePlateController.text.isNotEmpty &&
        _capturedImages.isNotEmpty &&
        ref.read(locationNotifierProvider).hasValue;
  }

  void _handleSubmit() {
    final location = ref.read(locationNotifierProvider).value;
    if (location == null) return;

    final capture = TrailerCapture(
      id: const Uuid().v4(),
      licensePlate: _licensePlateController.text.trim(),
      terminal: _selectedTerminal,
      location: location,
      timestamp: DateTime.now(),
      photoUrls: [], // Will be filled after upload
      isEmpty: _isEmpty,
    );

    ref.read(captureNotifierProvider.notifier).captureTrailer(
          capture,
          _capturedImages,
        );
  }
}
```

---

## 8. Widget Examples

### Camera Widget

```dart
// features/capture/presentation/widgets/camera_view.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/config/app_config.dart';

class CameraView extends StatefulWidget {
  final Function(String imagePath) onImageCaptured;

  const CameraView({
    super.key,
    required this.onImageCaptured,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      widget.onImageCaptured(image.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConfig.defaultRadius),
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        const SizedBox(height: AppConfig.defaultPadding),
        ElevatedButton.icon(
          onPressed: _takePicture,
          icon: const Icon(Icons.camera),
          label: const Text('Take Photo'),
        ),
      ],
    );
  }
}
```

### Terminal Selector Widget

```dart
// features/capture/presentation/widgets/terminal_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';

class TerminalSelector extends StatelessWidget {
  final String selectedTerminal;
  final ValueChanged<String> onChanged;

  const TerminalSelector({
    super.key,
    required this.selectedTerminal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Terminal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConfig.defaultPadding / 2),
            Wrap(
              spacing: AppConfig.defaultPadding / 2,
              children: AppConfig.availableTerminals.map((terminal) {
                final isSelected = terminal == selectedTerminal;
                return ChoiceChip(
                  label: Text(terminal),
                  selected: isSelected,
                  onSelected: (_) => onChanged(terminal),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 9. API Client

### core/network/api_client.dart
```dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(ApiInterceptor());

    if (AppConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );
    }
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // File upload
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      ...?data,
    });

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }
}
```

### core/network/api_interceptor.dart
```dart
import 'package:dio/dio.dart';
import '../utils/logger.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token if available
    // final token = ... get token from storage
    // options.headers['Authorization'] = 'Bearer $token';

    AppLogger.debug('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    super.onError(err, handler);
  }
}
```

---

## 10. Error Handling

### Showing Errors in UI

```dart
// shared/widgets/error_view.dart
import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../core/config/app_config.dart';

class ErrorView extends StatelessWidget {
  final Failure? failure;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.failure,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? _getErrorMessage();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConfig.defaultPadding),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConfig.defaultPadding * 2),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (failure == null) return 'An error occurred';

    return switch (failure.runtimeType) {
      const (ServerFailure) => 'Server error. Please try again later.',
      const (NetworkFailure) =>
        'No internet connection. Please check your network.',
      const (LocationFailure) => 'Failed to get location. Please enable GPS.',
      const (ValidationFailure) => failure!.message,
      _ => 'An unexpected error occurred.',
    };
  }

  IconData _getErrorIcon() {
    if (failure == null) return Icons.error_outline;

    return switch (failure.runtimeType) {
      const (ServerFailure) => Icons.cloud_off,
      const (NetworkFailure) => Icons.wifi_off,
      const (LocationFailure) => Icons.location_off,
      const (ValidationFailure) => Icons.warning_amber,
      _ => Icons.error_outline,
    };
  }
}
```

### Global Error Handler

```dart
// core/utils/error_handler.dart
import 'package:flutter/material.dart';
import '../errors/failures.dart';

class ErrorHandler {
  static void showError(BuildContext context, Object error) {
    String message;

    if (error is Failure) {
      message = _getFailureMessage(error);
    } else {
      message = 'An unexpected error occurred';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static String _getFailureMessage(Failure failure) {
    return switch (failure.runtimeType) {
      const (ServerFailure) => 'Server error. Please try again later.',
      const (NetworkFailure) => 'No internet connection.',
      const (LocationFailure) => 'Failed to get your location.',
      const (ValidationFailure) => failure.message,
      _ => 'An unexpected error occurred.',
    };
  }
}
```

---

## Build and Run Commands

### Generate code
```bash
# Generate all code (models, providers, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Run with different environments
```bash
# Development
flutter run --dart-define=ENV=development

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=production --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/features/capture/domain/usecases/capture_trailer_test.dart

# Run tests with coverage
flutter test --coverage
```

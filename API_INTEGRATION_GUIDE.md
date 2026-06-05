# API Integration Guide

This guide provides detailed examples for implementing API integrations, data sources, and network handling in the Trailer Management app.

## Table of Contents
1. [API Client Setup](#api-client-setup)
2. [Remote Data Sources](#remote-data-sources)
3. [Local Data Sources](#local-data-sources)
4. [Image Upload](#image-upload)
5. [Location Services](#location-services)
6. [Network Connectivity](#network-connectivity)
7. [Caching Strategy](#caching-strategy)
8. [Error Handling](#error-handling)

---

## API Client Setup

### Base API Client

```dart
// core/network/api_client.dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Custom interceptor
    _dio.interceptors.add(ApiInterceptor());

    // Logging interceptor (only in debug mode)
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );
    }

    // Retry interceptor
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode ?? 0) >= 500;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Dio get dio => _dio;

  // Convenience methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
```

### API Interceptor

```dart
// core/network/api_interceptor.dart
import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../errors/exceptions.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authentication token
    final token = _getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add request ID for tracking
    options.headers['X-Request-ID'] = _generateRequestId();

    AppLogger.debug('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );

    // Handle specific error codes
    if (err.response?.statusCode == 401) {
      // Handle unauthorized - maybe refresh token
      _handleUnauthorized();
    }

    super.onError(err, handler);
  }

  String? _getAuthToken() {
    // Get token from secure storage
    // TODO: Implement token storage
    return null;
  }

  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _handleUnauthorized() {
    // Handle token refresh or logout
    // TODO: Implement
  }
}
```

---

## Remote Data Sources

### Capture Remote Data Source

```dart
// features/capture/data/datasources/capture_remote_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/trailer_capture_model.dart';
import '../models/location_model.dart';

abstract class CaptureRemoteDataSource {
  Future<TrailerCaptureModel> createCapture(TrailerCaptureModel capture);
  Future<List<String>> uploadImages(List<String> imagePaths);
  Future<LocationModel> getCurrentLocation();
  Future<bool> validateLicensePlate(String licensePlate);
}

class CaptureRemoteDataSourceImpl implements CaptureRemoteDataSource {
  final ApiClient apiClient;

  CaptureRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  @override
  Future<TrailerCaptureModel> createCapture(
    TrailerCaptureModel capture,
  ) async {
    try {
      final response = await apiClient.post(
        ApiConstants.captureEndpoint,
        data: capture.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TrailerCaptureModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ServerException(
          'Failed to create capture',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final uploadedUrls = <String>[];

      for (final imagePath in imagePaths) {
        final url = await _uploadSingleImage(imagePath);
        uploadedUrls.add(url);
      }

      return uploadedUrls;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> _uploadSingleImage(String imagePath) async {
    final file = File(imagePath);

    // Compress image before upload
    final compressedFile = await _compressImage(file);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        compressedFile.path,
        filename: compressedFile.path.split('/').last,
      ),
      'type': 'trailer_photo',
    });

    final response = await apiClient.post(
      ApiConstants.uploadEndpoint,
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total * 100).toStringAsFixed(0);
        AppLogger.debug('Upload progress: $progress%');
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } else {
      throw ServerException(
        'Failed to upload image',
        response.statusCode,
      );
    }
  }

  Future<File> _compressImage(File file) async {
    // TODO: Implement image compression
    // Use image package to compress
    return file;
  }

  @override
  Future<LocationModel> getCurrentLocation() async {
    try {
      // This could call a geocoding API or just use device location
      // For now, we'll handle this in the location service
      throw UnimplementedError('Use LocationService instead');
    } catch (e) {
      throw LocationException('Failed to get location: $e');
    }
  }

  @override
  Future<bool> validateLicensePlate(String licensePlate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.trailersEndpoint}/validate',
        queryParameters: {'license_plate': licensePlate},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['valid'] as bool;
      } else {
        throw ServerException(
          'Failed to validate license plate',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';
        return ServerException(message, statusCode);

      case DioExceptionType.cancel:
        return ServerException('Request cancelled');

      default:
        return NetworkException('Network error: ${e.message}');
    }
  }
}
```

### Browse Remote Data Source

```dart
// features/browse/data/datasources/browse_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/trailer_model.dart';

abstract class BrowseRemoteDataSource {
  Future<List<TrailerModel>> getTrailers({
    String? sortBy,
    String? filterBy,
    int page = 1,
    int limit = 20,
  });

  Future<TrailerModel> getTrailerById(String id);
}

class BrowseRemoteDataSourceImpl implements BrowseRemoteDataSource {
  final ApiClient apiClient;

  BrowseRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  @override
  Future<List<TrailerModel>> getTrailers({
    String? sortBy,
    String? filterBy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (sortBy != null) queryParameters['sort'] = sortBy;
      if (filterBy != null) queryParameters['filter'] = filterBy;

      final response = await apiClient.get(
        ApiConstants.trailersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final trailers = data['trailers'] as List;

        return trailers
            .map((json) => TrailerModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to fetch trailers',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TrailerModel> getTrailerById(String id) async {
    try {
      final response = await apiClient.get(
        ApiConstants.trailerDetailEndpoint(id),
      );

      if (response.statusCode == 200) {
        return TrailerModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ServerException(
          'Failed to fetch trailer',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';
        return ServerException(message, statusCode);

      default:
        return NetworkException('Network error: ${e.message}');
    }
  }
}
```

---

## Local Data Sources

### Capture Local Data Source (Hive)

```dart
// features/capture/data/datasources/capture_local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trailer_capture_model.dart';

abstract class CaptureLocalDataSource {
  Future<void> cacheCapture(TrailerCaptureModel capture);
  Future<TrailerCaptureModel?> getCachedCapture(String id);
  Future<List<TrailerCaptureModel>> getCachedCaptures();
  Future<void> saveForSync(TrailerCaptureModel capture);
  Future<List<TrailerCaptureModel>> getPendingSync();
  Future<void> removePendingSync(String id);
  Future<void> clearCache();
}

class CaptureLocalDataSourceImpl implements CaptureLocalDataSource {
  static const String _cacheBoxName = 'trailer_captures_cache';
  static const String _syncBoxName = 'trailer_captures_sync';

  late Box<Map> _cacheBox;
  late Box<Map> _syncBox;

  CaptureLocalDataSourceImpl() {
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<Map>(_cacheBoxName);
    _syncBox = await Hive.openBox<Map>(_syncBoxName);
  }

  @override
  Future<void> cacheCapture(TrailerCaptureModel capture) async {
    try {
      await _cacheBox.put(capture.id, capture.toJson());

      // Remove old entries if cache is too large
      await _cleanOldCache();
    } catch (e) {
      throw CacheException('Failed to cache capture: $e');
    }
  }

  @override
  Future<TrailerCaptureModel?> getCachedCapture(String id) async {
    try {
      final json = _cacheBox.get(id);
      if (json == null) return null;

      return TrailerCaptureModel.fromJson(
        Map<String, dynamic>.from(json),
      );
    } catch (e) {
      throw CacheException('Failed to get cached capture: $e');
    }
  }

  @override
  Future<List<TrailerCaptureModel>> getCachedCaptures() async {
    try {
      return _cacheBox.values
          .map((json) => TrailerCaptureModel.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached captures: $e');
    }
  }

  @override
  Future<void> saveForSync(TrailerCaptureModel capture) async {
    try {
      final syncData = {
        ...capture.toJson(),
        'sync_timestamp': DateTime.now().toIso8601String(),
      };
      await _syncBox.put(capture.id, syncData);
    } catch (e) {
      throw CacheException('Failed to save for sync: $e');
    }
  }

  @override
  Future<List<TrailerCaptureModel>> getPendingSync() async {
    try {
      return _syncBox.values
          .map((json) => TrailerCaptureModel.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get pending sync items: $e');
    }
  }

  @override
  Future<void> removePendingSync(String id) async {
    try {
      await _syncBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to remove pending sync item: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _cacheBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }

  Future<void> _cleanOldCache() async {
    if (_cacheBox.length > AppConfig.maxCacheSize) {
      final keys = _cacheBox.keys.toList();
      final oldKeys = keys.take(keys.length - AppConfig.maxCacheSize);
      await _cacheBox.deleteAll(oldKeys);
    }
  }
}
```

---

## Image Upload

### Image Service

```dart
// core/services/image_service.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import '../utils/logger.dart';

class ImageService {
  Future<File> compressImage(File file) async {
    try {
      // Read image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > AppConfig.maxImageWidth ||
          image.height > AppConfig.maxImageHeight) {
        resized = img.copyResize(
          image,
          width: AppConfig.maxImageWidth,
          height: AppConfig.maxImageHeight,
          maintainAspect: true,
        );
      }

      // Compress
      final compressed = img.encodeJpg(
        resized,
        quality: AppConfig.imageQuality,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${path.basename(file.path)}';
      final compressedFile = File('${tempDir.path}/$fileName');
      await compressedFile.writeAsBytes(compressed);

      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();
      final savedPercent =
          ((originalSize - compressedSize) / originalSize * 100).toInt();

      AppLogger.debug(
        'Image compressed: ${_formatBytes(originalSize)} → '
        '${_formatBytes(compressedSize)} ($savedPercent% saved)',
      );

      return compressedFile;
    } catch (e) {
      AppLogger.error('Failed to compress image: $e');
      return file;
    }
  }

  Future<File> createThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final thumbnail = img.copyResize(
        image,
        width: AppConfig.thumbnailSize,
        height: AppConfig.thumbnailSize,
        maintainAspect: true,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 75);

      final tempDir = await getTemporaryDirectory();
      final fileName = 'thumb_${path.basename(file.path)}';
      final thumbnailFile = File('${tempDir.path}/$fileName');
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      AppLogger.error('Failed to create thumbnail: $e');
      return file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> validateImageSize(File file) async {
    final bytes = await file.length();
    final maxBytes = AppConfig.maxImageSizeMB * 1024 * 1024;
    return bytes <= maxBytes;
  }

  bool validateImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return AppConfig.allowedImageFormats.contains(extension.substring(1));
  }
}
```

---

## Location Services

### Location Service

```dart
// core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/capture/domain/entities/trailer_capture.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

class LocationService {
  Future<Location> getCurrentLocation() async {
    try {
      // Check permission
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        throw LocationException('Location permission denied');
      }

      // Check if location service is enabled
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        throw LocationException('Location service is disabled');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConfig.locationTimeout,
      );

      AppLogger.debug(
        'Location acquired: ${position.latitude}, ${position.longitude} '
        '(accuracy: ${position.accuracy}m)',
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } on TimeoutException {
      throw LocationException('Location request timed out');
    } catch (e) {
      throw LocationException('Failed to get location: $e');
    }
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      AppLogger.warning('Location permission permanently denied');
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<Stream<Location>> watchLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      throw LocationException('Location permission denied');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => Location(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            ));
  }

  Future<double> distanceBetween(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) async {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }
}
```

---

## Network Connectivity

### Network Info

```dart
// core/network/network_info.dart
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
```

---

## Caching Strategy

### Cache Manager

```dart
// core/cache/cache_manager.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class CacheManager {
  static const String _cacheBoxName = 'app_cache';
  late Box<Map> _cacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<Map>(_cacheBoxName);
  }

  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    final cacheData = Map<String, dynamic>.from(cached);
    final timestamp = DateTime.parse(cacheData['timestamp'] as String);

    // Check if cache is expired
    if (DateTime.now().difference(timestamp) > AppConfig.cacheExpiration) {
      await _cacheBox.delete(key);
      return null;
    }

    return fromJson(Map<String, dynamic>.from(cacheData['data']));
  }

  Future<void> put<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final cacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': toJson(data),
    };

    await _cacheBox.put(key, cacheData);
  }

  Future<void> clear() async {
    await _cacheBox.clear();
  }

  Future<void> delete(String key) async {
    await _cacheBox.delete(key);
  }
}
```

---

## Error Handling

### HTTP Error Handler

```dart
// core/network/http_error_handler.dart
import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

class HttpErrorHandler {
  static Exception handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response!);

      case DioExceptionType.cancel:
        return ServerException('Request was cancelled');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException('No internet connection');
        }
        return NetworkException('Unexpected error occurred');

      default:
        return NetworkException('Network error');
    }
  }

  static Exception _handleResponseError(Response response) {
    final statusCode = response.statusCode ?? 0;
    final message = _extractErrorMessage(response.data);

    switch (statusCode) {
      case 400:
        return ServerException('Bad request: $message', statusCode);
      case 401:
        return ServerException('Unauthorized. Please login again.', statusCode);
      case 403:
        return ServerException('Access forbidden', statusCode);
      case 404:
        return ServerException('Resource not found', statusCode);
      case 422:
        return ServerException('Validation error: $message', statusCode);
      case 500:
        return ServerException('Server error. Please try again later.', statusCode);
      case 503:
        return ServerException('Service unavailable', statusCode);
      default:
        return ServerException('Server error ($statusCode)', statusCode);
    }
  }

  static String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      return data['message'] ?? data['error'] ?? 'Unknown error';
    }
    return data?.toString() ?? 'Unknown error';
  }
}
```

---

## Complete Example: Syncing Offline Data

```dart
// core/services/sync_service.dart
import '../network/network_info.dart';
import '../../features/capture/data/datasources/capture_local_datasource.dart';
import '../../features/capture/data/datasources/capture_remote_datasource.dart';
import '../utils/logger.dart';

class SyncService {
  final NetworkInfo networkInfo;
  final CaptureLocalDataSource localDataSource;
  final CaptureRemoteDataSource remoteDataSource;

  SyncService({
    required this.networkInfo,
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> syncPendingCaptures() async {
    if (!await networkInfo.isConnected) {
      AppLogger.info('No internet connection. Sync skipped.');
      return;
    }

    final pending = await localDataSource.getPendingSync();
    AppLogger.info('Syncing ${pending.length} pending captures');

    for (final capture in pending) {
      try {
        await remoteDataSource.createCapture(capture);
        await localDataSource.removePendingSync(capture.id);
        AppLogger.info('Synced capture: ${capture.id}');
      } catch (e) {
        AppLogger.error('Failed to sync capture ${capture.id}: $e');
      }
    }

    AppLogger.info('Sync completed');
  }

  void startAutoSync() {
    networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncPendingCaptures();
      }
    });
  }
}
```

This comprehensive API integration guide provides all the building blocks needed for a robust, offline-capable Flutter application with proper error handling, caching, and network management.

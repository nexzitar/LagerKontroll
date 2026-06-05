import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/environment.dart';
import '../services/navigation_service.dart';
import '../utils/logger.dart';
import '../../features/auth/data/services/auth_storage_service.dart';

/// Dio HTTP client wrapper
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio _dio;

  /// Reference to auth storage for clearing on token expiry
  AuthStorageService? _authStorage;

  /// Callback to clear auth state in Riverpod
  void Function()? _onTokenExpired;

  /// Set auth storage reference (called from main.dart)
  void setAuthStorage(AuthStorageService authStorage) {
    _authStorage = authStorage;
  }

  /// Set callback for token expiry (called from main.dart)
  void setTokenExpiredCallback(void Function() callback) {
    _onTokenExpired = callback;
  }

  /// Initialize Dio with configuration
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.current.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiConnectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiReceiveTimeout),
        sendTimeout: Duration(milliseconds: AppConfig.apiSendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_tokenExpiryInterceptor());
    _dio.interceptors.add(_errorInterceptor());

    logger.info('DioClient initialized with base URL: ${EnvironmentConfig.current.apiBaseUrl}');
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Logging interceptor
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (AppConfig.enableNetworkLogging) {
          logger.logRequest(
            options.method,
            '${options.baseUrl}${options.path}',
            headers: options.headers,
            body: options.data,
          );
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppConfig.enableNetworkLogging) {
          logger.logResponse(
            response.statusCode ?? 0,
            response.requestOptions.uri.toString(),
            data: response.data,
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (AppConfig.enableNetworkLogging) {
          logger.logNetworkError(
            error.requestOptions.uri.toString(),
            error,
            error.stackTrace,
          );
        }
        handler.next(error);
      },
    );
  }

  /// Token expiry interceptor - handles 401 responses with expired token
  Interceptor _tokenExpiryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final data = error.response?.data;
          String? message;

          if (data is Map<String, dynamic>) {
            message = data['message'] as String?;
          }

          // Check for token expiry messages
          final isTokenExpired = message?.toLowerCase().contains('expired') == true ||
              message?.toLowerCase().contains('invalid token') == true ||
              message?.toLowerCase().contains('jwt expired') == true;

          if (isTokenExpired) {
            logger.warning('Token expired detected. Clearing auth and redirecting to login.');

            // Clear stored credentials
            await _authStorage?.clear();

            // Clear token from headers
            clearAuthToken();

            // Notify Riverpod to clear auth state
            _onTokenExpired?.call();

            // Navigate to login and show message
            navigationService.showSnackBar(
              'Session expired. Please log in again.',
            );
            navigationService.navigateToAndClearStack('/login');
          }
        }
        handler.next(error);
      },
    );
  }

  /// Error interceptor
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        logger.error('Dio Error: ${error.message}', error);
        handler.next(error);
      },
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      logger.error('GET request failed: $path', e);
      rethrow;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      logger.error('POST request failed: $path', e);
      rethrow;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      logger.error('PUT request failed: $path', e);
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      logger.error('PATCH request failed: $path', e);
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      logger.error('DELETE request failed: $path', e);
      rethrow;
    }
  }

  /// Upload file with multipart/form-data
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      logger.error('Upload request failed: $path', e);
      rethrow;
    }
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
    } catch (e) {
      logger.error('Download request failed: $urlPath', e);
      rethrow;
    }
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    logger.debug('Auth token set');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    logger.debug('Auth token cleared');
  }
}

/// Global Dio client instance
final dioClient = DioClient();

/// Riverpod provider for DioClient
final dioClientProvider = Provider<DioClient>((ref) => dioClient);

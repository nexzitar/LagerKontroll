import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// Application logger wrapper
/// Singleton pattern for global access
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  /// Initialize the logger
  void init() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: AppConfig.enableDebugLogging ? Level.debug : Level.info,
    );
  }

  /// Log debug message
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableDebugLogging) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical message
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request
  void logRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    if (AppConfig.enableNetworkLogging) {
      debug('[$method] $url');
      if (headers != null) debug('Headers: $headers');
      if (body != null) debug('Body: $body');
    }
  }

  /// Log network response
  void logResponse(int statusCode, String url, {dynamic data}) {
    if (AppConfig.enableNetworkLogging) {
      debug('Response [$statusCode] $url');
      if (data != null) debug('Data: $data');
    }
  }

  /// Log network error
  void logNetworkError(String url, dynamic error, [StackTrace? stackTrace]) {
    if (AppConfig.enableNetworkLogging) {
      this.error('Network Error: $url', error, stackTrace);
    }
  }
}

/// Global logger instance
final logger = AppLogger();

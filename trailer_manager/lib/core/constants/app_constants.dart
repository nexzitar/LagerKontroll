/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // =========================
  // App Information
  // =========================

  static const String appName = 'Trailer Manager';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // =========================
  // Terminal Names
  // =========================

  /// Get terminal display name (just returns the code as-is for consistency)
  static String getTerminalName(String code) {
    return code;
  }

  // =========================
  // Storage Box Names (Hive)
  // =========================

  static const String trailersBoxName = 'trailers';
  static const String entriesBoxName = 'entries';
  static const String settingsBoxName = 'settings';
  static const String cacheBoxName = 'cache';

  // =========================
  // File Constraints
  // =========================

  /// Supported image MIME types
  static const List<String> supportedImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/jpg',
  ];

  /// Supported image file extensions
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
  ];

  // =========================
  // Validation Rules
  // =========================

  /// Trailer number validation regex (alphanumeric with hyphens)
  static final RegExp trailerNumberRegex = RegExp(r'^[A-Z0-9\-]+$');

  /// Latitude bounds
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;

  /// Longitude bounds
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  // =========================
  // Date Formats
  // =========================

  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'HH:mm';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';

  // =========================
  // HTTP Status Codes
  // =========================

  static const int httpOk = 200;
  static const int httpCreated = 201;
  static const int httpNoContent = 204;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpConflict = 409;
  static const int httpUnprocessableEntity = 422;
  static const int httpTooManyRequests = 429;
  static const int httpInternalServerError = 500;
  static const int httpBadGateway = 502;
  static const int httpServiceUnavailable = 503;

  // =========================
  // Error Messages
  // =========================

  static const String networkErrorMessage = 'No internet connection';
  static const String serverErrorMessage = 'Server error occurred';
  static const String unknownErrorMessage = 'An unknown error occurred';
  static const String timeoutErrorMessage = 'Request timed out';
  static const String cacheErrorMessage = 'Cache error occurred';
  static const String validationErrorMessage = 'Validation error';

  // =========================
  // Success Messages
  // =========================

  static const String entryCreatedMessage = 'Entry created successfully';
  static const String entryUpdatedMessage = 'Entry updated successfully';
  static const String imageUploadedMessage = 'Image uploaded successfully';

  // =========================
  // Asset Paths
  // =========================

  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';

  /// Placeholder image for when photo fails to load
  static const String placeholderImage = '${imagesPath}placeholder.png';
}

/// Application configuration - NO MAGIC NUMBERS
/// All configurable constants are defined here for easy modification
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // =========================
  // API Configuration
  // =========================

  /// API base URL - change based on environment
  static const String apiBaseUrl = 'https://lassi.cloud/v1';

  /// API connection timeout in milliseconds
  static const int apiConnectTimeout = 30000; // 30 seconds

  /// API receive timeout in milliseconds
  static const int apiReceiveTimeout = 30000; // 30 seconds

  /// API send timeout in milliseconds
  static const int apiSendTimeout = 60000; // 60 seconds (for file uploads)

  /// Maximum retry attempts for failed requests
  static const int apiMaxRetries = 3;

  /// Delay between retries in milliseconds
  static const int apiRetryDelay = 1000; // 1 second

  // =========================
  // Image Configuration
  // =========================

  /// Maximum image file size in bytes (10 MB)
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  /// JPEG compression quality (0-100)
  static const int imageQuality = 85;

  /// Maximum image width for upload
  static const int maxImageWidth = 1920;

  /// Maximum image height for upload
  static const int maxImageHeight = 1920;

  /// Thumbnail width
  static const int thumbnailWidth = 200;

  /// Thumbnail height
  static const int thumbnailHeight = 200;

  /// Supported image formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // =========================
  // Location Configuration
  // =========================

  /// Location accuracy in meters
  static const double locationAccuracyMeters = 10.0;

  /// Location request timeout in seconds
  static const int locationTimeoutSeconds = 30;

  /// Minimum distance between location updates in meters
  static const double locationDistanceFilter = 10.0;

  /// Location update interval in milliseconds
  static const int locationUpdateInterval = 5000; // 5 seconds

  // =========================
  // History Configuration
  // =========================

  /// Default number of history entries to show
  static const int defaultHistoryCount = 10;

  /// Minimum history count
  static const int minHistoryCount = 5;

  /// Maximum history count
  static const int maxHistoryCount = 50;

  // =========================
  // Pagination Configuration
  // =========================

  /// Default page size for lists
  static const int defaultPageSize = 20;

  /// Maximum page size
  static const int maxPageSize = 100;

  // =========================
  // Cache Configuration
  // =========================

  /// Cache expiration time in milliseconds (5 minutes)
  static const int cacheExpirationMs = 5 * 60 * 1000;

  /// Maximum cache size in bytes (50 MB)
  static const int maxCacheSizeBytes = 50 * 1024 * 1024;

  /// Cache image expiration in days
  static const int cacheImageExpirationDays = 30;

  // =========================
  // Map Configuration
  // =========================

  /// Default map zoom level
  static const double defaultMapZoom = 15.0;

  /// Map zoom for detail view
  static const double detailMapZoom = 17.0;

  /// Marker size
  static const double markerSize = 40.0;

  /// Map update interval in milliseconds
  static const int mapUpdateInterval = 1000; // 1 second

  // =========================
  // UI Configuration
  // =========================

  /// Default animation duration in milliseconds
  static const int defaultAnimationDuration = 300;

  /// Fast animation duration in milliseconds
  static const int fastAnimationDuration = 150;

  /// Slow animation duration in milliseconds
  static const int slowAnimationDuration = 500;

  /// Default border radius
  static const double defaultBorderRadius = 8.0;

  /// Card border radius
  static const double cardBorderRadius = 12.0;

  /// Button border radius
  static const double buttonBorderRadius = 8.0;

  /// Default padding
  static const double defaultPadding = 16.0;

  /// Small padding
  static const double smallPadding = 8.0;

  /// Large padding
  static const double largePadding = 24.0;

  /// List item height
  static const double listItemHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  // =========================
  // Validation Configuration
  // =========================

  /// Minimum trailer number length
  static const int minTrailerNumberLength = 3;

  /// Maximum trailer number length
  static const int maxTrailerNumberLength = 20;

  /// Maximum notes length
  static const int maxNotesLength = 500;

  // =========================
  // Storage Keys
  // =========================

  /// Key for storing auth token
  static const String authTokenKey = 'auth_token';

  /// Key for storing refresh token
  static const String refreshTokenKey = 'refresh_token';

  /// Key for storing user data
  static const String userDataKey = 'user_data';

  /// Key for storing app settings
  static const String appSettingsKey = 'app_settings';

  /// Key for storing history count preference
  static const String historyCountKey = 'history_count';

  /// Key for storing theme preference
  static const String themeKey = 'theme_preference';

  // =========================
  // Terminal Configuration
  // =========================

  /// Available terminals (easily extensible)
  static const List<String> terminals = ['B1', 'B2', 'B3', 'B4', 'B5', 'ØT'];

  /// LSO terminals (all B terminals, excluding ØT)
  static const List<String> lsoTerminals = ['B1', 'B2', 'B3', 'B4', 'B5'];

  /// Default terminal
  static const String defaultTerminal = 'B1';

  // =========================
  // Logging Configuration
  // =========================

  /// Enable debug logging
  static const bool enableDebugLogging = true;

  /// Enable network logging
  static const bool enableNetworkLogging = true;

  /// Log file maximum size in bytes (10 MB)
  static const int maxLogFileSize = 10 * 1024 * 1024;
}

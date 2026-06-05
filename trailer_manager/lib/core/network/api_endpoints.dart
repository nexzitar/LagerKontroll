/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // =========================
  // Authentication
  // =========================
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // =========================
  // Trailers
  // =========================
  static const String trailers = '/trailers';
  
  /// Get specific trailer by ID
  static String trailerById(String id) => '/trailers/$id';
  
  /// Get trailer entries/history
  static String trailerEntries(String id) => '/trailers/$id/entries';
  
  /// Update trailer status
  static String updateTrailerStatus(String id) => '/trailers/$id/status';

  // =========================
  // Images
  // =========================
  static const String uploadImage = '/images/upload';
  
  /// Get image by ID
  static String imageById(String id) => '/images/$id';

  // =========================
  // Terminals
  // =========================
  static const String terminals = '/terminals';
  
  /// Create terminal (admin only)
  static const String createTerminal = '/terminals';

  // =========================
  // Health
  // =========================
  static const String health = '/health';
}

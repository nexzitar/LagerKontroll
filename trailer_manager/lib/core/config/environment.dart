/// Environment configuration for different deployment stages
enum Environment {
  development,
  staging,
  production,
}

/// Environment-specific configuration
class EnvironmentConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String apiKey;
  final bool enableLogging;
  final bool enableAnalytics;

  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiKey,
    required this.enableLogging,
    required this.enableAnalytics,
  });

  /// Development environment configuration
  static const EnvironmentConfig development = EnvironmentConfig(
    environment: Environment.development,
    apiBaseUrl: 'http://lassi.cloud:3000/api/v1',
    apiKey: 'dev-api-key',
    enableLogging: true,
    enableAnalytics: false,
  );

  /// Staging environment configuration
  static const EnvironmentConfig staging = EnvironmentConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.yourdomain.com/v1',
    apiKey: 'staging-api-key',
    enableLogging: true,
    enableAnalytics: true,
  );

  /// Production environment configuration
  static const EnvironmentConfig production = EnvironmentConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.yourdomain.com/v1',
    apiKey: 'production-api-key',
    enableLogging: false,
    enableAnalytics: true,
  );

  /// Current environment (change this to switch environments)
  static EnvironmentConfig current = development;

  /// Get current environment name
  String get environmentName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Check if running in production
  bool get isProduction => environment == Environment.production;

  /// Check if running in development
  bool get isDevelopment => environment == Environment.development;

  /// Check if running in staging
  bool get isStaging => environment == Environment.staging;
}

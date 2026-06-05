/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => 'AppException: $message${statusCode != null ? ' (Code: $statusCode)' : ''}';
}

/// Exception when server returns an error
class ServerException extends AppException {
  const ServerException(String message, [int? statusCode]) 
      : super(message, statusCode);
}

/// Exception when network connection fails
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection']) 
      : super(message);
}

/// Exception when cache operation fails
class CacheException extends AppException {
  const CacheException([String message = 'Cache operation failed']) 
      : super(message);
}

/// Exception when validation fails
class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

/// Exception when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException([String message = 'Authentication failed']) 
      : super(message, 401);
}

/// Exception when authorization fails
class AuthorizationException extends AppException {
  const AuthorizationException([String message = 'Access denied']) 
      : super(message, 403);
}

/// Exception when resource is not found
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found']) 
      : super(message, 404);
}

/// Exception when timeout occurs
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timed out']) 
      : super(message);
}

/// Exception when location services fail
class LocationException extends AppException {
  const LocationException(String message) : super(message);
}

/// Exception when permission is denied
class PermissionException extends AppException {
  const PermissionException(String message) : super(message);
}

/// Exception when file operation fails
class FileException extends AppException {
  const FileException(String message) : super(message);
}

/// Exception when parsing fails
class ParsingException extends AppException {
  const ParsingException([String message = 'Failed to parse data']) 
      : super(message);
}

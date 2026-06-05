import 'package:equatable/equatable.dart';

/// Base class for all failures
/// Used with dartz Either<Failure, Success> pattern
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

/// Failure when network connection is unavailable
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) 
      : super(message);
}

/// Failure when server returns an error
class ServerFailure extends Failure {
  const ServerFailure(String message, [int? code]) : super(message, code);
}

/// Failure when cache operation fails
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) 
      : super(message);
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Failure when authentication fails
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed']) 
      : super(message, 401);
}

/// Failure when authorization fails
class AuthorizationFailure extends Failure {
  const AuthorizationFailure([String message = 'Access denied']) 
      : super(message, 403);
}

/// Failure when resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) 
      : super(message, 404);
}

/// Failure when timeout occurs
class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request timed out']) 
      : super(message);
}

/// Failure when location services fail
class LocationFailure extends Failure {
  const LocationFailure(String message) : super(message);
}

/// Failure when permission is denied
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Failure when file operation fails
class FileFailure extends Failure {
  const FileFailure(String message) : super(message);
}

/// Generic failure for unknown errors
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred']) 
      : super(message);
}

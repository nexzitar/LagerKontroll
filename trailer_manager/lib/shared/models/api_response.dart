import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'api_response.g.dart';

/// Generic API response wrapper that handles success and error responses.
///
/// The generic type [T] represents the data type contained in the response.
/// Use [ApiResponse<List<TrailerModel>>] for list responses,
/// [ApiResponse<TrailerModel>] for single item responses, etc.
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.metadata,
  });

  /// Creates an ApiResponse from JSON.
  ///
  /// The [fromJsonT] parameter is a function that converts JSON to type [T].
  /// Example usage:
  /// ```dart
  /// ApiResponse<TrailerModel>.fromJson(
  ///   json,
  ///   (data) => TrailerModel.fromJson(data as Map<String, dynamic>),
  /// );
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  /// Converts this ApiResponse to JSON.
  ///
  /// The [toJsonT] parameter is a function that converts type [T] to JSON.
  /// Example usage:
  /// ```dart
  /// response.toJson((data) => data.toJson());
  /// ```
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  @override
  List<Object?> get props => [success, data, message, error, metadata];

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, error: $error, hasData: ${data != null})';
  }

  /// Creates a successful response with data.
  factory ApiResponse.success({
    required T data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      metadata: metadata,
    );
  }

  /// Creates an error response.
  factory ApiResponse.failure({
    required String error,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      metadata: metadata,
    );
  }

  /// Returns true if the response is successful and has data.
  bool get hasData => success && data != null;

  /// Returns true if the response is an error.
  bool get isError => !success;
}

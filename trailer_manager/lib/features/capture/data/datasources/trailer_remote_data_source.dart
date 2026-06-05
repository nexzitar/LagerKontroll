import 'dart:io';
import 'package:trailer_manager/features/capture/data/models/trailer_entry_model.dart';

/// Remote data source for trailer capture operations
///
/// This interface defines methods for interacting with the remote API
/// to create trailer entries and upload images.
abstract class TrailerRemoteDataSource {
  /// Creates a new trailer entry on the remote server
  ///
  /// Throws:
  /// - [ServerException] if the server returns an error
  /// - [NetworkException] if there's a network connectivity issue
  /// - [ValidationException] if the input data is invalid
  /// - [TimeoutException] if the request times out
  Future<TrailerEntryModel> createEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    required String photoUrl,
    required String thumbnailUrl,
    String? notes,
  });

  /// Uploads an image to the remote server and returns the URL
  ///
  /// Throws:
  /// - [ServerException] if the server returns an error
  /// - [NetworkException] if there's a network connectivity issue
  /// - [StorageException] if the file cannot be read
  /// - [TimeoutException] if the request times out
  Future<String> uploadImage(File image);
}

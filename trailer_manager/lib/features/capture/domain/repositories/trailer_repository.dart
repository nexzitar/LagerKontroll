import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trailer_entry.dart';

/// Repository interface for trailer operations
abstract class TrailerRepository {
  /// Create a new trailer entry
  /// Returns Either<Failure, TrailerEntry>
  Future<Either<Failure, TrailerEntry>> createEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    bool isInRamp = false,
    String? rampNumber,
    required double latitude,
    required double longitude,
    String? address,
    required File photo,
    String? notes,
  });

  /// Upload an image
  /// Returns Either<Failure, String> where String is the image URL
  Future<Either<Failure, String>> uploadImage(File image);
}

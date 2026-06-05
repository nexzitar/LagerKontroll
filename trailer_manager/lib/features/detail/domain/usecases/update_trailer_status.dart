import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../repositories/trailer_detail_repository.dart';

/// Use case for updating trailer status (mark as empty or update location)
class UpdateTrailerStatus {
  final TrailerDetailRepository repository;

  UpdateTrailerStatus(this.repository);

  /// Execute the use case
  Future<Either<Failure, TrailerEntry>> call({
    required String trailerId,
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    bool isInRamp = false,
    String? rampNumber,
    String? address,
    String? notes,
  }) async {
    // Validate inputs
    final validationFailure = _validateInputs(
      trailerId: trailerId,
      trailerNumber: trailerNumber,
      terminal: terminal,
      latitude: latitude,
      longitude: longitude,
    );

    if (validationFailure != null) {
      return Left(validationFailure);
    }

    logger.debug('Updating trailer status: $trailerNumber (isEmpty: $isEmpty, isInRamp: $isInRamp)');

    return await repository.updateTrailerStatus(
      trailerId: trailerId,
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      isInRamp: isInRamp,
      rampNumber: rampNumber,
      latitude: latitude,
      longitude: longitude,
      address: address,
      notes: notes,
    );
  }

  /// Validate all inputs
  ValidationFailure? _validateInputs({
    required String trailerId,
    required String trailerNumber,
    required String terminal,
    required double latitude,
    required double longitude,
  }) {
    if (trailerId.isEmpty) {
      return const ValidationFailure('Trailer ID cannot be empty');
    }

    if (trailerNumber.isEmpty) {
      return const ValidationFailure('Trailer number cannot be empty');
    }

    if (terminal.isEmpty) {
      return const ValidationFailure('Terminal cannot be empty');
    }

    if (latitude < -90 || latitude > 90) {
      return const ValidationFailure('Invalid latitude value');
    }

    if (longitude < -180 || longitude > 180) {
      return const ValidationFailure('Invalid longitude value');
    }

    return null;
  }
}

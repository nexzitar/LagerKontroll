import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../entities/trailer_entry.dart';
import '../repositories/trailer_repository.dart';

/// Use case for creating a new trailer entry
class CreateTrailerEntry {
  final TrailerRepository repository;

  CreateTrailerEntry(this.repository);

  /// Execute the use case
  Future<Either<Failure, TrailerEntry>> call({
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
  }) async {
    // Validate inputs
    final validationFailure = _validateInputs(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isInRamp: isInRamp,
      rampNumber: rampNumber,
      latitude: latitude,
      longitude: longitude,
      photo: photo,
      notes: notes,
    );

    if (validationFailure != null) {
      return Left(validationFailure);
    }

    // Create entry through repository
    logger.debug('Creating trailer entry: $trailerNumber');
    return await repository.createEntry(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      isInRamp: isInRamp,
      rampNumber: rampNumber,
      latitude: latitude,
      longitude: longitude,
      address: address,
      photo: photo,
      notes: notes,
    );
  }

  /// Validate all inputs
  ValidationFailure? _validateInputs({
    required String trailerNumber,
    required String terminal,
    required bool isInRamp,
    String? rampNumber,
    required double latitude,
    required double longitude,
    required File photo,
    String? notes,
  }) {
    // Validate trailer number
    if (trailerNumber.isEmpty) {
      return const ValidationFailure('Trailer number cannot be empty');
    }

    if (trailerNumber.length < AppConfig.minTrailerNumberLength) {
      return ValidationFailure(
        'Trailer number must be at least ${AppConfig.minTrailerNumberLength} characters',
      );
    }

    if (trailerNumber.length > AppConfig.maxTrailerNumberLength) {
      return ValidationFailure(
        'Trailer number must be at most ${AppConfig.maxTrailerNumberLength} characters',
      );
    }

    // Validate terminal
    if (!AppConfig.terminals.contains(terminal)) {
      return ValidationFailure('Invalid terminal: $terminal');
    }

    // Validate ramp number if in ramp
    if (isInRamp && (rampNumber == null || rampNumber.trim().isEmpty)) {
      return const ValidationFailure('Ramp number is required when trailer is in ramp');
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      return const ValidationFailure('Invalid latitude');
    }

    if (longitude < -180 || longitude > 180) {
      return const ValidationFailure('Invalid longitude');
    }

    // Validate photo
    if (!photo.existsSync()) {
      return const ValidationFailure('Photo file does not exist');
    }

    // Validate notes length
    if (notes != null && notes.length > AppConfig.maxNotesLength) {
      return ValidationFailure(
        'Notes must be at most ${AppConfig.maxNotesLength} characters',
      );
    }

    return null;
  }
}

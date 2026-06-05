import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/utils/mock_data.dart';
import '../../domain/entities/trailer_entry.dart';
import '../../domain/repositories/trailer_repository.dart';

/// Mock implementation of TrailerRepository for testing without backend
/// This bypasses network checks and simulates successful operations
class TrailerRepositoryMock implements TrailerRepository {
  @override
  Future<Either<Failure, TrailerEntry>> createEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    String? address,
    required File photo,
    String? notes,
    bool isInRamp = false,
    String? rampNumber,
  }) async {
    try {
      logger.debug('Creating trailer entry (mock mode)...');

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate mock entry with provided data
      final entry = MockData.generateMockEntry(
        trailerNumber: trailerNumber,
        terminal: terminal,
        isEmpty: isEmpty,
        latitude: latitude,
        longitude: longitude,
        address: address,
        notes: notes,
      );

      logger.info('Trailer entry created successfully (mock): $trailerNumber');
      return Right(entry);
    } catch (e, stackTrace) {
      logger.error('Error creating entry (mock)', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File image) async {
    try {
      logger.debug('Uploading image (mock mode)...');

      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Return mock image URL
      final mockUrl = 'https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}';

      logger.info('Image uploaded successfully (mock): $mockUrl');
      return Right(mockUrl);
    } catch (e, stackTrace) {
      logger.error('Error uploading image (mock)', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }
}

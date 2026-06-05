import 'package:dartz/dartz.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../entities/history_response.dart';
import '../repositories/trailer_detail_repository.dart';

/// Use case for getting trailer history with pagination
class GetTrailerHistory {
  final TrailerDetailRepository repository;

  GetTrailerHistory(this.repository);

  /// Execute the use case
  Future<Either<Failure, HistoryResponse>> call(
    String trailerId, {
    int? limit,
    int? offset,
  }) async {
    if (trailerId.isEmpty) {
      return const Left(ValidationFailure('Trailer ID cannot be empty'));
    }

    final historyLimit = limit ?? AppConfig.defaultHistoryCount;
    final historyOffset = offset ?? 0;

    if (historyLimit < AppConfig.minHistoryCount ||
        historyLimit > AppConfig.maxHistoryCount) {
      return Left(ValidationFailure(
        'History limit must be between ${AppConfig.minHistoryCount} and ${AppConfig.maxHistoryCount}',
      ));
    }

    if (historyOffset < 0) {
      return const Left(ValidationFailure('Offset cannot be negative'));
    }

    logger.debug('Getting history for trailer: $trailerId (limit: $historyLimit, offset: $historyOffset)');
    return await repository.getTrailerHistory(trailerId, historyLimit, historyOffset);
  }
}

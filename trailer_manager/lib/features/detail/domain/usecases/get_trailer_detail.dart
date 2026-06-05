import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../browse/domain/entities/trailer.dart';
import '../repositories/trailer_detail_repository.dart';

/// Use case for getting detailed trailer information
class GetTrailerDetail {
  final TrailerDetailRepository repository;

  GetTrailerDetail(this.repository);

  /// Execute the use case
  Future<Either<Failure, Trailer>> call(String trailerId) async {
    if (trailerId.isEmpty) {
      return const Left(ValidationFailure('Trailer ID cannot be empty'));
    }

    logger.debug('Getting trailer detail for: $trailerId');
    return await repository.getTrailerById(trailerId);
  }
}

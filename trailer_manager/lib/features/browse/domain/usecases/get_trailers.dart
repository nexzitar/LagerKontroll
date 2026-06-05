import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../entities/trailer.dart';
import '../repositories/trailer_list_repository.dart';

/// Use case for getting list of trailers
class GetTrailers {
  final TrailerListRepository repository;

  GetTrailers(this.repository);

  /// Execute the use case with optional filters
  Future<Either<Failure, List<Trailer>>> call({
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 1000,
  }) async {
    logger.debug('Getting trailers (page: $page, limit: $limit)');

    return await repository.getTrailers(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
    );
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../entities/trailer.dart';
import '../repositories/trailer_list_repository.dart';

/// Use case for searching trailers by query
class SearchTrailers {
  final TrailerListRepository repository;

  SearchTrailers(this.repository);

  /// Execute search
  Future<Either<Failure, List<Trailer>>> call(String query) async {
    // Validate query
    if (query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }

    logger.debug('Searching trailers with query: $query');
    return await repository.searchTrailers(query.trim().toUpperCase());
  }
}

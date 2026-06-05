import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trailer.dart';

/// Repository interface for browsing trailers
abstract class TrailerListRepository {
  /// Get list of trailers with optional filters
  Future<Either<Failure, List<Trailer>>> getTrailers({
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  });

  /// Search trailers by trailer number
  Future<Either<Failure, List<Trailer>>> searchTrailers(String query);

  /// Get cached trailers (offline support)
  Future<Either<Failure, List<Trailer>>> getCachedTrailers();
}

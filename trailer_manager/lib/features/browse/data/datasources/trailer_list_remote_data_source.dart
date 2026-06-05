import 'package:trailer_manager/features/browse/data/models/trailer_model.dart';
import 'package:trailer_manager/features/browse/domain/repositories/trailer_list_repository.dart';

/// Remote data source for browsing trailers
///
/// This interface defines methods for retrieving trailer lists from the remote API
/// with filtering, sorting, and pagination support.
abstract class TrailerListRemoteDataSource {
  /// Gets a list of trailers from the remote server
  ///
  /// Parameters:
  /// - [filters]: Optional filters to apply
  /// - [sortBy]: How to sort the results
  /// - [sortDirection]: Sort direction
  /// - [page]: Page number for pagination
  /// - [limit]: Number of items per page
  ///
  /// Throws:
  /// - [ServerException] if the server returns an error
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ParseException] if the response cannot be parsed
  Future<List<TrailerModel>> getTrailers({
    TrailerFilters? filters,
    required TrailerSortBy sortBy,
    required SortDirection sortDirection,
    required int page,
    required int limit,
  });
}

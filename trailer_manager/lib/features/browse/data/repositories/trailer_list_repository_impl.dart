import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/trailer.dart';
import '../../domain/repositories/trailer_list_repository.dart';
import '../datasources/trailer_list_local_datasource.dart';
import '../datasources/trailer_list_remote_datasource.dart';

/// Implementation of TrailerListRepository
class TrailerListRepositoryImpl implements TrailerListRepository {
  final TrailerListRemoteDataSource remoteDataSource;
  final TrailerListLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TrailerListRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
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
  }) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        logger.warning('No network connection, returning cached data');
        
        // Try to return cached data
        try {
          final cachedTrailers = await localDataSource.getCachedTrailers();
          if (cachedTrailers.isNotEmpty) {
            logger.info('Returning ${cachedTrailers.length} cached trailers');
            return Right(cachedTrailers);
          }
        } catch (e) {
          logger.error('Failed to get cached data', e);
        }
        
        return const Left(NetworkFailure('No internet connection and no cached data available'));
      }

      // Fetch from remote
      final trailers = await remoteDataSource.getTrailers(
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

      // Cache the results (only for first page without filters)
      if (page == 1 && 
          trailerNumber == null && 
          terminal == null && 
          isEmpty == null) {
        try {
          await localDataSource.cacheTrailers(trailers);
          logger.debug('Trailers cached successfully');
        } catch (e) {
          logger.warning('Failed to cache trailers', e);
          // Don't fail the request if caching fails
        }
      }

      return Right(trailers);
    } on NetworkException {
      logger.warning('Network exception, trying cache');
      
      // Try cached data
      try {
        final cachedTrailers = await localDataSource.getCachedTrailers();
        if (cachedTrailers.isNotEmpty) {
          return Right(cachedTrailers);
        }
      } catch (e) {
        logger.error('Failed to get cached data', e);
      }
      
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      logger.error('Server exception: ${e.message}');
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      logger.warning('Request timeout');
      return const Left(TimeoutFailure());
    } catch (e, stackTrace) {
      logger.error('Unexpected error getting trailers', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trailer>>> searchTrailers(String query) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      final trailers = await remoteDataSource.getTrailers(
        trailerNumber: query,
        limit: 50,
      );

      return Right(trailers);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trailer>>> getCachedTrailers() async {
    try {
      final trailers = await localDataSource.getCachedTrailers();
      return Right(trailers);
    } on CacheException catch (e) {
      logger.error('Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../browse/domain/entities/trailer.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../../domain/entities/history_response.dart';
import '../../domain/repositories/trailer_detail_repository.dart';
import '../datasources/trailer_detail_remote_datasource.dart';

/// Implementation of TrailerDetailRepository
class TrailerDetailRepositoryImpl implements TrailerDetailRepository {
  final TrailerDetailRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TrailerDetailRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Trailer>> getTrailerById(String id) async {
    try {
      if (!await networkInfo.isConnected) {
        logger.warning('No network connection');
        return const Left(NetworkFailure());
      }

      final trailer = await remoteDataSource.getTrailerById(id);
      return Right(trailer);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        logger.error('Trailer not found: $id');
        return const Left(NotFoundFailure('Trailer not found'));
      }
      logger.error('Server exception: ${e.message}');
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      logger.warning('Request timeout');
      return const Left(TimeoutFailure());
    } catch (e, stackTrace) {
      logger.error('Unexpected error getting trailer detail', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HistoryResponse>> getTrailerHistory(
    String trailerId,
    int limit,
    int offset,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        logger.warning('No network connection');
        return const Left(NetworkFailure());
      }

      final response = await remoteDataSource.getTrailerHistory(trailerId, limit, offset);
      return Right(response);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      logger.error('Server exception: ${e.message}');
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      logger.warning('Request timeout');
      return const Left(TimeoutFailure());
    } catch (e, stackTrace) {
      logger.error('Unexpected error getting trailer history', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrailerEntry>> updateTrailerStatus({
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
    try {
      if (!await networkInfo.isConnected) {
        logger.warning('No network connection');
        return const Left(NetworkFailure('No internet connection'));
      }

      final entry = await remoteDataSource.updateTrailerStatus(
        trailerId: trailerId,
        terminal: terminal,
        isEmpty: isEmpty,
        isInRamp: isInRamp,
        rampNumber: rampNumber,
        latitude: latitude,
        longitude: longitude,
        address: address,
        notes: notes,
      );
      return Right(entry);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      logger.error('Server exception: ${e.message}');
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      logger.warning('Request timeout');
      return const Left(TimeoutFailure());
    } catch (e, stackTrace) {
      logger.error('Unexpected error updating trailer status', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }
}

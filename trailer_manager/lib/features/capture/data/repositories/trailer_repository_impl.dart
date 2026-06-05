import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/image_compression.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/trailer_entry.dart';
import '../../domain/repositories/trailer_repository.dart';
import '../datasources/trailer_remote_datasource.dart';

/// Implementation of TrailerRepository
class TrailerRepositoryImpl implements TrailerRepository {
  final TrailerRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TrailerRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TrailerEntry>> createEntry({
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
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        logger.warning('No network connection');
        return const Left(NetworkFailure('No internet connection. Please check your network.'));
      }

      // Validate image
      final isValid = await ImageCompression.validateImage(photo);
      if (!isValid) {
        return const Left(ValidationFailure('Invalid image file'));
      }

      // Compress image before uploading
      logger.debug('Compressing image...');
      final compressedPhoto = await ImageCompression.compressImage(photo);

      // Create trailer entry
      final entry = await remoteDataSource.createTrailerEntry(
        trailerNumber: trailerNumber,
        terminal: terminal,
        isEmpty: isEmpty,
        isInRamp: isInRamp,
        rampNumber: rampNumber,
        latitude: latitude,
        longitude: longitude,
        address: address,
        photo: compressedPhoto,
        notes: notes,
      );

      logger.info('Trailer entry created successfully');
      return Right(entry);
    } on NetworkException {
      logger.warning('Network exception occurred');
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      logger.error('Server exception: ${e.message}');
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      logger.warning('Request timeout');
      return const Left(TimeoutFailure());
    } on ValidationException catch (e) {
      logger.warning('Validation exception: ${e.message}');
      return Left(ValidationFailure(e.message));
    } catch (e, stackTrace) {
      logger.error('Unexpected error creating entry', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File image) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      // Validate and compress image
      final isValid = await ImageCompression.validateImage(image);
      if (!isValid) {
        return const Left(ValidationFailure('Invalid image file'));
      }

      final compressedImage = await ImageCompression.compressImage(image);

      // Upload image
      final imageUrl = await remoteDataSource.uploadImage(compressedImage);

      return Right(imageUrl);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/trailer_entry_model.dart';

/// Remote data source for trailer operations
abstract class TrailerRemoteDataSource {
  Future<TrailerEntryModel> createTrailerEntry({
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
  });

  Future<String> uploadImage(File image);
}

/// Implementation of TrailerRemoteDataSource
class TrailerRemoteDataSourceImpl implements TrailerRemoteDataSource {
  final DioClient client;

  TrailerRemoteDataSourceImpl(this.client);

  @override
  Future<TrailerEntryModel> createTrailerEntry({
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
      logger.debug('Creating trailer entry for: $trailerNumber');

      // Create multipart form data
      final formData = FormData.fromMap({
        'trailerNumber': trailerNumber,
        'terminal': terminal,
        'isEmpty': isEmpty,
        'isInRamp': isInRamp,
        if (rampNumber != null) 'rampNumber': rampNumber,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await client.upload(
        ApiEndpoints.trailers,
        formData: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        logger.info('Trailer entry created successfully');
        return TrailerEntryModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to create trailer entry', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error creating trailer entry', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutException();
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          e.response?.data?['message'] ?? 'Server error',
          e.response?.statusCode,
        );
      } else {
        throw ServerException(e.message ?? 'Unknown error');
      }
    } catch (e) {
      logger.error('Unexpected error creating trailer entry', e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadImage(File image) async {
    try {
      logger.debug('Uploading image: ${image.path}');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await client.upload(
        ApiEndpoints.uploadImage,
        formData: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final imageUrl = response.data['url'] as String;
        logger.info('Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        throw ServerException('Failed to upload image', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error uploading image', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutException();
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          e.response?.data?['message'] ?? 'Server error',
          e.response?.statusCode,
        );
      } else {
        throw ServerException(e.message ?? 'Unknown error');
      }
    } catch (e) {
      logger.error('Unexpected error uploading image', e);
      throw ServerException(e.toString());
    }
  }
}

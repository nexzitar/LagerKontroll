import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../browse/data/models/trailer_model.dart';
import '../../../capture/data/models/trailer_entry_model.dart';
import '../../domain/entities/history_response.dart';

/// Remote data source for trailer detail operations
abstract class TrailerDetailRemoteDataSource {
  Future<TrailerModel> getTrailerById(String id);
  Future<HistoryResponse> getTrailerHistory(String trailerId, int limit, int offset);
  Future<TrailerEntryModel> createTrailerEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    required String photoPath,
    String? address,
    String? notes,
  });
  Future<TrailerEntryModel> updateTrailerStatus({
    required String trailerId,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    bool isInRamp = false,
    String? rampNumber,
    String? address,
    String? notes,
  });
}

/// Implementation of TrailerDetailRemoteDataSource
class TrailerDetailRemoteDataSourceImpl implements TrailerDetailRemoteDataSource {
  final DioClient client;

  TrailerDetailRemoteDataSourceImpl(this.client);

  @override
  Future<TrailerModel> getTrailerById(String id) async {
    try {
      logger.debug('Fetching trailer by ID: $id');

      final response = await client.get(ApiEndpoints.trailerById(id));

      if (response.statusCode == 200 && response.data != null) {
        final trailer = TrailerModel.fromJson(response.data as Map<String, dynamic>);
        logger.info('Fetched trailer: ${trailer.trailerNumber}');
        return trailer;
      } else {
        throw ServerException('Failed to fetch trailer', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error fetching trailer by ID', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutException();
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      } else if (e.response?.statusCode == 404) {
        throw ServerException('Trailer not found', 404);
      } else if (e.response != null) {
        throw ServerException(
          e.response?.data?['message'] ?? 'Server error',
          e.response?.statusCode,
        );
      } else {
        throw ServerException(e.message ?? 'Unknown error');
      }
    } catch (e) {
      logger.error('Unexpected error fetching trailer by ID', e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<HistoryResponse> getTrailerHistory(String trailerId, int limit, int offset) async {
    try {
      logger.debug('Fetching trailer history: $trailerId (limit: $limit, offset: $offset)');

      final response = await client.get(
        ApiEndpoints.trailerEntries(trailerId),
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Parse entries from 'data' field
        final List<dynamic> entriesJson = responseData['data'] as List<dynamic>;
        final entries = entriesJson
            .map((json) => TrailerEntryModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Parse pagination info
        final paginationJson = responseData['pagination'] as Map<String, dynamic>;
        final pagination = HistoryPagination(
          total: paginationJson['total'] as int,
          limit: paginationJson['limit'] as int,
          offset: paginationJson['offset'] as int,
          hasMore: paginationJson['hasMore'] as bool,
        );

        logger.info('Fetched ${entries.length} history entries (total: ${pagination.total})');
        return HistoryResponse(data: entries, pagination: pagination);
      } else {
        throw ServerException('Failed to fetch trailer history', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error fetching trailer history', e);
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
      logger.error('Unexpected error fetching trailer history', e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TrailerEntryModel> createTrailerEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    required String photoPath,
    String? address,
    String? notes,
  }) async {
    try {
      logger.debug('Creating trailer entry for: $trailerNumber');

      // Create multipart form data
      final formData = FormData.fromMap({
        'trailerNumber': trailerNumber,
        'terminal': terminal,
        'isEmpty': isEmpty,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await client.post(
        ApiEndpoints.trailers,
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        final entry = TrailerEntryModel.fromJson(response.data as Map<String, dynamic>);
        logger.info('Created trailer entry: ${entry.id}');
        return entry;
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
  Future<TrailerEntryModel> updateTrailerStatus({
    required String trailerId,
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
      logger.debug('Updating trailer status for: $trailerId (isEmpty: $isEmpty, isInRamp: $isInRamp)');

      final response = await client.put(
        '${ApiEndpoints.trailerById(trailerId)}/status',
        data: {
          'terminal': terminal,
          'isEmpty': isEmpty,
          'isInRamp': isInRamp,
          if (isInRamp && rampNumber != null && rampNumber.isNotEmpty) 'rampNumber': rampNumber,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final entry = TrailerEntryModel.fromJson(response.data as Map<String, dynamic>);
        logger.info('Updated trailer status: ${entry.id}');
        return entry;
      } else {
        throw ServerException('Failed to update trailer status', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error updating trailer status', e);
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
      logger.error('Unexpected error updating trailer status', e);
      throw ServerException(e.toString());
    }
  }
}

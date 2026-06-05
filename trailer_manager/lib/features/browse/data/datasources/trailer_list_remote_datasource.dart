import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/trailer_model.dart';

/// Remote data source for trailer list operations
abstract class TrailerListRemoteDataSource {
  Future<List<TrailerModel>> getTrailers({
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
}

/// Implementation of TrailerListRemoteDataSource
class TrailerListRemoteDataSourceImpl implements TrailerListRemoteDataSource {
  final DioClient client;

  TrailerListRemoteDataSourceImpl(this.client);

  @override
  Future<List<TrailerModel>> getTrailers({
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
      logger.debug('Fetching trailers (page: $page, limit: $limit)');

      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (trailerNumber != null) queryParams['trailerNumber'] = trailerNumber;
      if (terminal != null) queryParams['terminal'] = terminal;
      if (isEmpty != null) queryParams['isEmpty'] = isEmpty;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await client.get(
        ApiEndpoints.trailers,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> trailersJson = data['data'] as List<dynamic>;

        final trailers = trailersJson
            .map((json) => TrailerModel.fromJson(json as Map<String, dynamic>))
            .toList();

        logger.info('Fetched ${trailers.length} trailers');
        return trailers;
      } else {
        throw ServerException('Failed to fetch trailers', response.statusCode);
      }
    } on DioException catch (e) {
      logger.error('Dio error fetching trailers', e);
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
      logger.error('Unexpected error fetching trailers', e);
      throw ServerException(e.toString());
    }
  }
}

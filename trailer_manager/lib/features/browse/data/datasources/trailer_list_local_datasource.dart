import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/trailer_model.dart';

/// Local data source for trailer list caching
abstract class TrailerListLocalDataSource {
  Future<List<TrailerModel>> getCachedTrailers();
  Future<void> cacheTrailers(List<TrailerModel> trailers);
  Future<void> clearCache();
}

/// Implementation using Hive
class TrailerListLocalDataSourceImpl implements TrailerListLocalDataSource {
  static const String _cachedTrailersKey = 'cached_trailers';
  static const String _cacheTimestampKey = 'cache_timestamp';

  @override
  Future<List<TrailerModel>> getCachedTrailers() async {
    try {
      logger.debug('Getting cached trailers');
      final box = await Hive.openBox(AppConstants.cacheBoxName);

      final cachedData = box.get(_cachedTrailersKey);
      if (cachedData == null) {
        logger.debug('No cached trailers found');
        return [];
      }

      // Check cache timestamp
      final timestamp = box.get(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        logger.debug('Cache age: ${difference.inMinutes} minutes');
        // Cache is valid for 5 minutes (configurable in AppConfig)
        if (difference.inMinutes > 5) {
          logger.debug('Cache expired');
          return [];
        }
      }

      final List<dynamic> jsonList = cachedData as List<dynamic>;
      final trailers = jsonList
          .map((json) => TrailerModel.fromJson(json as Map<String, dynamic>))
          .toList();

      logger.info('Retrieved ${trailers.length} trailers from cache');
      return trailers;
    } catch (e, stackTrace) {
      logger.error('Failed to get cached trailers', e, stackTrace);
      throw const CacheException('Failed to retrieve cached data');
    }
  }

  @override
  Future<void> cacheTrailers(List<TrailerModel> trailers) async {
    try {
      logger.debug('Caching ${trailers.length} trailers');
      final box = await Hive.openBox(AppConstants.cacheBoxName);

      final jsonList = trailers.map((trailer) => trailer.toJson()).toList();
      await box.put(_cachedTrailersKey, jsonList);
      await box.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      logger.info('Successfully cached ${trailers.length} trailers');
    } catch (e, stackTrace) {
      logger.error('Failed to cache trailers', e, stackTrace);
      throw const CacheException('Failed to cache data');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.debug('Clearing trailer cache');
      final box = await Hive.openBox(AppConstants.cacheBoxName);
      await box.delete(_cachedTrailersKey);
      await box.delete(_cacheTimestampKey);
      logger.info('Cache cleared successfully');
    } catch (e, stackTrace) {
      logger.error('Failed to clear cache', e, stackTrace);
      throw const CacheException('Failed to clear cache');
    }
  }
}

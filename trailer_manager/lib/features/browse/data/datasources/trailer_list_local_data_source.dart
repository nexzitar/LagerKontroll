import 'package:trailer_manager/features/browse/data/models/trailer_model.dart';

/// Local data source for browsing trailers
///
/// This interface defines methods for caching and retrieving trailer lists locally.
abstract class TrailerListLocalDataSource {
  /// Caches a list of trailers locally
  ///
  /// Throws:
  /// - [CacheException] if the trailers cannot be cached
  Future<void> cacheTrailers(List<TrailerModel> trailers);

  /// Gets cached trailers
  ///
  /// Throws:
  /// - [CacheException] if trailers cannot be retrieved
  Future<List<TrailerModel>> getCachedTrailers();

  /// Gets the timestamp of the last cache update
  ///
  /// Returns null if no cache exists
  ///
  /// Throws:
  /// - [CacheException] if the timestamp cannot be retrieved
  Future<DateTime?> getLastCacheTime();

  /// Clears all cached trailers
  ///
  /// Throws:
  /// - [CacheException] if the cache cannot be cleared
  Future<void> clearCache();
}

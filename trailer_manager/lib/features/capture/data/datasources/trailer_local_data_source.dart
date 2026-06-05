import 'package:trailer_manager/features/capture/data/models/trailer_entry_model.dart';

/// Local data source for trailer capture operations
///
/// This interface defines methods for caching trailer entries locally
/// using Hive or another local storage solution.
abstract class TrailerLocalDataSource {
  /// Caches a trailer entry locally
  ///
  /// Throws:
  /// - [CacheException] if the entry cannot be cached
  Future<void> cacheEntry(TrailerEntryModel entry);

  /// Gets a cached trailer entry by ID
  ///
  /// Throws:
  /// - [CacheException] if the entry cannot be retrieved
  /// - [CacheException] if the entry is not found
  Future<TrailerEntryModel> getCachedEntry(String id);

  /// Gets all cached trailer entries
  ///
  /// Throws:
  /// - [CacheException] if entries cannot be retrieved
  Future<List<TrailerEntryModel>> getCachedEntries();

  /// Clears all cached entries
  ///
  /// Throws:
  /// - [CacheException] if the cache cannot be cleared
  Future<void> clearCache();
}

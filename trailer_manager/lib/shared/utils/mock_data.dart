import '../../features/capture/data/models/trailer_entry_model.dart';
import '../../features/browse/data/models/trailer_model.dart';

/// Mock data generator for testing without backend
class MockData {
  MockData._();

  /// Generate mock trailer entries
  static List<TrailerModel> generateMockTrailers() {
    final now = DateTime.now();

    return [
      TrailerModel(
        id: 'trailer-1',
        trailerNumber: 'TR-12345',
        latestEntry: TrailerEntryModel(
          id: 'entry-1',
          trailerId: 'trailer-1',
          trailerNumber: 'TR-12345',
          terminal: 'B1',
          isEmpty: false,
          latitude: 59.3293,
          longitude: 18.0686,
          address: 'Stockholm, Sweden',
          photoUrl: 'https://via.placeholder.com/400',
          thumbnailUrl: 'https://via.placeholder.com/200',
          notes: 'Full load of equipment',
          createdBy: 'John Doe',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        entryCount: 15,
        firstSeenAt: now.subtract(const Duration(days: 30)),
        lastSeenAt: now.subtract(const Duration(hours: 2)),
      ),
      TrailerModel(
        id: 'trailer-2',
        trailerNumber: 'TR-67890',
        latestEntry: TrailerEntryModel(
          id: 'entry-2',
          trailerId: 'trailer-2',
          trailerNumber: 'TR-67890',
          terminal: 'B3',
          isEmpty: true,
          latitude: 57.7089,
          longitude: 11.9746,
          address: 'Gothenburg, Sweden',
          photoUrl: 'https://via.placeholder.com/400',
          thumbnailUrl: 'https://via.placeholder.com/200',
          createdBy: 'Jane Smith',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        entryCount: 8,
        firstSeenAt: now.subtract(const Duration(days: 15)),
        lastSeenAt: now.subtract(const Duration(hours: 5)),
      ),
      TrailerModel(
        id: 'trailer-3',
        trailerNumber: 'TR-11111',
        latestEntry: TrailerEntryModel(
          id: 'entry-3',
          trailerId: 'trailer-3',
          trailerNumber: 'TR-11111',
          terminal: 'B1',
          isEmpty: false,
          latitude: 59.8586,
          longitude: 17.6389,
          address: 'Uppsala, Sweden',
          photoUrl: 'https://via.placeholder.com/400',
          thumbnailUrl: 'https://via.placeholder.com/200',
          notes: 'Partial load',
          createdBy: 'Mike Johnson',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        entryCount: 22,
        firstSeenAt: now.subtract(const Duration(days: 60)),
        lastSeenAt: now.subtract(const Duration(days: 1)),
      ),
      TrailerModel(
        id: 'trailer-4',
        trailerNumber: 'TR-22222',
        latestEntry: TrailerEntryModel(
          id: 'entry-4',
          trailerId: 'trailer-4',
          trailerNumber: 'TR-22222',
          terminal: 'B3',
          isEmpty: true,
          latitude: 55.6050,
          longitude: 13.0038,
          address: 'Malmö, Sweden',
          photoUrl: 'https://via.placeholder.com/400',
          thumbnailUrl: 'https://via.placeholder.com/200',
          createdBy: 'Sarah Wilson',
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
        entryCount: 5,
        firstSeenAt: now.subtract(const Duration(days: 10)),
        lastSeenAt: now.subtract(const Duration(hours: 12)),
      ),
      TrailerModel(
        id: 'trailer-5',
        trailerNumber: 'TR-33333',
        latestEntry: TrailerEntryModel(
          id: 'entry-5',
          trailerId: 'trailer-5',
          trailerNumber: 'TR-33333',
          terminal: 'B1',
          isEmpty: false,
          latitude: 59.4021,
          longitude: 17.9465,
          address: 'Stockholm, Sweden',
          photoUrl: 'https://via.placeholder.com/400',
          thumbnailUrl: 'https://via.placeholder.com/200',
          notes: 'Heavy machinery',
          createdBy: 'Tom Anderson',
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
        entryCount: 12,
        firstSeenAt: now.subtract(const Duration(days: 45)),
        lastSeenAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  /// Generate a single mock trailer entry
  static TrailerEntryModel generateMockEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    String? address,
    String? notes,
  }) {
    return TrailerEntryModel(
      id: 'entry-${DateTime.now().millisecondsSinceEpoch}',
      trailerId: 'trailer-${DateTime.now().millisecondsSinceEpoch}',
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      latitude: latitude,
      longitude: longitude,
      address: address ?? 'Mock Location',
      photoUrl: 'https://via.placeholder.com/400',
      thumbnailUrl: 'https://via.placeholder.com/200',
      notes: notes,
      createdBy: 'Mock User',
      createdAt: DateTime.now(),
    );
  }
}

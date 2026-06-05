import 'package:equatable/equatable.dart';
import '../../../capture/domain/entities/trailer_entry.dart';

/// Domain entity representing a trailer with its latest entry
class Trailer extends Equatable {
  final String id;
  final String trailerNumber;
  final TrailerEntry latestEntry;
  final int entryCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  const Trailer({
    required this.id,
    required this.trailerNumber,
    required this.latestEntry,
    required this.entryCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  @override
  List<Object?> get props => [
        id,
        trailerNumber,
        latestEntry,
        entryCount,
        firstSeenAt,
        lastSeenAt,
      ];

  @override
  String toString() => 'Trailer(id: $id, trailerNumber: $trailerNumber, entryCount: $entryCount)';
}

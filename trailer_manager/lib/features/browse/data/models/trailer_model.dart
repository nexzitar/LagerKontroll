import 'package:json_annotation/json_annotation.dart';
import '../../../capture/data/models/trailer_entry_model.dart';
import '../../domain/entities/trailer.dart';

part 'trailer_model.g.dart';

/// Data model for Trailer with JSON serialization
@JsonSerializable()
class TrailerModel extends Trailer {
  @override
  @JsonKey(name: 'latestEntry')
  final TrailerEntryModel latestEntry;

  const TrailerModel({
    required super.id,
    required super.trailerNumber,
    required this.latestEntry,
    required super.entryCount,
    required super.firstSeenAt,
    required super.lastSeenAt,
  }) : super(latestEntry: latestEntry);

  /// Create from JSON
  factory TrailerModel.fromJson(Map<String, dynamic> json) =>
      _$TrailerModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TrailerModelToJson(this);

  /// Create from domain entity
  factory TrailerModel.fromEntity(Trailer entity) {
    return TrailerModel(
      id: entity.id,
      trailerNumber: entity.trailerNumber,
      latestEntry: TrailerEntryModel.fromEntity(entity.latestEntry),
      entryCount: entity.entryCount,
      firstSeenAt: entity.firstSeenAt,
      lastSeenAt: entity.lastSeenAt,
    );
  }

  /// Create a copy with some fields changed
  TrailerModel copyWith({
    String? id,
    String? trailerNumber,
    TrailerEntryModel? latestEntry,
    int? entryCount,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return TrailerModel(
      id: id ?? this.id,
      trailerNumber: trailerNumber ?? this.trailerNumber,
      latestEntry: latestEntry ?? this.latestEntry,
      entryCount: entryCount ?? this.entryCount,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

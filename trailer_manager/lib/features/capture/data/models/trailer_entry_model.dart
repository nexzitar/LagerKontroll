import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trailer_entry.dart';
import '../../../../core/config/environment.dart';

part 'trailer_entry_model.g.dart';

/// Data model for TrailerEntry with JSON serialization
@JsonSerializable()
class TrailerEntryModel extends TrailerEntry {
  const TrailerEntryModel({
    required super.id,
    super.trailerId,
    required super.trailerNumber,
    required super.terminal,
    required super.isEmpty,
    super.isInRamp,
    super.rampNumber,
    required super.latitude,
    required super.longitude,
    super.address,
    required super.photoUrl,
    super.thumbnailUrl,
    super.notes,
    super.createdBy,
    required super.createdAt,
  });

  /// Convert relative URL to absolute URL
  static String _toAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already absolute
    }
    // Remove /api/v1 from base URL and append the relative path
    final baseUrl = EnvironmentConfig.current.apiBaseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  /// Create from JSON
  factory TrailerEntryModel.fromJson(Map<String, dynamic> json) {
    final model = _$TrailerEntryModelFromJson(json);
    // Convert relative URLs to absolute
    return TrailerEntryModel(
      id: model.id,
      trailerId: model.trailerId,
      trailerNumber: model.trailerNumber,
      terminal: model.terminal,
      isEmpty: model.isEmpty,
      isInRamp: model.isInRamp,
      rampNumber: model.rampNumber,
      latitude: model.latitude,
      longitude: model.longitude,
      address: model.address,
      photoUrl: _toAbsoluteUrl(model.photoUrl),
      thumbnailUrl: _toAbsoluteUrl(model.thumbnailUrl),
      notes: model.notes,
      createdBy: model.createdBy,
      createdAt: model.createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TrailerEntryModelToJson(this);

  /// Create from domain entity
  factory TrailerEntryModel.fromEntity(TrailerEntry entity) {
    return TrailerEntryModel(
      id: entity.id,
      trailerId: entity.trailerId,
      trailerNumber: entity.trailerNumber,
      terminal: entity.terminal,
      isEmpty: entity.isEmpty,
      isInRamp: entity.isInRamp,
      rampNumber: entity.rampNumber,
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      photoUrl: entity.photoUrl,
      thumbnailUrl: entity.thumbnailUrl,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  /// Create a copy with some fields changed
  TrailerEntryModel copyWith({
    String? id,
    String? trailerId,
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
    bool? isInRamp,
    String? rampNumber,
    double? latitude,
    double? longitude,
    String? address,
    String? photoUrl,
    String? thumbnailUrl,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TrailerEntryModel(
      id: id ?? this.id,
      trailerId: trailerId ?? this.trailerId,
      trailerNumber: trailerNumber ?? this.trailerNumber,
      terminal: terminal ?? this.terminal,
      isEmpty: isEmpty ?? this.isEmpty,
      isInRamp: isInRamp ?? this.isInRamp,
      rampNumber: rampNumber ?? this.rampNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trailer_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrailerEntryModel _$TrailerEntryModelFromJson(Map<String, dynamic> json) =>
    TrailerEntryModel(
      id: json['id'] as String,
      trailerId: json['trailerId'] as String?,
      trailerNumber: json['trailerNumber'] as String,
      terminal: json['terminal'] as String,
      isEmpty: json['isEmpty'] as bool,
      isInRamp: json['isInRamp'] as bool? ?? false,
      rampNumber: json['rampNumber'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      photoUrl: json['photoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TrailerEntryModelToJson(TrailerEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailerId': instance.trailerId,
      'trailerNumber': instance.trailerNumber,
      'terminal': instance.terminal,
      'isEmpty': instance.isEmpty,
      'isInRamp': instance.isInRamp,
      'rampNumber': instance.rampNumber,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'photoUrl': instance.photoUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'notes': instance.notes,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };

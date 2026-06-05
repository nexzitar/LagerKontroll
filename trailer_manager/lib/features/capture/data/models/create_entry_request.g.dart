// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_entry_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateEntryRequest _$CreateEntryRequestFromJson(Map<String, dynamic> json) =>
    CreateEntryRequest(
      trailerNumber: json['trailerNumber'] as String,
      terminal: json['terminal'] as String,
      isEmpty: json['isEmpty'] as bool,
      isInRamp: json['isInRamp'] as bool? ?? false,
      rampNumber: json['rampNumber'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$CreateEntryRequestToJson(CreateEntryRequest instance) =>
    <String, dynamic>{
      'trailerNumber': instance.trailerNumber,
      'terminal': instance.terminal,
      'isEmpty': instance.isEmpty,
      'isInRamp': instance.isInRamp,
      'rampNumber': instance.rampNumber,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'photoUrl': instance.photoUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'notes': instance.notes,
      'createdBy': instance.createdBy,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trailer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrailerModel _$TrailerModelFromJson(Map<String, dynamic> json) => TrailerModel(
  id: json['id'] as String,
  trailerNumber: json['trailerNumber'] as String,
  latestEntry: TrailerEntryModel.fromJson(
    json['latestEntry'] as Map<String, dynamic>,
  ),
  entryCount: (json['entryCount'] as num).toInt(),
  firstSeenAt: DateTime.parse(json['firstSeenAt'] as String),
  lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
);

Map<String, dynamic> _$TrailerModelToJson(TrailerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailerNumber': instance.trailerNumber,
      'entryCount': instance.entryCount,
      'firstSeenAt': instance.firstSeenAt.toIso8601String(),
      'lastSeenAt': instance.lastSeenAt.toIso8601String(),
      'latestEntry': instance.latestEntry,
    };

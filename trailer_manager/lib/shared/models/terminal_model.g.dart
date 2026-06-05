// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TerminalModel _$TerminalModelFromJson(Map<String, dynamic> json) =>
    TerminalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$TerminalModelToJson(TerminalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'isActive': instance.isActive,
    };

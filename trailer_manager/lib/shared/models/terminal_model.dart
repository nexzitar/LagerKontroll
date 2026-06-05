import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'terminal_model.g.dart';

/// Model for terminal information
@JsonSerializable()
class TerminalModel extends Equatable {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isActive;

  const TerminalModel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.address,
    required this.isActive,
  });

  factory TerminalModel.fromJson(Map<String, dynamic> json) =>
      _$TerminalModelFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalModelToJson(this);

  @override
  List<Object?> get props => [id, name, latitude, longitude, address, isActive];
}

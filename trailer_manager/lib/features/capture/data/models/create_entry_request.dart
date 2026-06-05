import 'package:json_annotation/json_annotation.dart';

part 'create_entry_request.g.dart';

/// Request model for creating a new trailer entry.
/// Used when posting new entries to the API.
@JsonSerializable()
class CreateEntryRequest {
  final String trailerNumber;
  final String terminal;
  final bool isEmpty;
  final bool isInRamp;
  final String? rampNumber;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final String thumbnailUrl;
  final String? notes;
  final String createdBy;

  const CreateEntryRequest({
    required this.trailerNumber,
    required this.terminal,
    required this.isEmpty,
    this.isInRamp = false,
    this.rampNumber,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.thumbnailUrl,
    this.notes,
    required this.createdBy,
  });

  /// Creates a CreateEntryRequest from JSON.
  factory CreateEntryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEntryRequestFromJson(json);

  /// Converts this CreateEntryRequest to JSON for API submission.
  Map<String, dynamic> toJson() => _$CreateEntryRequestToJson(this);

  @override
  String toString() {
    return 'CreateEntryRequest(trailerNumber: $trailerNumber, terminal: $terminal, isEmpty: $isEmpty, isInRamp: $isInRamp, rampNumber: $rampNumber, createdBy: $createdBy)';
  }

  /// Creates a copy of this CreateEntryRequest with the given fields replaced with new values.
  CreateEntryRequest copyWith({
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
    bool? isInRamp,
    String? rampNumber,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? thumbnailUrl,
    String? notes,
    String? createdBy,
  }) {
    return CreateEntryRequest(
      trailerNumber: trailerNumber ?? this.trailerNumber,
      terminal: terminal ?? this.terminal,
      isEmpty: isEmpty ?? this.isEmpty,
      isInRamp: isInRamp ?? this.isInRamp,
      rampNumber: rampNumber ?? this.rampNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

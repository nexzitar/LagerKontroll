import 'package:equatable/equatable.dart';

/// Domain entity representing a trailer entry
/// Pure Dart class with no external dependencies (except equatable)
class TrailerEntry extends Equatable {
  final String id;
  final String? trailerId;
  final String trailerNumber;
  final String terminal;
  final bool isEmpty;
  final bool isInRamp;
  final String? rampNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String photoUrl;
  final String? thumbnailUrl;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const TrailerEntry({
    required this.id,
    this.trailerId,
    required this.trailerNumber,
    required this.terminal,
    required this.isEmpty,
    this.isInRamp = false,
    this.rampNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.photoUrl,
    this.thumbnailUrl,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        trailerId,
        trailerNumber,
        terminal,
        isEmpty,
        isInRamp,
        rampNumber,
        latitude,
        longitude,
        address,
        photoUrl,
        thumbnailUrl,
        notes,
        createdBy,
        createdAt,
      ];

  @override
  String toString() => 'TrailerEntry(id: $id, trailerNumber: $trailerNumber, terminal: $terminal)';
}

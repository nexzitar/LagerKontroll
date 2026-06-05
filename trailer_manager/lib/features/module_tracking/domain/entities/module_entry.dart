import 'package:flutter/foundation.dart';

/// A single captured module entry
@immutable
class ModuleEntry {
  final String licensePlate;
  final String? containerId;
  final String terminal;
  final DateTime capturedAt;
  final String? photoPath;

  const ModuleEntry({
    required this.licensePlate,
    this.containerId,
    required this.terminal,
    required this.capturedAt,
    this.photoPath,
  });

  /// Creates a copy with updated fields
  ModuleEntry copyWith({
    String? licensePlate,
    String? containerId,
    String? terminal,
    DateTime? capturedAt,
    String? photoPath,
  }) {
    return ModuleEntry(
      licensePlate: licensePlate ?? this.licensePlate,
      containerId: containerId ?? this.containerId,
      terminal: terminal ?? this.terminal,
      capturedAt: capturedAt ?? this.capturedAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  /// Formats the entry as a single line for the list output
  /// Format: "NB 5229 -- PTRU 406124-0" or "NB 5229" if no container
  String toFormattedLine() {
    if (containerId != null && containerId!.isNotEmpty) {
      return '$licensePlate -- $containerId';
    }
    return licensePlate;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModuleEntry &&
        other.licensePlate == licensePlate &&
        other.containerId == containerId &&
        other.terminal == terminal &&
        other.capturedAt == capturedAt &&
        other.photoPath == photoPath;
  }

  @override
  int get hashCode {
    return Object.hash(licensePlate, containerId, terminal, capturedAt, photoPath);
  }

  @override
  String toString() {
    return 'ModuleEntry(licensePlate: $licensePlate, containerId: $containerId, terminal: $terminal, capturedAt: $capturedAt, photoPath: $photoPath)';
  }
}

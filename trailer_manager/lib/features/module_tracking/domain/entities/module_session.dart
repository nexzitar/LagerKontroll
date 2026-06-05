import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'module_entry.dart';

/// A module tracking session containing multiple entries
@immutable
class ModuleSession {
  final List<ModuleEntry> entries;
  final DateTime sessionStart;

  const ModuleSession({
    required this.entries,
    required this.sessionStart,
  });

  /// Creates an empty session starting now
  factory ModuleSession.start() {
    return ModuleSession(
      entries: const [],
      sessionStart: DateTime.now(),
    );
  }

  /// Returns entries grouped by terminal
  Map<String, List<ModuleEntry>> get entriesByTerminal {
    final grouped = <String, List<ModuleEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.terminal, () => []).add(entry);
    }
    return grouped;
  }

  /// Generates the formatted list text for sharing/display
  ///
  /// Format:
  /// ```
  /// Moduler (2026-01-20)
  /// B1
  /// NB 5229 -- PTRU 406124-0
  /// VA 1948 -- CONT 123456-0
  /// B2
  /// ...
  /// ```
  String toFormattedText() {
    final dateStr = DateFormat('yyyy-MM-dd').format(sessionStart);
    final buffer = StringBuffer();
    buffer.writeln('Moduler ($dateStr)');

    final grouped = entriesByTerminal;
    // Sort terminals alphabetically for consistent output
    final sortedTerminals = grouped.keys.toList()..sort();

    for (final terminal in sortedTerminals) {
      buffer.writeln(terminal);
      for (final entry in grouped[terminal]!) {
        buffer.writeln(entry.toFormattedLine());
      }
    }

    return buffer.toString().trimRight();
  }

  /// Total number of entries in the session
  int get entryCount => entries.length;

  /// Returns true if the session has any entries
  bool get hasEntries => entries.isNotEmpty;

  /// Adds an entry and returns a new session
  ModuleSession addEntry(ModuleEntry entry) {
    return ModuleSession(
      entries: [...entries, entry],
      sessionStart: sessionStart,
    );
  }

  /// Removes an entry at the given index and returns a new session
  ModuleSession removeEntryAt(int index) {
    final newEntries = List<ModuleEntry>.from(entries)..removeAt(index);
    return ModuleSession(
      entries: newEntries,
      sessionStart: sessionStart,
    );
  }

  /// Creates a copy with updated fields
  ModuleSession copyWith({
    List<ModuleEntry>? entries,
    DateTime? sessionStart,
  }) {
    return ModuleSession(
      entries: entries ?? this.entries,
      sessionStart: sessionStart ?? this.sessionStart,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModuleSession &&
        listEquals(other.entries, entries) &&
        other.sessionStart == sessionStart;
  }

  @override
  int get hashCode {
    return Object.hash(entries, sessionStart);
  }

  @override
  String toString() {
    return 'ModuleSession(entryCount: $entryCount, sessionStart: $sessionStart)';
  }
}

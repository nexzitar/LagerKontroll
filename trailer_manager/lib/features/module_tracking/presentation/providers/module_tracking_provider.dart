import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/module_entry.dart';
import '../../domain/entities/module_session.dart';

/// Module tracking state notifier
class ModuleTrackingNotifier extends StateNotifier<ModuleSession> {
  ModuleTrackingNotifier() : super(ModuleSession.start());

  /// Starts a new tracking session
  void startSession() {
    state = ModuleSession.start();
    logger.info('Module tracking session started');
  }

  /// Adds a captured module entry to the current session
  void addEntry(ModuleEntry entry) {
    state = state.addEntry(entry);
    logger.info('Added module entry: ${entry.licensePlate} at ${entry.terminal}');
  }

  /// Removes an entry at the specified index
  void removeEntry(int index) {
    if (index < 0 || index >= state.entries.length) {
      logger.warning('Cannot remove entry: Invalid index $index');
      return;
    }

    final removed = state.entries[index];
    state = state.removeEntryAt(index);
    logger.info('Removed module entry: ${removed.licensePlate}');
  }

  /// Updates an entry at the specified index
  void updateEntry(int index, ModuleEntry updatedEntry) {
    if (index < 0 || index >= state.entries.length) {
      logger.warning('Cannot update entry: Invalid index $index');
      return;
    }

    final updatedEntries = List<ModuleEntry>.from(state.entries);
    updatedEntries[index] = updatedEntry;
    state = state.copyWith(entries: updatedEntries);
    logger.info('Updated module entry at index $index');
  }

  /// Clears all entries and resets the session
  void clearSession() {
    state = ModuleSession.start();
    logger.info('Module tracking session cleared');
  }

  /// Returns the formatted text list for sending
  String getFormattedList() {
    return state.toFormattedText();
  }

  /// Getter to check if session has any entries
  bool get hasEntries => state.hasEntries;

  /// Getter for entry count
  int get entryCount => state.entryCount;
}

/// Provider for module tracking state
final moduleTrackingProvider =
    StateNotifierProvider<ModuleTrackingNotifier, ModuleSession>((ref) {
  return ModuleTrackingNotifier();
});

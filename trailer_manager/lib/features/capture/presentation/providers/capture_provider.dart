import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trailer_entry.dart';
import '../../domain/usecases/create_trailer_entry.dart';
import '../../../../core/providers/providers.dart';

/// State for capture screen
class CaptureState {
  final bool isLoading;
  final TrailerEntry? entry;
  final String? error;
  final bool success;

  const CaptureState({
    this.isLoading = false,
    this.entry,
    this.error,
    this.success = false,
  });

  CaptureState copyWith({
    bool? isLoading,
    TrailerEntry? entry,
    String? error,
    bool? success,
  }) {
    return CaptureState(
      isLoading: isLoading ?? this.isLoading,
      entry: entry ?? this.entry,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Notifier for managing capture state
class CaptureNotifier extends StateNotifier<CaptureState> {
  final CreateTrailerEntry createEntryUseCase;

  CaptureNotifier(this.createEntryUseCase) : super(const CaptureState());

  /// Create a new trailer entry
  Future<void> createEntry({
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    bool isInRamp = false,
    String? rampNumber,
    required double latitude,
    required double longitude,
    String? address,
    required File photo,
    String? notes,
  }) async {
    state = const CaptureState(isLoading: true);

    final result = await createEntryUseCase(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      isInRamp: isInRamp,
      rampNumber: rampNumber,
      latitude: latitude,
      longitude: longitude,
      address: address,
      photo: photo,
      notes: notes,
    );

    result.fold(
      (failure) {
        state = CaptureState(
          isLoading: false,
          error: failure.message,
          success: false,
        );
      },
      (entry) {
        state = CaptureState(
          isLoading: false,
          entry: entry,
          success: true,
        );
      },
    );
  }

  /// Reset state
  void reset() {
    state = const CaptureState();
  }
}

/// Provider for capture state
final captureProvider = StateNotifierProvider.autoDispose<CaptureNotifier, CaptureState>((ref) {
  final createEntry = ref.watch(createTrailerEntryProvider);
  return CaptureNotifier(createEntry);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../browse/domain/entities/trailer.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../../../capture/domain/usecases/get_address_from_coordinates.dart';
import '../../../capture/domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_trailer_detail.dart';
import '../../domain/usecases/get_trailer_history.dart';
import '../../domain/usecases/update_trailer_status.dart';
import '../../../../core/providers/providers.dart';

/// State for trailer detail screen
class TrailerDetailState {
  final Trailer? trailer;
  final List<TrailerEntry> history;
  final bool isLoading;
  final bool isLoadingHistory;
  final bool isUpdatingStatus;
  final String? error;
  final String? successMessage;

  const TrailerDetailState({
    this.trailer,
    this.history = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.isUpdatingStatus = false,
    this.error,
    this.successMessage,
  });

  TrailerDetailState copyWith({
    Trailer? trailer,
    List<TrailerEntry>? history,
    bool? isLoading,
    bool? isLoadingHistory,
    bool? isUpdatingStatus,
    String? error,
    String? successMessage,
  }) {
    return TrailerDetailState(
      trailer: trailer ?? this.trailer,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for managing trailer detail state
class TrailerDetailNotifier extends StateNotifier<TrailerDetailState> {
  final GetTrailerDetail getTrailerDetailUseCase;
  final GetTrailerHistory getTrailerHistoryUseCase;
  final UpdateTrailerStatus updateTrailerStatusUseCase;
  final GetCurrentLocation getCurrentLocationUseCase;
  final GetAddressFromCoordinates getAddressUseCase;

  TrailerDetailNotifier(
    this.getTrailerDetailUseCase,
    this.getTrailerHistoryUseCase,
    this.updateTrailerStatusUseCase,
    this.getCurrentLocationUseCase,
    this.getAddressUseCase,
  ) : super(const TrailerDetailState());

  /// Load trailer details
  Future<void> loadTrailer(String trailerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await getTrailerDetailUseCase(trailerId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (trailer) {
        state = state.copyWith(
          trailer: trailer,
          isLoading: false,
          error: null,
        );

        // Also load history
        loadHistory(trailerId);
      },
    );
  }

  /// Load trailer history
  Future<void> loadHistory(String trailerId, {int? limit}) async {
    state = state.copyWith(isLoadingHistory: true);

    final result = await getTrailerHistoryUseCase(trailerId, limit: limit, offset: 0);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoadingHistory: false,
          error: failure.message,
        );
      },
      (response) {
        state = state.copyWith(
          history: response.data,
          isLoadingHistory: false,
        );
      },
    );
  }

  /// Refresh data
  Future<void> refresh(String trailerId) async {
    await loadTrailer(trailerId);
  }

  /// Mark trailer as empty (creates new entry with same location, isEmpty = true)
  Future<void> markAsEmpty(String trailerId) async {
    final trailer = state.trailer;
    if (trailer == null) {
      state = state.copyWith(error: 'No trailer data available');
      return;
    }

    state = state.copyWith(
      isUpdatingStatus: true,
      error: null,
      successMessage: null,
    );

    final entry = trailer.latestEntry;

    final result = await updateTrailerStatusUseCase(
      trailerId: trailerId,
      trailerNumber: trailer.trailerNumber,
      terminal: entry.terminal,
      isEmpty: true, // Mark as empty
      latitude: entry.latitude,
      longitude: entry.longitude,
      address: entry.address,
      notes: 'Marked as empty',
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isUpdatingStatus: false,
          error: failure.message,
        );
      },
      (newEntry) {
        state = state.copyWith(
          isUpdatingStatus: false,
          successMessage: 'Trailer marked as empty successfully',
        );
        // Refresh data to show new entry
        refresh(trailerId);
      },
    );
  }

  /// Update trailer location (gets current GPS and creates new entry)
  Future<void> updateLocation(String trailerId) async {
    final trailer = state.trailer;
    if (trailer == null) {
      state = state.copyWith(error: 'No trailer data available');
      return;
    }

    state = state.copyWith(
      isUpdatingStatus: true,
      error: null,
      successMessage: null,
    );

    // Get current location
    final locationResult = await getCurrentLocationUseCase();

    await locationResult.fold(
      (failure) async {
        state = state.copyWith(
          isUpdatingStatus: false,
          error: 'Failed to get current location: ${failure.message}',
        );
      },
      (locationData) async {
        // Get address from coordinates
        String? address;
        final addressResult = await getAddressUseCase(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
        );
        addressResult.fold(
          (failure) => address = null,
          (addr) => address = addr,
        );

        // Update trailer with new location
        final entry = trailer.latestEntry;
        final result = await updateTrailerStatusUseCase(
          trailerId: trailerId,
          trailerNumber: trailer.trailerNumber,
          terminal: entry.terminal,
          isEmpty: entry.isEmpty, // Keep same empty status
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          address: address,
          notes: 'Location updated',
        );

        result.fold(
          (failure) {
            state = state.copyWith(
              isUpdatingStatus: false,
              error: failure.message,
            );
          },
          (newEntry) {
            state = state.copyWith(
              isUpdatingStatus: false,
              successMessage: 'Location updated successfully',
            );
            // Refresh data to show new entry
            refresh(trailerId);
          },
        );
      },
    );
  }

  /// Update trailer status (Empty/Loaded/In Ramp) and optionally location
  Future<void> updateStatus(
    String trailerId, {
    required bool isEmpty,
    required bool isInRamp,
    String? rampNumber,
    bool updateLocation = true,
  }) async {
    final trailer = state.trailer;
    if (trailer == null) {
      state = state.copyWith(error: 'No trailer data available');
      return;
    }

    state = state.copyWith(
      isUpdatingStatus: true,
      error: null,
      successMessage: null,
    );

    final entry = trailer.latestEntry;

    // Determine status description for notes
    String statusDesc;
    if (isInRamp) {
      statusDesc = rampNumber != null && rampNumber.isNotEmpty
          ? 'In Ramp $rampNumber'
          : 'In Ramp';
    } else if (isEmpty) {
      statusDesc = 'Empty';
    } else {
      statusDesc = 'Loaded';
    }

    if (updateLocation) {
      // Get current location
      final locationResult = await getCurrentLocationUseCase();

      await locationResult.fold(
        (failure) async {
          state = state.copyWith(
            isUpdatingStatus: false,
            error: 'Failed to get current location: ${failure.message}',
          );
        },
        (locationData) async {
          // Get address from coordinates
          String? address;
          final addressResult = await getAddressUseCase(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
          );
          addressResult.fold(
            (failure) => address = null,
            (addr) => address = addr,
          );

          // Update trailer with new status and location
          final result = await updateTrailerStatusUseCase(
            trailerId: trailerId,
            trailerNumber: trailer.trailerNumber,
            terminal: entry.terminal,
            isEmpty: isEmpty,
            isInRamp: isInRamp,
            rampNumber: rampNumber,
            latitude: locationData.latitude,
            longitude: locationData.longitude,
            address: address,
            notes: 'Status changed to $statusDesc',
          );

          result.fold(
            (failure) {
              state = state.copyWith(
                isUpdatingStatus: false,
                error: failure.message,
              );
            },
            (newEntry) {
              state = state.copyWith(
                isUpdatingStatus: false,
                successMessage: 'Status updated to $statusDesc',
              );
              // Refresh data to show new entry
              refresh(trailerId);
            },
          );
        },
      );
    } else {
      // Keep existing location
      final result = await updateTrailerStatusUseCase(
        trailerId: trailerId,
        trailerNumber: trailer.trailerNumber,
        terminal: entry.terminal,
        isEmpty: isEmpty,
        isInRamp: isInRamp,
        rampNumber: rampNumber,
        latitude: entry.latitude,
        longitude: entry.longitude,
        address: entry.address,
        notes: 'Status changed to $statusDesc',
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isUpdatingStatus: false,
            error: failure.message,
          );
        },
        (newEntry) {
          state = state.copyWith(
            isUpdatingStatus: false,
            successMessage: 'Status updated to $statusDesc',
          );
          // Refresh data to show new entry
          refresh(trailerId);
        },
      );
    }
  }

  /// Update trailer terminal/location (keeps same GPS and isEmpty status)
  Future<void> updateTerminal(String trailerId, String newTerminal) async {
    final trailer = state.trailer;
    if (trailer == null) {
      state = state.copyWith(error: 'No trailer data available');
      return;
    }

    state = state.copyWith(
      isUpdatingStatus: true,
      error: null,
      successMessage: null,
    );

    final entry = trailer.latestEntry;

    final result = await updateTrailerStatusUseCase(
      trailerId: trailerId,
      trailerNumber: trailer.trailerNumber,
      terminal: newTerminal,
      isEmpty: entry.isEmpty, // Keep same empty status
      latitude: entry.latitude, // Keep same coordinates
      longitude: entry.longitude,
      address: entry.address, // Keep same address
      notes: 'Terminal/location updated to $newTerminal',
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isUpdatingStatus: false,
          error: failure.message,
        );
      },
      (newEntry) {
        state = state.copyWith(
          isUpdatingStatus: false,
          successMessage: 'Location updated to $newTerminal',
        );
        // Refresh data to show new entry
        refresh(trailerId);
      },
    );
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider for trailer detail
final trailerDetailProvider =
    StateNotifierProvider.family<TrailerDetailNotifier, TrailerDetailState, String>(
  (ref, trailerId) {
    final getDetail = ref.watch(getTrailerDetailProvider);
    final getHistory = ref.watch(getTrailerHistoryProvider);
    final updateStatus = ref.watch(updateTrailerStatusProvider);
    final getLocation = ref.watch(getCurrentLocationProvider);
    final getAddress = ref.watch(getAddressFromCoordinatesProvider);

    final notifier = TrailerDetailNotifier(
      getDetail,
      getHistory,
      updateStatus,
      getLocation,
      getAddress,
    );

    // Auto-load trailer when provider is created
    Future.microtask(() => notifier.loadTrailer(trailerId));

    return notifier;
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../../domain/usecases/get_trailer_history.dart';
import '../../../../core/providers/providers.dart';

/// State for trailer history with pagination
class TrailerHistoryState {
  final List<TrailerEntry> history;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;

  const TrailerHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.total = 0,
    this.offset = 0,
    this.limit = 20,
    this.hasMore = false,
  });

  TrailerHistoryState copyWith({
    List<TrailerEntry>? history,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? total,
    int? offset,
    int? limit,
    bool? hasMore,
  }) {
    return TrailerHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier for managing trailer history with pagination
class TrailerHistoryNotifier extends StateNotifier<TrailerHistoryState> {
  final GetTrailerHistory getTrailerHistoryUseCase;
  final String trailerId;

  TrailerHistoryNotifier(
    this.getTrailerHistoryUseCase,
    this.trailerId,
  ) : super(const TrailerHistoryState());

  /// Load initial history
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await getTrailerHistoryUseCase(trailerId, limit: state.limit, offset: 0);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (response) {
        state = state.copyWith(
          history: response.data,
          total: response.pagination.total,
          offset: response.pagination.offset + response.data.length,
          hasMore: response.pagination.hasMore,
          isLoading: false,
        );
      },
    );
  }

  /// Load more history (for infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await getTrailerHistoryUseCase(
      trailerId,
      limit: state.limit,
      offset: state.offset,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          error: failure.message,
        );
      },
      (response) {
        final updatedHistory = [...state.history, ...response.data];
        state = state.copyWith(
          history: updatedHistory,
          total: response.pagination.total,
          offset: state.offset + response.data.length,
          hasMore: response.pagination.hasMore,
          isLoadingMore: false,
        );
      },
    );
  }

  /// Refresh history (pull-to-refresh)
  Future<void> refresh() async {
    state = const TrailerHistoryState();
    await loadHistory();
  }
}

/// Provider for trailer history
final trailerHistoryProvider =
    StateNotifierProvider.family<TrailerHistoryNotifier, TrailerHistoryState, String>(
  (ref, trailerId) {
    final getHistory = ref.watch(getTrailerHistoryProvider);

    final notifier = TrailerHistoryNotifier(getHistory, trailerId);

    // Auto-load history when provider is created
    Future.microtask(() => notifier.loadHistory());

    return notifier;
  },
);

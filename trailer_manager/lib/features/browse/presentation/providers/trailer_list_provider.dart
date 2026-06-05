import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trailer.dart';
import '../../domain/usecases/get_trailers.dart';
import '../../../../core/providers/providers.dart';

/// State for trailer list
class TrailerListState {
  final List<Trailer> trailers;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const TrailerListState({
    this.trailers = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  TrailerListState copyWith({
    List<Trailer>? trailers,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return TrailerListState(
      trailers: trailers ?? this.trailers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for managing trailer list state
class TrailerListNotifier extends StateNotifier<TrailerListState> {
  final GetTrailers getTrailersUseCase;

  TrailerListNotifier(this.getTrailersUseCase) : super(const TrailerListState());

  /// Load trailers
  Future<void> loadTrailers({
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
    bool refresh = false,
  }) async {
    // If refreshing, reset state
    if (refresh) {
      state = const TrailerListState(isLoading: true);
    } else if (state.isLoading) {
      return; // Already loading
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await getTrailersUseCase(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      page: refresh ? 1 : state.currentPage,
      limit: 1000,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (trailers) {
        state = state.copyWith(
          trailers: refresh ? trailers : [...state.trailers, ...trailers],
          isLoading: false,
          error: null,
          hasMore: trailers.length >= 1000,
          currentPage: refresh ? 1 : state.currentPage + 1,
        );
      },
    );
  }

  /// Load more trailers (pagination)
  Future<void> loadMore({
    String? trailerNumber,
    String? terminal,
    bool? isEmpty,
  }) async {
    if (!state.hasMore || state.isLoading) return;

    await loadTrailers(
      trailerNumber: trailerNumber,
      terminal: terminal,
      isEmpty: isEmpty,
      refresh: false,
    );
  }

  /// Refresh trailers
  Future<void> refresh() async {
    await loadTrailers(refresh: true);
  }
}

/// Provider for trailer list
final trailerListProvider = StateNotifierProvider<TrailerListNotifier, TrailerListState>((ref) {
  final getTrailers = ref.watch(getTrailersProvider);
  return TrailerListNotifier(getTrailers);
});

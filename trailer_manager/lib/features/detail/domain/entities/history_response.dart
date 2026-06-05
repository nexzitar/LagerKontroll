import '../../../capture/domain/entities/trailer_entry.dart';

/// Pagination information for history response
class HistoryPagination {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  const HistoryPagination({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });
}

/// Response for paginated history
class HistoryResponse {
  final List<TrailerEntry> data;
  final HistoryPagination pagination;

  const HistoryResponse({
    required this.data,
    required this.pagination,
  });
}

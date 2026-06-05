import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../providers/history_provider.dart';
import '../widgets/fullscreen_photo_viewer.dart';

/// Screen for viewing complete trailer history with pagination
class TrailerHistoryScreen extends ConsumerStatefulWidget {
  final String trailerId;
  final String trailerNumber;

  const TrailerHistoryScreen({
    super.key,
    required this.trailerId,
    required this.trailerNumber,
  });

  @override
  ConsumerState<TrailerHistoryScreen> createState() => _TrailerHistoryScreenState();
}

class _TrailerHistoryScreenState extends ConsumerState<TrailerHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from bottom
      final state = ref.read(trailerHistoryProvider(widget.trailerId));
      if (!state.isLoadingMore && state.hasMore) {
        ref.read(trailerHistoryProvider(widget.trailerId).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailerHistoryProvider(widget.trailerId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.trailerNumber} History'),
      ),
      body: state.isLoading && state.history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.history.isEmpty
              ? _buildErrorState(state.error!)
              : state.history.isEmpty
                  ? const Center(child: Text('No history available'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(trailerHistoryProvider(widget.trailerId).notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.history.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.history.length) {
                            // Loading indicator at bottom
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildHistoryCard(state.history[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(trailerHistoryProvider(widget.trailerId).notifier)
                  .refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(TrailerEntry entry) {
    final dateFormat = DateFormat(AppConstants.displayDateTimeFormat);
    final baseUrl = EnvironmentConfig.current.apiBaseUrl.replaceAll('/api/v1', '');
    final fullImageUrl = '$baseUrl${entry.photoUrl}';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConfig.defaultPadding,
        vertical: AppConfig.smallPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          if (entry.photoUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenPhotoViewer(
                      photoUrl: fullImageUrl,
                      heroTag: 'history_photo_${entry.id}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'history_photo_${entry.id}',
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(entry.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location and Status
                Row(
                  children: [
                    // Terminal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.terminal,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Empty/Full status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.isEmpty ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.isEmpty ? 'Empty' : 'Full',
                        style: TextStyle(
                          color: entry.isEmpty ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Notes (if any)
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],

                // Address (if any)
                if (entry.address != null && entry.address!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.address!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

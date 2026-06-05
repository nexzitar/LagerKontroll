import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/admin_panel_screen.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../capture/presentation/screens/capture_screen.dart';
import '../../../detail/presentation/screens/trailer_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../map/presentation/screens/map_view_screen.dart';
import '../../domain/entities/trailer.dart';
import '../providers/trailer_list_provider.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/network/dio_client.dart';

/// Trailer list screen connected to backend
class TrailerListScreen extends ConsumerStatefulWidget {
  const TrailerListScreen({super.key});

  @override
  ConsumerState<TrailerListScreen> createState() => _TrailerListScreenState();
}

class _TrailerListScreenState extends ConsumerState<TrailerListScreen> {
  String? _selectedTerminal;
  bool? _selectedEmptyStatus;
  bool _selectedInRampStatus = false;
  String _sortBy = 'date';
  bool _isLsoFilter = false;
  static bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    // Load trailers when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trailerListProvider.notifier).loadTrailers(refresh: true);

      // Check for updates once per app session
      if (!_hasCheckedForUpdate) {
        _checkForUpdate();
        _hasCheckedForUpdate = true;
      }
    });
  }

  /// Check for app updates and show dialog if available
  Future<void> _checkForUpdate() async {
    try {
      final updateService = UpdateService(dioClient);
      final updateInfo = await updateService.checkForUpdate();

      if (updateInfo != null &&
          updateInfo['updateAvailable'] == true &&
          mounted) {
        _showUpdateDialog(
          latestVersion: updateInfo['latestVersion'] as String,
          currentVersion: updateInfo['currentVersion'] as String,
          downloadUrl: updateInfo['downloadUrl'] as String,
        );
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
      // Errors are already logged in UpdateService
    }
  }

  /// Show update available dialog
  void _showUpdateDialog({
    required String latestVersion,
    required String currentVersion,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'A new version ($latestVersion) is available.\nCurrent version: $currentVersion',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadAndInstallUpdate(downloadUrl, latestVersion);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Download and install the update with progress indicator
  Future<void> _downloadAndInstallUpdate(String downloadUrl, String version) async {
    final updateService = UpdateService(dioClient);
    int downloadedBytes = 0;
    int totalBytes = 0;

    // Show download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Downloading Update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: totalBytes > 0 ? downloadedBytes / totalBytes : null,
                ),
                const SizedBox(height: 16),
                Text(
                  totalBytes > 0
                      ? '${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB'
                      : 'Starting download...',
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $version',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Download the APK
      final filePath = await updateService.downloadUpdate(
        downloadUrl,
        onProgress: (received, total) {
          downloadedBytes = received;
          totalBytes = total;
          // Force rebuild of dialog
          if (mounted) {
            setState(() {});
          }
        },
      );

      // Close download dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (filePath != null) {
        // Show installing message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download complete. Installing...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Install the APK
        final installed = await updateService.installApk(filePath);
        if (!installed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to launch installer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close download dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailerListProvider);
    final authState = ref.watch(authProvider);

    // Get trailers from state (create a mutable copy)
    var trailers = List.from(state.trailers);

    // Apply filters
    if (_isLsoFilter) {
      trailers = trailers
          .where((t) => AppConfig.lsoTerminals.contains(t.latestEntry.terminal))
          .toList();
    } else if (_selectedTerminal != null) {
      trailers = trailers
          .where((t) => t.latestEntry.terminal == _selectedTerminal)
          .toList();
    }

    if (_selectedEmptyStatus != null) {
      if (_selectedEmptyStatus == true) {
        // Empty filter
        trailers = trailers
            .where((t) => t.latestEntry.isEmpty == true && t.latestEntry.isInRamp == false)
            .toList();
      } else {
        // Loaded filter
        trailers = trailers
            .where((t) => t.latestEntry.isEmpty == false && t.latestEntry.isInRamp == false)
            .toList();
      }
    }

    // Apply In Ramp filter if selected
    if (_selectedInRampStatus) {
      trailers = trailers
          .where((t) => t.latestEntry.isInRamp == true)
          .toList();
    }

    // Calculate counts from the FULL list (state.trailers), not filtered
    final emptyCount = state.trailers.where((t) => t.latestEntry.isEmpty == true && t.latestEntry.isInRamp == false).length;
    final loadedCount = state.trailers.where((t) => t.latestEntry.isEmpty == false && t.latestEntry.isInRamp == false).length;
    final inRampCount = state.trailers.where((t) => t.latestEntry.isInRamp == true).length;
    final totalCount = state.trailers.length;

    // Apply sorting
    if (_sortBy == 'date') {
      trailers.sort((a, b) => b.latestEntry.createdAt.compareTo(a.latestEntry.createdAt));
    } else if (_sortBy == 'date_oldest') {
      trailers.sort((a, b) => a.latestEntry.createdAt.compareTo(b.latestEntry.createdAt));
    } else if (_sortBy == 'name') {
      trailers.sort((a, b) => a.trailerNumber.compareTo(b.trailerNumber));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // Account button
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'admin') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              } else if (value == 'change-password') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
                // User will be automatically redirected to login screen
                // because main.dart watches authProvider
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.user?.name ?? 'User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      authState.user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Admin Panel (only for admins)
              if (authState.user?.isAdmin == true) ...[
                const PopupMenuItem<String>(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings),
                      SizedBox(width: 8),
                      Text('Admin Panel'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              // Change Password
              const PopupMenuItem<String>(
                value: 'change-password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapViewScreen(),
                ),
              );
            },
            tooltip: 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.local_shipping),
            onPressed: () {
              Navigator.pushNamed(context, '/module-capture');
            },
            tooltip: 'Module Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trailerListProvider.notifier).refresh();
        },
        child: state.isLoading && state.trailers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.trailers.isEmpty
                ? _buildErrorState(state.error!)
                : state.trailers.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildSummaryCard(emptyCount, loadedCount, inRampCount, totalCount),
                          Expanded(
                            child: trailers.isEmpty
                                ? _buildFilteredEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(AppConfig.smallPadding),
                                    itemCount: trailers.length,
                                    itemBuilder: (context, index) {
                                      final trailer = trailers[index];
                                      return _buildTrailerCard(trailer);
                                    },
                                  ),
                          ),
                        ],
                      ),
      ),
      floatingActionButton: authState.user?.isGuest == true
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CaptureScreen(),
                  ),
                );

                // Refresh list if entry was created
                if (result == true && mounted) {
                  ref.read(trailerListProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entry created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('New Entry'),
            ),
    );
  }

  Widget _buildSummaryCard(int emptyCount, int loadedCount, int inRampCount, int totalCount) {
    // Determine which filter is active
    final isEmptyActive = _selectedEmptyStatus == true && !_selectedInRampStatus;
    final isLoadedActive = _selectedEmptyStatus == false && !_selectedInRampStatus;
    final isInRampActive = _selectedInRampStatus;
    final isAllActive = _selectedEmptyStatus == null && !_selectedInRampStatus;

    return Container(
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.defaultPadding,
        vertical: AppConfig.smallPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Empty',
            emptyCount,
            Colors.green,
            isActive: isEmptyActive,
            onTap: () {
              setState(() {
                if (isEmptyActive) {
                  // Already active, clear filter
                  _selectedEmptyStatus = null;
                } else {
                  _selectedEmptyStatus = true;
                  _selectedInRampStatus = false;
                }
              });
            },
          ),
          _buildDivider(),
          _buildSummaryItem(
            'Loaded',
            loadedCount,
            Colors.orange,
            isActive: isLoadedActive,
            onTap: () {
              setState(() {
                if (isLoadedActive) {
                  _selectedEmptyStatus = null;
                } else {
                  _selectedEmptyStatus = false;
                  _selectedInRampStatus = false;
                }
              });
            },
          ),
          _buildDivider(),
          _buildSummaryItem(
            'In Ramp',
            inRampCount,
            Colors.blue,
            isActive: isInRampActive,
            onTap: () {
              setState(() {
                if (isInRampActive) {
                  _selectedInRampStatus = false;
                } else {
                  _selectedInRampStatus = true;
                  _selectedEmptyStatus = null;
                }
              });
            },
          ),
          _buildDivider(),
          _buildSummaryItem(
            'All',
            totalCount,
            Theme.of(context).colorScheme.primary,
            isActive: isAllActive,
            onTap: () {
              setState(() {
                _selectedEmptyStatus = null;
                _selectedInRampStatus = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailerCard(Trailer trailer) {
    final entry = trailer.latestEntry;
    final dateFormat = DateFormat(AppConstants.displayDateTimeFormat);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.defaultPadding),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TrailerDetailScreen(
                trailerId: trailer.id,
                trailerNumber: trailer.trailerNumber,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: entry.thumbnailUrl != null
                      ? Image.network(
                          entry.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.local_shipping, size: 40);
                          },
                        )
                      : const Icon(Icons.local_shipping, size: 40),
                ),
              ),
              const SizedBox(width: AppConfig.defaultPadding),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trailer Number
                    Text(
                      trailer.trailerNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),

                    // Terminal
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          AppConstants.getTerminalName(entry.terminal),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Status
                    Row(
                      children: [
                        Icon(
                          entry.isInRamp
                              ? Icons.warehouse
                              : (entry.isEmpty ? Icons.check_circle : Icons.inventory_2),
                          size: 16,
                          color: entry.isInRamp
                              ? Colors.blue
                              : (entry.isEmpty ? Colors.green : Colors.orange),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.isInRamp
                              ? 'In Ramp${entry.rampNumber != null ? " (${entry.rampNumber})" : ""}'
                              : (entry.isEmpty ? 'Empty' : 'Loaded'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: entry.isInRamp
                                    ? Colors.blue
                                    : (entry.isEmpty ? Colors.green : Colors.orange),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Timestamp
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(entry.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),

                    // Entry Count
                    const SizedBox(height: 4),
                    Text(
                      '${trailer.entryCount} entries',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    String filterName = 'selected filter';
    if (_selectedEmptyStatus == true) {
      filterName = 'Empty';
    } else if (_selectedEmptyStatus == false) {
      filterName = 'Loaded';
    } else if (_selectedInRampStatus) {
      filterName = 'In Ramp';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConfig.defaultPadding),
            Text(
              'No "$filterName" trailers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConfig.smallPadding),
            Text(
              'Tap "All" above to see all trailers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final authState = ref.watch(authProvider);
    final isGuest = authState.user?.isGuest == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConfig.largePadding),
            Text(
              'No trailers found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.smallPadding),
            Text(
              isGuest
                  ? 'No trailer entries are available at this time'
                  : 'Add a new trailer entry to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (!isGuest) ...[
              const SizedBox(height: AppConfig.largePadding),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CaptureScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Create Entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 100, color: Colors.red),
            const SizedBox(height: AppConfig.largePadding),
            Text(
              'Error loading trailers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.smallPadding),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.largePadding),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(trailerListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Terminal Filter
                Text('Terminal', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedTerminal == null && !_isLsoFilter,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedTerminal = null;
                          _isLsoFilter = false;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('LSO'),
                      selected: _isLsoFilter,
                      onSelected: (selected) {
                        setDialogState(() {
                          _isLsoFilter = selected;
                          if (selected) {
                            _selectedTerminal = null;
                          }
                        });
                      },
                    ),
                    ...AppConfig.terminals.map((terminal) {
                      return FilterChip(
                        label: Text(terminal),
                        selected: _selectedTerminal == terminal && !_isLsoFilter,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedTerminal = selected ? terminal : null;
                            if (selected) {
                              _isLsoFilter = false;
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Filter
                Text('Status', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedEmptyStatus == null && !_selectedInRampStatus,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedEmptyStatus = null;
                          _selectedInRampStatus = false;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Empty'),
                      selected: _selectedEmptyStatus == true && !_selectedInRampStatus,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedEmptyStatus = selected ? true : null;
                          _selectedInRampStatus = false;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Loaded'),
                      selected: _selectedEmptyStatus == false && !_selectedInRampStatus,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedEmptyStatus = selected ? false : null;
                          _selectedInRampStatus = false;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('In Ramp'),
                      selected: _selectedInRampStatus,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedInRampStatus = selected;
                          if (selected) {
                            _selectedEmptyStatus = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sort By
                Text('Sort by', style: Theme.of(context).textTheme.titleSmall),
                RadioListTile<String>(
                  title: const Text('Date (newest first)'),
                  value: 'date',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() => _sortBy = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Date (oldest first)'),
                  value: 'date_oldest',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() => _sortBy = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Trailer number'),
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() => _sortBy = value!);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTerminal = null;
                _selectedEmptyStatus = null;
                _selectedInRampStatus = false;
                _sortBy = 'date';
                _isLsoFilter = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

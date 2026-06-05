import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/terminal_geofence_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../browse/presentation/providers/trailer_list_provider.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../providers/detail_provider.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import 'trailer_history_screen.dart';

/// Trailer detail screen with map and history
class TrailerDetailScreen extends ConsumerStatefulWidget {
  final String trailerId;
  final String trailerNumber;

  const TrailerDetailScreen({
    super.key,
    required this.trailerId,
    required this.trailerNumber,
  });

  @override
  ConsumerState<TrailerDetailScreen> createState() => _TrailerDetailScreenState();
}

class _TrailerDetailScreenState extends ConsumerState<TrailerDetailScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailerDetailProvider(widget.trailerId));
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;
    final isGuest = authState.user?.isGuest ?? false;

    // Listen for state changes to show messages
    ref.listen<TrailerDetailState>(
      trailerDetailProvider(widget.trailerId),
      (previous, next) {
        if (next.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Clear message after showing
          Future.delayed(const Duration(milliseconds: 100), () {
            ref
                .read(trailerDetailProvider(widget.trailerId).notifier)
                .clearMessages();
          });
        }
        if (next.error != null && !next.isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: isGuest
            ? Text(widget.trailerNumber)
            : GestureDetector(
                onTap: () => _showEditTrailerNumberDialog(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.trailerNumber),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 16),
                  ],
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isUpdatingStatus
                ? null
                : () {
                    ref
                        .read(trailerDetailProvider(widget.trailerId).notifier)
                        .refresh(widget.trailerId);
                  },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: state.isLoading ? null : () => _showDeleteDialog(),
              tooltip: 'Delete trailer',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.trailer == null
              ? _buildErrorState(state.error!)
              : state.trailer == null
                  ? const Center(child: Text('No data available'))
                  : _buildContent(state),
    );
  }

  Widget _buildContent(TrailerDetailState state) {
    final trailer = state.trailer!;
    final entry = trailer.latestEntry;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(trailerDetailProvider(widget.trailerId).notifier)
            .refresh(widget.trailerId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Section
            _buildPhotoSection(entry.photoUrl),

            // Map Section
            _buildMapSection(entry.latitude, entry.longitude, entry.address, entry.terminal),

            // Information Section
            _buildInformationSection(entry),

            // Actions Section
            _buildActionsSection(state),

            // History Section
            _buildHistorySection(state.history, state.isLoadingHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String photoUrl) {
    return GestureDetector(
      onTap: () {
        if (photoUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullscreenPhotoViewer(
                photoUrl: photoUrl,
                heroTag: 'trailer_photo_${widget.trailerId}',
              ),
            ),
          );
        }
      },
      child: Hero(
        tag: 'trailer_photo_${widget.trailerId}',
        child: Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey[300],
          child: photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                )
              : const Center(
                  child: Icon(Icons.local_shipping, size: 50, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  Widget _buildMapSection(double latitude, double longitude, String? address, String terminal) {
    final position = LatLng(latitude, longitude);
    final terminalBounds = TerminalGeofenceService.getTerminalBounds(terminal);

    return Container(
      height: 250,
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
        child: GoogleMap(
          mapType: MapType.satellite,
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: AppConfig.detailMapZoom,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('trailer_location'),
              position: position,
              infoWindow: InfoWindow(
                title: widget.trailerNumber,
                snippet: address ?? 'Trailer location',
              ),
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
            // If terminal bounds are known, zoom to show entire terminal
            if (terminalBounds != null) {
              Future.delayed(const Duration(milliseconds: 300), () {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(terminalBounds.swLat, terminalBounds.swLon),
                      northeast: LatLng(terminalBounds.neLat, terminalBounds.neLon),
                    ),
                    10, // minimal padding to show just the terminal
                  ),
                );
              });
            }
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildInformationSection(TrailerEntry entry) {
    final dateFormat = DateFormat(AppConstants.displayDateTimeFormat);
    final authState = ref.watch(authProvider);
    final isGuest = authState.user?.isGuest ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
              child: Column(
                children: [
                  InkWell(
                    onTap: isGuest ? null : () => _showEditTerminalDialog(entry.terminal),
                    child: _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Terminal',
                      value: entry.terminal,
                      color: Theme.of(context).colorScheme.primary,
                      trailing: isGuest
                          ? null
                          : Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: entry.isInRamp
                        ? Icons.warehouse
                        : (entry.isEmpty ? Icons.check_circle : Icons.inventory_2),
                    label: 'Status',
                    value: entry.isInRamp
                        ? 'In Ramp'
                        : (entry.isEmpty ? 'Empty' : 'Loaded'),
                    color: entry.isInRamp
                        ? Colors.blue
                        : (entry.isEmpty ? Colors.green : Colors.orange),
                  ),
                  if (entry.isInRamp && entry.rampNumber != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.numbers,
                      label: 'Ramp Number',
                      value: entry.rampNumber!,
                      color: Colors.blue,
                    ),
                  ],
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Last Updated',
                    value: dateFormat.format(entry.createdAt.toLocal()),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Updated By',
                    value: entry.createdBy ?? 'Unknown',
                  ),
                  if (entry.address != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.place,
                      label: 'Address',
                      value: entry.address!,
                    ),
                  ],
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.gps_fixed,
                    label: 'Coordinates',
                    value:
                        '${entry.latitude.toStringAsFixed(6)}, ${entry.longitude.toStringAsFixed(6)}',
                    valueStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.notes,
                      label: 'Notes',
                      value: entry.notes!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    TextStyle? valueStyle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConfig.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: AppConfig.defaultPadding),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                      ),
              textAlign: TextAlign.right,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppConfig.smallPadding),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(TrailerDetailState state) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.user?.isGuest ?? false;
    final isUpdating = state.isUpdatingStatus;
    final trailer = state.trailer!;
    final isCurrentlyEmpty = trailer.latestEntry.isEmpty;

    // Guest users cannot perform actions
    if (isGuest) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          if (isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConfig.defaultPadding),
                child: CircularProgressIndicator(),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditStatusDialog(trailer.latestEntry),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Status'),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditStatusDialog(dynamic entry) {
    // Determine current status: 0 = Empty, 1 = Loaded, 2 = In Ramp
    int currentStatus;
    if (entry.isInRamp) {
      currentStatus = 2;
    } else if (entry.isEmpty) {
      currentStatus = 0;
    } else {
      currentStatus = 1;
    }

    int selectedStatus = currentStatus;
    bool updateLocation = true; // Default to updating location
    final rampNumberController = TextEditingController(
      text: entry.rampNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Empty'),
                    icon: Icon(Icons.check_circle),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Loaded'),
                    icon: Icon(Icons.inventory_2),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text('In Ramp'),
                    icon: Icon(Icons.dock),
                  ),
                ],
                selected: {selectedStatus},
                onSelectionChanged: (Set<int> newSelection) {
                  setDialogState(() {
                    selectedStatus = newSelection.first;
                  });
                },
              ),
              if (selectedStatus == 2) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: rampNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Ramp Number (optional)',
                    hintText: 'e.g., 3, A1',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Update location'),
                subtitle: const Text('Use current GPS position'),
                value: updateLocation,
                onChanged: (value) {
                  setDialogState(() {
                    updateLocation = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(trailerDetailProvider(widget.trailerId).notifier)
                    .updateStatus(
                      widget.trailerId,
                      isEmpty: selectedStatus == 0,
                      isInRamp: selectedStatus == 2,
                      rampNumber: selectedStatus == 2
                          ? rampNumberController.text.trim()
                          : null,
                      updateLocation: updateLocation,
                    );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTerminalDialog(String currentTerminal) {
    final terminalController = TextEditingController(text: currentTerminal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location'),
        content: Autocomplete<String>(
          initialValue: TextEditingValue(text: currentTerminal),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return AppConfig.terminals;
            }
            return AppConfig.terminals.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            terminalController.text = selection;
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Sync with our terminal controller
            if (terminalController.text.isNotEmpty && textEditingController.text.isEmpty) {
              textEditingController.text = terminalController.text;
            }
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Terminal / Location',
                hintText: 'e.g., B1, B3, Ramp 5',
                prefixIcon: Icon(Icons.location_on),
                helperText: 'Enter terminal or custom location',
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                terminalController.text = value;
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTerminal = terminalController.text.toUpperCase().trim();
              if (newTerminal.isNotEmpty && newTerminal != currentTerminal) {
                Navigator.pop(context);
                ref
                    .read(trailerDetailProvider(widget.trailerId).notifier)
                    .updateTerminal(widget.trailerId, newTerminal);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      terminalController.dispose();
    });
  }

  Widget _buildHistorySection(List history, bool isLoading) {
    final dateFormat = DateFormat(AppConstants.displayDateTimeFormat);

    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrailerHistoryScreen(
                        trailerId: widget.trailerId,
                        trailerNumber: widget.trailerNumber,
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppConfig.smallPadding),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConfig.largePadding),
                child: CircularProgressIndicator(),
              ),
            )
          else if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.largePadding),
                child: Text(
                  'No history available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppConfig.smallPadding),
              itemBuilder: (context, index) {
                final entry = history[index];
                final Color statusColor = entry.isInRamp
                    ? Colors.blue
                    : (entry.isEmpty ? Colors.green : Colors.orange);
                final IconData statusIcon = entry.isInRamp
                    ? Icons.warehouse
                    : (entry.isEmpty ? Icons.check : Icons.inventory_2);
                final String statusLabel = entry.isInRamp
                    ? 'In Ramp${entry.rampNumber != null ? " (${entry.rampNumber})" : ""}'
                    : (entry.isEmpty ? 'Empty' : 'Loaded');

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppConstants.getTerminalName(entry.terminal),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      dateFormat.format(entry.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Chip(
                      label: Text(statusLabel, style: const TextStyle(fontSize: 12)),
                      backgroundColor: statusColor,
                      labelStyle: const TextStyle(color: Colors.white),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
        ],
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
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: AppConfig.defaultPadding),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
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
                ref
                    .read(trailerDetailProvider(widget.trailerId).notifier)
                    .refresh(widget.trailerId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTrailerNumber(String newTrailerNumber) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.put(
        '/trailers/${widget.trailerId}/number',
        data: {'newTrailerNumber': newTrailerNumber},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trailer renamed to $newTrailerNumber'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh trailer list
        await ref.read(trailerListProvider.notifier).refresh();

        // Navigate back and let user re-open with new name
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming trailer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditTrailerNumberDialog() {
    final controller = TextEditingController(text: widget.trailerNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Trailer Number'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Trailer Number',
            hintText: 'Enter new trailer number',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newNumber = controller.text.trim().toUpperCase();
              if (newNumber.length >= 3) {
                Navigator.of(context).pop();
                _updateTrailerNumber(newNumber);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrailer() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.delete('/trailers/${widget.trailerId}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trailer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh trailer list to remove the deleted item
        await ref.read(trailerListProvider.notifier).refresh();

        // Navigate back to previous screen
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting trailer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trailer'),
        content: Text(
          'Are you sure you want to delete trailer "${widget.trailerNumber}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTrailer();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

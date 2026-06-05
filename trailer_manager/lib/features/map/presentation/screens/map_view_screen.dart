import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/terminal_geofence_service.dart';
import '../../../browse/presentation/providers/trailer_list_provider.dart';
import '../../../browse/domain/entities/trailer.dart';
import '../../../detail/presentation/screens/trailer_detail_screen.dart';

/// Map view screen showing trailers on a map by terminal
class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  GoogleMapController? _mapController;
  String _selectedTerminal = 'LSO'; // LSO means all B1-B5
  final List<String> _terminalOptions = ['LSO', 'B1', 'B2', 'B3', 'B4', 'B5', 'ØT'];

  @override
  void initState() {
    super.initState();
    // Load trailers when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trailerListProvider.notifier).loadTrailers(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailerListProvider);

    // Filter trailers by selected terminal
    var trailers = state.trailers;
    if (_selectedTerminal != 'LSO') {
      trailers = trailers
          .where((t) => t.latestEntry.terminal == _selectedTerminal)
          .toList();
    } else {
      // LSO means all B1-B5 terminals
      trailers = trailers
          .where((t) => ['B1', 'B2', 'B3', 'B4', 'B5'].contains(t.latestEntry.terminal))
          .toList();
    }

    // Create markers for trailers
    final markers = _createMarkers(trailers);

    // Get bounds for the selected terminal(s)
    final bounds = _getTerminalBounds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trailer Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(trailerListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Terminal selector
          Container(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: AppConfig.smallPadding),
                const Text(
                  'Terminal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: AppConfig.defaultPadding),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTerminal,
                    isExpanded: true,
                    items: _terminalOptions.map((terminal) {
                      return DropdownMenuItem<String>(
                        value: terminal,
                        child: Text(
                          terminal == 'LSO' ? 'LSO (All B1-B5)' : terminal,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTerminal = value;
                        });
                        // Zoom to the new terminal bounds
                        _zoomToBounds(bounds);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.defaultPadding,
              vertical: AppConfig.smallPadding,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red, 'Loaded'),
                const SizedBox(width: AppConfig.defaultPadding),
                _buildLegendItem(Colors.green, 'Empty'),
                const SizedBox(width: AppConfig.defaultPadding),
                _buildLegendItem(Colors.yellow, 'In Ramp'),
                const SizedBox(width: AppConfig.defaultPadding),
                Text(
                  '${trailers.length} trailers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: state.isLoading && trailers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : trailers.isEmpty
                    ? _buildEmptyState()
                    : GoogleMap(
                        mapType: MapType.satellite,
                        initialCameraPosition: CameraPosition(
                          target: _getInitialTarget(bounds),
                          zoom: AppConfig.defaultMapZoom,
                        ),
                        markers: markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          // Zoom to bounds after map is created
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _zoomToBounds(bounds);
                          });
                        },
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConfig.largePadding),
            Text(
              'No trailers in ${_selectedTerminal == 'LSO' ? 'LSO terminals' : _selectedTerminal}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.smallPadding),
            Text(
              'Try selecting a different terminal',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _createMarkers(List<Trailer> trailers) {
    final markers = <Marker>{};

    for (final trailer in trailers) {
      final entry = trailer.latestEntry;
      final position = LatLng(entry.latitude, entry.longitude);

      // Determine marker color based on status
      final double hue;
      final String statusText;
      if (entry.isInRamp) {
        hue = BitmapDescriptor.hueYellow;
        statusText = 'In Ramp${entry.rampNumber != null ? " (${entry.rampNumber})" : ""}';
      } else if (entry.isEmpty) {
        hue = BitmapDescriptor.hueGreen;
        statusText = 'Empty';
      } else {
        hue = BitmapDescriptor.hueRed;
        statusText = 'Loaded';
      }

      markers.add(
        Marker(
          markerId: MarkerId(trailer.id),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: trailer.trailerNumber,
            snippet: '${entry.terminal} - $statusText',
          ),
          onTap: () {
            // Show bottom sheet with trailer details
            _showTrailerDetails(trailer);
          },
        ),
      );
    }

    return markers;
  }

  void _showTrailerDetails(Trailer trailer) {
    final entry = trailer.latestEntry;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConfig.largePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trailer.trailerNumber,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConfig.defaultPadding),
            _buildDetailRow(Icons.location_on, 'Terminal', entry.terminal),
            _buildDetailRow(
              entry.isInRamp
                  ? Icons.warehouse
                  : (entry.isEmpty ? Icons.check_circle : Icons.inventory_2),
              'Status',
              entry.isInRamp
                  ? 'In Ramp${entry.rampNumber != null ? " (${entry.rampNumber})" : ""}'
                  : (entry.isEmpty ? 'Empty' : 'Loaded'),
              color: entry.isInRamp
                  ? Colors.blue
                  : (entry.isEmpty ? Colors.green : Colors.orange),
            ),
            if (entry.address != null)
              _buildDetailRow(Icons.place, 'Address', entry.address!),
            const SizedBox(height: AppConfig.largePadding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to trailer detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrailerDetailScreen(
                        trailerId: trailer.id,
                        trailerNumber: trailer.trailerNumber,
                      ),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConfig.smallPadding),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: AppConfig.smallPadding),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  /// Get bounds for the selected terminal(s)
  ({double swLat, double swLon, double neLat, double neLon})? _getTerminalBounds() {
    if (_selectedTerminal == 'LSO') {
      // Calculate combined bounds for B1-B5
      return _getCombinedBounds(['B1', 'B2', 'B3', 'B4', 'B5']);
    } else {
      return TerminalGeofenceService.getTerminalBounds(_selectedTerminal);
    }
  }

  /// Calculate combined bounds for multiple terminals
  ({double swLat, double swLon, double neLat, double neLon})? _getCombinedBounds(
      List<String> terminals) {
    double? minLat;
    double? maxLat;
    double? minLon;
    double? maxLon;

    for (final terminal in terminals) {
      final bounds = TerminalGeofenceService.getTerminalBounds(terminal);
      if (bounds != null) {
        minLat = minLat == null ? bounds.swLat : (minLat < bounds.swLat ? minLat : bounds.swLat);
        maxLat = maxLat == null ? bounds.neLat : (maxLat > bounds.neLat ? maxLat : bounds.neLat);
        minLon = minLon == null ? bounds.swLon : (minLon < bounds.swLon ? minLon : bounds.swLon);
        maxLon = maxLon == null ? bounds.neLon : (maxLon > bounds.neLon ? maxLon : bounds.neLon);
      }
    }

    if (minLat != null && maxLat != null && minLon != null && maxLon != null) {
      return (swLat: minLat, swLon: minLon, neLat: maxLat, neLon: maxLon);
    }

    return null;
  }

  /// Get initial camera target from bounds
  LatLng _getInitialTarget(
      ({double swLat, double swLon, double neLat, double neLon})? bounds) {
    if (bounds != null) {
      // Center of the bounds
      return LatLng(
        (bounds.swLat + bounds.neLat) / 2,
        (bounds.swLon + bounds.neLon) / 2,
      );
    }
    // Default to Oslo area
    return const LatLng(59.934, 10.848);
  }

  /// Zoom map to show the terminal bounds
  void _zoomToBounds(({double swLat, double swLon, double neLat, double neLon})? bounds) {
    if (_mapController != null && bounds != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(bounds.swLat, bounds.swLon),
            northeast: LatLng(bounds.neLat, bounds.neLon),
          ),
          50, // padding
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/license_plate_service.dart';
import '../../../../core/services/terminal_geofence_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../capture/domain/usecases/get_current_location.dart';
import '../../domain/entities/module_entry.dart';
import '../providers/module_tracking_provider.dart';

/// Screen for capturing module photos and building a list
class ModuleCaptureScreen extends ConsumerStatefulWidget {
  const ModuleCaptureScreen({super.key});

  @override
  ConsumerState<ModuleCaptureScreen> createState() => _ModuleCaptureScreenState();
}

class _ModuleCaptureScreenState extends ConsumerState<ModuleCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  bool _isProcessing = false;
  String? _capturedImagePath;
  FlashMode _flashMode = FlashMode.auto;

  // Form fields for editing detected values
  final _licensePlateController = TextEditingController();
  final _containerIdController = TextEditingController();
  final _terminalController = TextEditingController();

  // Auto-detected flags
  bool _licensePlateAutoDetected = false;
  bool _containerIdAutoDetected = false;
  bool _terminalAutoDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      logger.debug('Initializing camera for module capture...');
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        logger.warning('No cameras available');
        setState(() => _isInitializing = false);
        return;
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      logger.info('Camera initialized for module capture');

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      logger.error('Camera initialization failed', e);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
      logger.debug('Flash mode changed to: $nextMode');
    } catch (e) {
      logger.error('Failed to set flash mode: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  String _getFlashLabel() {
    switch (_flashMode) {
      case FlashMode.off:
        return 'Off';
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      case FlashMode.torch:
        return 'Torch';
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackBar('Camera not ready', isError: true);
      return;
    }

    if (_isTakingPicture) return;

    try {
      setState(() => _isTakingPicture = true);
      logger.debug('Taking picture for module capture...');

      final image = await _cameraController!.takePicture();
      logger.info('Picture taken: ${image.path}');

      // Copy to temporary location for OCR processing
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/module_$timestamp.jpg';
      await File(image.path).copy(tempPath);
      logger.debug('Image copied to temp: $tempPath');

      setState(() {
        _capturedImagePath = tempPath;
        _isTakingPicture = false;
        _isProcessing = true;
        _licensePlateAutoDetected = false;
        _containerIdAutoDetected = false;
        _terminalAutoDetected = false;
      });

      _showSnackBar('Photo captured! Processing...');

      // Run OCR detection for module info
      final moduleInfo = await LicensePlateService.detectModuleInfo(tempPath);

      // Get current location and auto-detect terminal
      final locationUseCase = GetCurrentLocation();
      final locationResult = await locationUseCase();

      String? detectedTerminal;
      locationResult.fold(
        (failure) {
          logger.error('Failed to get location: ${failure.message}');
        },
        (locationData) {
          detectedTerminal = TerminalGeofenceService.getTerminal(
            locationData.latitude,
            locationData.longitude,
          );
          if (detectedTerminal != null) {
            logger.info('Auto-detected terminal: $detectedTerminal');
          }
        },
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;

          // Set license plate if detected
          if (moduleInfo.licensePlate != null) {
            _licensePlateController.text = moduleInfo.licensePlate!;
            _licensePlateAutoDetected = true;
            logger.info('License plate auto-detected: ${moduleInfo.licensePlate}');
          }

          // Set container ID if detected
          if (moduleInfo.containerId != null) {
            _containerIdController.text = moduleInfo.containerId!;
            _containerIdAutoDetected = true;
            logger.info('Container ID auto-detected: ${moduleInfo.containerId}');
          }

          // Set terminal if detected
          if (detectedTerminal != null) {
            _terminalController.text = detectedTerminal!;
            _terminalAutoDetected = true;
          } else if (_terminalController.text.isEmpty) {
            // Default to first terminal if no auto-detection
            _terminalController.text = AppConfig.terminals.first;
          }
        });

        if (moduleInfo.licensePlate != null || moduleInfo.containerId != null) {
          _showSnackBar('Detected: ${moduleInfo.licensePlate ?? ''} ${moduleInfo.containerId ?? ''}');
        } else {
          _showSnackBar('No plate/container detected - enter manually');
        }
      }
    } catch (e) {
      logger.error('Failed to take picture', e);
      setState(() {
        _isTakingPicture = false;
        _isProcessing = false;
      });
      _showSnackBar('Failed to take picture', isError: true);
    }
  }

  void _addEntry() {
    final licensePlate = _licensePlateController.text.trim();
    if (licensePlate.isEmpty) {
      _showSnackBar('Please enter a license plate', isError: true);
      return;
    }

    final terminal = _terminalController.text.trim();
    if (terminal.isEmpty) {
      _showSnackBar('Please enter a terminal', isError: true);
      return;
    }

    final containerId = _containerIdController.text.trim();

    // Create and add the entry
    final entry = ModuleEntry(
      licensePlate: LicensePlateService.formatPlate(licensePlate),
      containerId: containerId.isNotEmpty ? containerId : null,
      terminal: terminal.toUpperCase(),
      capturedAt: DateTime.now(),
      photoPath: _capturedImagePath,
    );

    ref.read(moduleTrackingProvider.notifier).addEntry(entry);
    logger.info('Added module entry: ${entry.licensePlate} at ${entry.terminal}');

    _showSnackBar('Added: ${entry.licensePlate}');

    // Reset for next capture
    _resetForNextCapture();
  }

  void _resetForNextCapture() {
    setState(() {
      _capturedImagePath = null;
      _licensePlateController.clear();
      _containerIdController.clear();
      // Keep terminal for next capture (likely same terminal)
      _licensePlateAutoDetected = false;
      _containerIdAutoDetected = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  void _navigateToReview() {
    Navigator.of(context).pushNamed('/module-review');
  }

  void _navigateToList() {
    Navigator.of(context).pushNamed('/module-list');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _licensePlateController.dispose();
    _containerIdController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moduleSession = ref.watch(moduleTrackingProvider);
    final entryCount = moduleSession.entryCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Modules'),
        actions: [
          if (entryCount > 0)
            TextButton.icon(
              onPressed: _navigateToReview,
              icon: const Icon(Icons.done, color: Colors.white),
              label: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Session tracking display
                if (entryCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.defaultPadding,
                      vertical: AppConfig.smallPadding,
                    ),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Captured: $entryCount module${entryCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _navigateToList,
                          child: const Text('View List'),
                        ),
                      ],
                    ),
                  ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConfig.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Camera Preview or Captured Image
                        _buildCameraSection(),
                        const SizedBox(height: AppConfig.defaultPadding),

                        // Only show form fields after photo is captured
                        if (_capturedImagePath != null) ...[
                          // License Plate Input
                          TextFormField(
                            controller: _licensePlateController,
                            decoration: InputDecoration(
                              labelText: 'License Plate *',
                              hintText: 'Enter license plate (e.g., VA 1948)',
                              prefixIcon: const Icon(Icons.directions_car),
                              suffixIcon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : _licensePlateAutoDetected
                                      ? const Icon(Icons.auto_awesome, color: Colors.green)
                                      : null,
                              helperText: _licensePlateAutoDetected ? 'Auto-detected from photo' : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) {
                              if (_licensePlateAutoDetected) {
                                setState(() => _licensePlateAutoDetected = false);
                              }
                            },
                          ),
                          const SizedBox(height: AppConfig.defaultPadding),

                          // Container ID Input (optional)
                          TextFormField(
                            controller: _containerIdController,
                            decoration: InputDecoration(
                              labelText: 'Container ID (optional)',
                              hintText: 'e.g., PTRU 406124-0',
                              prefixIcon: const Icon(Icons.inventory),
                              suffixIcon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : _containerIdAutoDetected
                                      ? const Icon(Icons.auto_awesome, color: Colors.green)
                                      : null,
                              helperText: _containerIdAutoDetected ? 'Auto-detected from photo' : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) {
                              if (_containerIdAutoDetected) {
                                setState(() => _containerIdAutoDetected = false);
                              }
                            },
                          ),
                          const SizedBox(height: AppConfig.defaultPadding),

                          // Terminal Input with Autocomplete
                          Autocomplete<String>(
                            initialValue: TextEditingValue(text: _terminalController.text),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return AppConfig.terminals;
                              }
                              return AppConfig.terminals.where((String option) {
                                return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              _terminalController.text = selection;
                            },
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              // Sync the autocomplete controller with our terminal controller
                              if (_terminalController.text.isNotEmpty &&
                                  textEditingController.text.isEmpty) {
                                textEditingController.text = _terminalController.text;
                              }
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Terminal *',
                                  hintText: 'e.g., B1, B3, ØT',
                                  prefixIcon: const Icon(Icons.location_on),
                                  suffixIcon: _terminalAutoDetected
                                      ? const Icon(Icons.gps_fixed, color: Colors.green)
                                      : null,
                                  helperText: _terminalAutoDetected
                                      ? 'Auto-detected from GPS'
                                      : 'Select or enter terminal',
                                ),
                                textCapitalization: TextCapitalization.characters,
                                onChanged: (value) {
                                  _terminalController.text = value;
                                  if (_terminalAutoDetected) {
                                    setState(() => _terminalAutoDetected = false);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: AppConfig.largePadding),

                          // Add Button
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _addEntry,
                            icon: const Icon(Icons.add),
                            label: const Text('Add to List'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(AppConfig.defaultPadding),
                            ),
                          ),
                          const SizedBox(height: AppConfig.smallPadding),

                          // Retake Photo Button
                          OutlinedButton.icon(
                            onPressed: _resetForNextCapture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Retake Photo'),
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

  Widget _buildCameraSection() {
    if (_capturedImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
        child: Image.file(
          File(_capturedImagePath!),
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 250,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 50),
            );
          },
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Camera not available'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Get camera preview size
                final previewSize = _cameraController!.value.previewSize!;

                // Camera is typically landscape, so we need to swap dimensions in portrait
                final size = MediaQuery.of(context).size;
                final isPortrait = size.height > size.width;

                // Calculate actual dimensions considering orientation
                final previewWidth = isPortrait ? previewSize.height : previewSize.width;
                final previewHeight = isPortrait ? previewSize.width : previewSize.height;

                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: CameraPreview(_cameraController!),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppConfig.defaultPadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flash toggle button
            OutlinedButton.icon(
              onPressed: _toggleFlash,
              icon: Icon(_getFlashIcon()),
              label: Text(_getFlashLabel()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            // Take photo button
            ElevatedButton.icon(
              onPressed: _isTakingPicture ? null : _takePicture,
              icon: _isTakingPicture
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera),
              label: Text(_isTakingPicture ? 'Taking Photo...' : 'Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

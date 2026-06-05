import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/license_plate_service.dart';
import '../../../../core/services/terminal_geofence_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/usecases/get_current_location.dart';
import '../providers/capture_provider.dart';

/// Screen for capturing trailer photos and information
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  bool _isDetectingPlate = false;
  String? _capturedImagePath;
  bool _plateAutoDetected = false;
  FlashMode _flashMode = FlashMode.auto;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _trailerNumberController = TextEditingController();
  final _terminalController = TextEditingController();
  final _notesController = TextEditingController();
  final _rampNumberController = TextEditingController();

  // Status: 0 = Empty, 1 = Loaded, 2 = In Ramp
  int _statusSelection = 1; // Default to Loaded

  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    _terminalController.text = AppConfig.terminals.first;
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    try {
      logger.debug('Initializing camera...');
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
      logger.info('Camera initialized');

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

  Future<void> _getCurrentLocation() async {
    final useCase = GetCurrentLocation();
    final result = await useCase();

    result.fold(
      (failure) {
        logger.error('Failed to get location: ${failure.message}');
        _showSnackBar(failure.message, isError: true);
      },
      (locationData) {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
        });
        logger.info('Location obtained: $_latitude, $_longitude');
        _showSnackBar('Location obtained');
      },
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
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
      logger.debug('Taking picture...');

      final image = await _cameraController!.takePicture();
      logger.info('Picture taken: ${image.path}');

      setState(() {
        _capturedImagePath = image.path;
        _isTakingPicture = false;
        _isDetectingPlate = true;
        _plateAutoDetected = false;
      });

      _showSnackBar('Photo captured! Detecting plate...');

      // Run license plate detection
      final detectedPlate = await LicensePlateService.detectPlate(image.path);

      if (mounted) {
        setState(() => _isDetectingPlate = false);

        if (detectedPlate != null && _trailerNumberController.text.isEmpty) {
          setState(() {
            _trailerNumberController.text = detectedPlate;
            _plateAutoDetected = true;
          });
          _showSnackBar('Plate detected: $detectedPlate');
        } else if (detectedPlate == null) {
          _showSnackBar('No plate detected - enter manually');
        }
      }
    } catch (e) {
      logger.error('Failed to take picture', e);
      setState(() {
        _isTakingPicture = false;
        _isDetectingPlate = false;
      });
      _showSnackBar('Failed to take picture', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _trailerNumberController.dispose();
    _terminalController.dispose();
    _notesController.dispose();
    _rampNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final captureState = ref.watch(captureProvider);

    // Guest users cannot access capture screen
    if (authState.user?.isGuest == true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Capture Trailer'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Guest users do not have permission to create new trailer entries.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Trailer'),
        actions: [
          if (_capturedImagePath != null && !captureState.isLoading)
            TextButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          if (captureState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Camera Preview or Captured Image
                    _buildCameraSection(),
                    const SizedBox(height: AppConfig.largePadding),

                    // Trailer Number Input
                    TextFormField(
                      controller: _trailerNumberController,
                      decoration: InputDecoration(
                        labelText: 'Trailer Number',
                        hintText: 'Enter trailer number (e.g., TR-12345)',
                        prefixIcon: const Icon(Icons.local_shipping),
                        suffixIcon: _isDetectingPlate
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _plateAutoDetected
                                ? const Icon(Icons.auto_awesome, color: Colors.green)
                                : null,
                        helperText: _plateAutoDetected ? 'Auto-detected from photo' : null,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        // Clear auto-detected flag if user edits
                        if (_plateAutoDetected) {
                          setState(() => _plateAutoDetected = false);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter trailer number';
                        }
                        if (value.length < AppConfig.minTrailerNumberLength) {
                          return 'Trailer number too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConfig.defaultPadding),

                    // Terminal/Location Input (Free Text with Suggestions)
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _terminalController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return AppConfig.terminals;
                        }
                        return AppConfig.terminals.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _terminalController.text = selection;
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // Sync the autocomplete controller with our terminal controller
                        if (_terminalController.text.isNotEmpty && textEditingController.text.isEmpty) {
                          textEditingController.text = _terminalController.text;
                        }
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Terminal / Location',
                            hintText: 'e.g., B1, B3, Ramp 5',
                            prefixIcon: const Icon(Icons.location_on),
                            helperText: 'You can select a terminal or write custom location',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _terminalController.text = value;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppConfig.defaultPadding),

                    // Status Selector
                    Text(
                      'Trailer Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: AppConfig.smallPadding),
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
                          icon: Icon(Icons.warehouse),
                        ),
                      ],
                      selected: {_statusSelection},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _statusSelection = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: AppConfig.defaultPadding),

                    // Ramp Number (only show when In Ramp is selected)
                    if (_statusSelection == 2) ...[
                      TextFormField(
                        controller: _rampNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Ramp Number',
                          hintText: 'Enter ramp number (e.g., Ramp 5)',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (_statusSelection == 2 && (value == null || value.isEmpty)) {
                            return 'Please enter ramp number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConfig.defaultPadding),
                    ],

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any additional notes',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                      maxLength: AppConfig.maxNotesLength,
                    ),
                    const SizedBox(height: AppConfig.defaultPadding),

                    // Location Info
                    _buildLocationInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCameraSection() {
    if (_capturedImagePath != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
            child: Image.file(
              File(_capturedImagePath!),
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                );
              },
            ),
          ),
          const SizedBox(height: AppConfig.smallPadding),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _capturedImagePath = null;
                _plateAutoDetected = false;
              });
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Retake Photo'),
          ),
        ],
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
            height: 300, // Same height as captured image display
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

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_latitude != null && _longitude != null) ...[
              Text('Lat: ${_latitude!.toStringAsFixed(6)}'),
              Text('Lng: ${_longitude!.toStringAsFixed(6)}'),
              if (_address != null) Text('Address: $_address'),
            ] else ...[
              const Text('Getting location...'),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Location'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_capturedImagePath == null) {
      _showSnackBar('Please take a photo first', isError: true);
      return;
    }

    // Refresh GPS location before saving (trailer may have moved since photo was taken)
    _showSnackBar('Getting current location...');
    final useCase = GetCurrentLocation();
    final result = await useCase();

    await result.fold(
      (failure) async {
        logger.error('Failed to get location on save: ${failure.message}');
        // If we already have a location, ask user if they want to use it
        if (_latitude != null && _longitude != null) {
          _showSnackBar('Using previous location', isError: false);
        } else {
          _showSnackBar('Could not get location: ${failure.message}', isError: true);
          return;
        }
      },
      (locationData) async {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
        });
        logger.info('Fresh location obtained: $_latitude, $_longitude');

        // Auto-detect terminal based on GPS coordinates
        final detectedTerminal = TerminalGeofenceService.getTerminal(
          locationData.latitude,
          locationData.longitude,
        );
        if (detectedTerminal != null) {
          setState(() {
            _terminalController.text = detectedTerminal;
          });
          logger.info('Auto-detected terminal: $detectedTerminal');
          _showSnackBar('Terminal detected: $detectedTerminal');
        }
      },
    );

    if (_latitude == null || _longitude == null) {
      _showSnackBar('Location required to save', isError: true);
      return;
    }

    // Use Riverpod provider to save entry
    logger.info('Saving entry: ${_trailerNumberController.text}');

    final bool isEmpty = _statusSelection == 0;
    final bool isInRamp = _statusSelection == 2;
    final String? rampNumber = isInRamp ? _rampNumberController.text.toUpperCase().trim() : null;

    // Format the trailer number consistently (e.g., "VA1948" -> "VA 1948")
    final formattedTrailerNumber = LicensePlateService.formatPlate(_trailerNumberController.text);

    await ref.read(captureProvider.notifier).createEntry(
      trailerNumber: formattedTrailerNumber,
      terminal: _terminalController.text.toUpperCase().trim(),
      isEmpty: isEmpty,
      isInRamp: isInRamp,
      rampNumber: rampNumber,
      latitude: _latitude!,
      longitude: _longitude!,
      address: _address,
      photo: File(_capturedImagePath!),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // Check result
    final state = ref.read(captureProvider);

    if (state.success) {
      _showSnackBar('Entry saved successfully!');

      // Navigate back after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      });
    } else if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
    }
  }
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:trailer_manager/core/utils/logger.dart';

/// Service for detecting license plates in images using ML Kit OCR.
class LicensePlateService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Detects a license plate in the given image file.
  /// Returns the detected plate text, or null if no plate was found.
  static Future<String?> detectPlate(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        logger.info('No text detected in image');
        return null;
      }

      // Get image dimensions to determine "bottom" area
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imageHeight = frame.image.height.toDouble();

      // Log all detected text for debugging
      logger.debug('OCR detected ${recognizedText.blocks.length} blocks:');
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          logger.debug('  Raw text: "${line.text}"');
        }
      }

      // Collect candidate plates from text blocks
      final candidates = <_PlateCandidate>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = _cleanPlateText(line.text);
          final extracted = _extractPlateFromText(text);

          if (extracted != null) {
            // Calculate vertical position (0 = top, 1 = bottom)
            final centerY = line.boundingBox.center.dy;
            final verticalPosition = centerY / imageHeight;

            // Calculate text area (larger text is more likely to be a plate)
            final area = line.boundingBox.width * line.boundingBox.height;

            logger.debug('  Candidate plate: "$extracted" (from "$text")');
            candidates.add(_PlateCandidate(
              text: extracted,
              verticalPosition: verticalPosition,
              area: area,
            ));
          } else if (_isLikelyPlate(text)) {
            // Fallback to original matching
            final centerY = line.boundingBox.center.dy;
            final verticalPosition = centerY / imageHeight;
            final area = line.boundingBox.width * line.boundingBox.height;

            logger.debug('  Candidate plate (fallback): "$text"');
            candidates.add(_PlateCandidate(
              text: text,
              verticalPosition: verticalPosition,
              area: area,
            ));
          }
        }
      }

      if (candidates.isEmpty) {
        logger.info('No license plate patterns found in detected text');
        return null;
      }

      // Score candidates: prefer bottom of image + larger text
      candidates.sort((a, b) {
        final scoreA = a.verticalPosition * 0.6 + (a.area / 10000) * 0.4;
        final scoreB = b.verticalPosition * 0.6 + (b.area / 10000) * 0.4;
        return scoreB.compareTo(scoreA);
      });

      final bestMatch = formatPlate(candidates.first.text);
      logger.info('Detected license plate: $bestMatch');
      return bestMatch;
    } catch (e) {
      logger.error('Error detecting license plate: $e');
      return null;
    }
  }

  /// Cleans up detected text to normalize plate format.
  static String _cleanPlateText(String text) {
    // Remove extra whitespace, keep alphanumeric and spaces
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tries to extract a license plate from text that might contain extra characters.
  /// More aggressive than _isLikelyPlate - looks for plate patterns within longer text.
  static String? _extractPlateFromText(String text) {
    // Remove all whitespace for pattern matching
    final raw = text.replaceAll(RegExp(r'\s+'), '');

    // Try to find Norwegian plate pattern (2 letters + 4-5 digits) anywhere in text
    // This handles cases like "NVA1977" where "N" is from the country code
    final norwegianMatch = RegExp(r'([A-Z]{2})(\d{4,5})').firstMatch(raw);
    if (norwegianMatch != null) {
      return '${norwegianMatch.group(1)} ${norwegianMatch.group(2)}';
    }

    // Try Swedish new format (3 letters + 2 digits + 1 letter) e.g., POT 95B
    final swedishNewMatch = RegExp(r'([A-Z]{3})(\d{2})([A-Z])').firstMatch(raw);
    if (swedishNewMatch != null) {
      return '${swedishNewMatch.group(1)} ${swedishNewMatch.group(2)}${swedishNewMatch.group(3)}';
    }

    // Try Swedish classic format (3 letters + 3 digits) e.g., ABC 123
    final swedishMatch = RegExp(r'([A-Z]{3})(\d{3})(?!\d)').firstMatch(raw);
    if (swedishMatch != null) {
      return '${swedishMatch.group(1)} ${swedishMatch.group(2)}';
    }

    // Try Dutch patterns
    // XX 99 XX
    final dutchMatch1 = RegExp(r'([A-Z]{2})(\d{2})([A-Z]{2})').firstMatch(raw);
    if (dutchMatch1 != null) {
      return '${dutchMatch1.group(1)} ${dutchMatch1.group(2)} ${dutchMatch1.group(3)}';
    }

    // 99 XX XX
    final dutchMatch2 = RegExp(r'(\d{2})([A-Z]{2})([A-Z]{2})').firstMatch(raw);
    if (dutchMatch2 != null) {
      return '${dutchMatch2.group(1)} ${dutchMatch2.group(2)} ${dutchMatch2.group(3)}';
    }

    // Generic: find any sequence of 2-3 letters followed by 3-5 digits
    final genericMatch = RegExp(r'([A-Z]{2,3})(\d{3,5})').firstMatch(raw);
    if (genericMatch != null) {
      return '${genericMatch.group(1)} ${genericMatch.group(2)}';
    }

    return null;
  }

  /// Formats a license plate string with consistent spacing for readability.
  /// E.g., "VA1948" -> "VA 1948", "OR79FT" -> "OR 79 FT"
  static String formatPlate(String plate) {
    // First, remove all whitespace to get raw characters
    final raw = plate.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    if (raw.isEmpty) return plate;

    // Try to match and format known patterns

    // Norwegian: 2 letters + 4-5 digits -> "XX YYYYY"
    final norwegianMatch = RegExp(r'^([A-Z]{2})(\d{4,5})$').firstMatch(raw);
    if (norwegianMatch != null) {
      return '${norwegianMatch.group(1)} ${norwegianMatch.group(2)}';
    }

    // Swedish classic: 3 letters + 3 digits -> "XXX 123"
    final swedishMatch = RegExp(r'^([A-Z]{3})(\d{3})$').firstMatch(raw);
    if (swedishMatch != null) {
      return '${swedishMatch.group(1)} ${swedishMatch.group(2)}';
    }

    // Swedish new: 3 letters + 2 digits + 1 letter -> "XXX 12Y"
    final swedishNewMatch = RegExp(r'^([A-Z]{3})(\d{2})([A-Z])$').firstMatch(raw);
    if (swedishNewMatch != null) {
      return '${swedishNewMatch.group(1)} ${swedishNewMatch.group(2)}${swedishNewMatch.group(3)}';
    }

    // Dutch sidecodes (6 characters in various formats)
    // XX-99-XX, 99-XX-XX, XX-XX-99, 99-XXX-9, 9-XXX-99, etc.
    if (raw.length == 6) {
      // XX 99 XX pattern
      final dutch1 = RegExp(r'^([A-Z]{2})(\d{2})([A-Z]{2})$').firstMatch(raw);
      if (dutch1 != null) {
        return '${dutch1.group(1)} ${dutch1.group(2)} ${dutch1.group(3)}';
      }

      // 99 XX XX pattern
      final dutch2 = RegExp(r'^(\d{2})([A-Z]{2})([A-Z]{2})$').firstMatch(raw);
      if (dutch2 != null) {
        return '${dutch2.group(1)} ${dutch2.group(2)} ${dutch2.group(3)}';
      }

      // XX XX 99 pattern
      final dutch3 = RegExp(r'^([A-Z]{2})([A-Z]{2})(\d{2})$').firstMatch(raw);
      if (dutch3 != null) {
        return '${dutch3.group(1)} ${dutch3.group(2)} ${dutch3.group(3)}';
      }

      // 99 XXX 9 pattern
      final dutch4 = RegExp(r'^(\d{2})([A-Z]{3})(\d{1})$').firstMatch(raw);
      if (dutch4 != null) {
        return '${dutch4.group(1)} ${dutch4.group(2)} ${dutch4.group(3)}';
      }

      // 9 XXX 99 pattern
      final dutch5 = RegExp(r'^(\d{1})([A-Z]{3})(\d{2})$').firstMatch(raw);
      if (dutch5 != null) {
        return '${dutch5.group(1)} ${dutch5.group(2)} ${dutch5.group(3)}';
      }
    }

    // Generic: split between letters and numbers
    // Find transitions between letter groups and digit groups
    final buffer = StringBuffer();
    String? lastType;

    for (int i = 0; i < raw.length; i++) {
      final char = raw[i];
      final isLetter = RegExp(r'[A-Z]').hasMatch(char);
      final currentType = isLetter ? 'L' : 'D';

      if (lastType != null && lastType != currentType) {
        buffer.write(' ');
      }
      buffer.write(char);
      lastType = currentType;
    }

    return buffer.toString();
  }

  /// Normalizes a plate for comparison (removes all whitespace, uppercase).
  static String normalizePlate(String plate) {
    return plate.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Checks if text matches common license plate patterns.
  static bool _isLikelyPlate(String text) {
    if (text.length < 4 || text.length > 12) return false;

    // Must contain both letters and numbers
    final hasLetters = RegExp(r'[A-Z]').hasMatch(text);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(text);
    if (!hasLetters || !hasNumbers) return false;

    // Common patterns:
    // Norwegian: "AB 12345", "AB 1234"
    // Swedish: "ABC 123" (classic), "ABC 12D" (new format)
    // Dutch: "XX 99 XX", "99 XX XX", "XX 99 99" (sidecode formats)
    // Generic: 2-3 letters + space + 3-5 digits
    final patterns = [
      RegExp(r'^[A-Z]{2}\s?\d{4,5}$'),           // Norwegian: VA 1948
      RegExp(r'^[A-Z]{3}\s?\d{3}$'),              // Swedish classic: ABC 123
      RegExp(r'^[A-Z]{3}\s?\d{2}\s?[A-Z]$'),     // Swedish new: POT 95B
      RegExp(r'^[A-Z]{1,3}\s?\d{3,5}$'),          // Generic European
      RegExp(r'^\d{2,3}\s?[A-Z]{2,3}$'),          // Reversed format
      RegExp(r'^[A-Z]{2}\s?\d{2}\s?[A-Z]{2}$'),   // Dutch: OR 79 FT
      RegExp(r'^\d{2}\s?[A-Z]{2}\s?[A-Z]{2}$'),   // Dutch: 99 XX XX
      RegExp(r'^[A-Z]{2}\s?[A-Z]{2}\s?\d{2}$'),   // Dutch: XX XX 99
      RegExp(r'^\d{2}\s?[A-Z]{3}\s?\d{1}$'),      // Dutch: 99 XXX 9
      RegExp(r'^\d{1}\s?[A-Z]{3}\s?\d{2}$'),      // Dutch: 9 XXX 99
    ];

    return patterns.any((p) => p.hasMatch(text));
  }

  /// Detects a container ID in the given image file.
  /// Container IDs have the format: XXXX NNNNNN-N (4 letters, space, 6 digits, hyphen, 1 digit)
  /// Example: PTRU 406124-0
  /// Returns the detected container ID, or null if none was found.
  static Future<String?> detectContainerId(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        logger.info('No text detected in image for container ID');
        return null;
      }

      // Log all detected text for debugging
      logger.debug('OCR detected ${recognizedText.blocks.length} blocks for container ID:');
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          logger.debug('  Raw text: "${line.text}"');
        }
      }

      // Look for container ID pattern in all text blocks
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final extracted = _extractContainerIdFromText(line.text);
          if (extracted != null) {
            logger.info('Detected container ID: $extracted');
            return extracted;
          }
        }
      }

      logger.info('No container ID patterns found in detected text');
      return null;
    } catch (e) {
      logger.error('Error detecting container ID: $e');
      return null;
    }
  }

  /// Tries to extract a container ID from text.
  /// Container ID format: XXXX NNNNNN-N (4 letters, space, 6 digits, hyphen, 1 digit)
  /// Example: PTRU 406124-0
  static String? _extractContainerIdFromText(String text) {
    final cleaned = text.toUpperCase().trim();

    // Pattern: 4 letters, optional space, 6 digits, hyphen, 1 digit
    // Allow for OCR variations (space might be missing, hyphen might be different)
    final containerPattern = RegExp(r'([A-Z]{4})\s*(\d{6})[-–—]?(\d)');
    final match = containerPattern.firstMatch(cleaned);

    if (match != null) {
      // Format as standard: XXXX NNNNNN-N
      return '${match.group(1)} ${match.group(2)}-${match.group(3)}';
    }

    return null;
  }

  /// Detects both license plate and container ID from the given image.
  /// Returns a record containing both values (either can be null).
  static Future<({String? licensePlate, String? containerId})> detectModuleInfo(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String? licensePlate;
      String? containerId;

      if (recognizedText.blocks.isEmpty) {
        logger.info('No text detected in image for module info');
        return (licensePlate: null, containerId: null);
      }

      // Get image dimensions for license plate scoring
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imageHeight = frame.image.height.toDouble();

      // Log all detected text for debugging
      logger.debug('OCR detected ${recognizedText.blocks.length} blocks for module info:');
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          logger.debug('  Raw text: "${line.text}"');
        }
      }

      // Collect license plate candidates
      final plateCandidates = <_PlateCandidate>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          // Check for container ID
          if (containerId == null) {
            final extractedContainer = _extractContainerIdFromText(line.text);
            if (extractedContainer != null) {
              containerId = extractedContainer;
              logger.debug('  Found container ID: $containerId');
            }
          }

          // Check for license plate
          final cleanedText = _cleanPlateText(line.text);
          final extracted = _extractPlateFromText(cleanedText);

          if (extracted != null) {
            final centerY = line.boundingBox.center.dy;
            final verticalPosition = centerY / imageHeight;
            final area = line.boundingBox.width * line.boundingBox.height;

            logger.debug('  Candidate plate: "$extracted" (from "${line.text}")');
            plateCandidates.add(_PlateCandidate(
              text: extracted,
              verticalPosition: verticalPosition,
              area: area,
            ));
          } else if (_isLikelyPlate(cleanedText)) {
            final centerY = line.boundingBox.center.dy;
            final verticalPosition = centerY / imageHeight;
            final area = line.boundingBox.width * line.boundingBox.height;

            logger.debug('  Candidate plate (fallback): "$cleanedText"');
            plateCandidates.add(_PlateCandidate(
              text: cleanedText,
              verticalPosition: verticalPosition,
              area: area,
            ));
          }
        }
      }

      // Select best license plate candidate
      if (plateCandidates.isNotEmpty) {
        plateCandidates.sort((a, b) {
          final scoreA = a.verticalPosition * 0.6 + (a.area / 10000) * 0.4;
          final scoreB = b.verticalPosition * 0.6 + (b.area / 10000) * 0.4;
          return scoreB.compareTo(scoreA);
        });

        licensePlate = formatPlate(plateCandidates.first.text);
        logger.info('Detected license plate: $licensePlate');
      }

      if (containerId != null) {
        logger.info('Detected container ID: $containerId');
      }

      return (licensePlate: licensePlate, containerId: containerId);
    } catch (e) {
      logger.error('Error detecting module info: $e');
      return (licensePlate: null, containerId: null);
    }
  }

  /// Dispose the text recognizer when no longer needed.
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

class _PlateCandidate {
  final String text;
  final double verticalPosition;
  final double area;

  _PlateCandidate({
    required this.text,
    required this.verticalPosition,
    required this.area,
  });
}

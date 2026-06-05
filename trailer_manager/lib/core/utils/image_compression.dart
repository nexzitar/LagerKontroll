import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import 'logger.dart';

/// Utility class for image compression
class ImageCompression {
  ImageCompression._();

  /// Compress image file
  static Future<File> compressImage(File imageFile) async {
    try {
      logger.debug('Starting image compression for: ${imageFile.path}');

      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        logger.error('Failed to decode image');
        throw Exception('Failed to decode image');
      }

      logger.debug('Original image size: ${image.width}x${image.height}');

      // Resize if needed
      img.Image resized = image;
      if (image.width > AppConfig.maxImageWidth ||
          image.height > AppConfig.maxImageHeight) {
        resized = img.copyResize(
          image,
          width: AppConfig.maxImageWidth,
          height: AppConfig.maxImageHeight,
          maintainAspect: true,
        );
        logger.debug('Resized image to: ${resized.width}x${resized.height}');
      }

      // Compress as JPEG
      final compressed = img.encodeJpg(resized, quality: AppConfig.imageQuality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/compressed_$timestamp.jpg';
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressed);

      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);

      logger.info('Image compressed: $originalSize bytes → $compressedSize bytes ($compressionRatio% reduction)');

      return compressedFile;
    } catch (e, stackTrace) {
      logger.error('Image compression failed', e, stackTrace);
      rethrow;
    }
  }

  /// Create thumbnail
  static Future<File> createThumbnail(File imageFile) async {
    try {
      logger.debug('Creating thumbnail for: ${imageFile.path}');

      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to thumbnail size
      final thumbnail = img.copyResize(
        image,
        width: AppConfig.thumbnailWidth,
        height: AppConfig.thumbnailHeight,
        maintainAspect: true,
      );

      // Compress
      final compressed = img.encodeJpg(thumbnail, quality: AppConfig.imageQuality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/thumbnail_$timestamp.jpg';
      final thumbnailFile = File(tempPath);
      await thumbnailFile.writeAsBytes(compressed);

      logger.info('Thumbnail created: ${thumbnail.width}x${thumbnail.height}');

      return thumbnailFile;
    } catch (e, stackTrace) {
      logger.error('Thumbnail creation failed', e, stackTrace);
      rethrow;
    }
  }

  /// Validate image file
  static Future<bool> validateImage(File imageFile) async {
    try {
      // Check file exists
      if (!await imageFile.exists()) {
        logger.warning('Image file does not exist');
        return false;
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSizeBytes) {
        logger.warning('Image file too large: $fileSize bytes');
        return false;
      }

      // Check if it's a valid image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        logger.warning('Invalid image format');
        return false;
      }

      logger.debug('Image validation passed');
      return true;
    } catch (e, stackTrace) {
      logger.error('Image validation failed', e, stackTrace);
      return false;
    }
  }
}

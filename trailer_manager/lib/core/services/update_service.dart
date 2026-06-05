import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/dio_client.dart';
import '../utils/logger.dart';

/// Service for checking and installing app updates.
class UpdateService {
  final DioClient _dioClient;
  static const _installChannel = MethodChannel('com.lagerkontroll.trailer_manager/install');

  /// iOS App Store URL for Trailer Manager.
  /// TODO: Update with actual App Store ID when the app is published.
  static const _iosAppStoreUrl = 'https://apps.apple.com/app/trailer-manager/id0000000000';

  /// Whether the current platform is iOS.
  bool get isIOS => Platform.isIOS;

  /// Whether the current platform is Android.
  bool get isAndroid => Platform.isAndroid;

  UpdateService(this._dioClient);

  /// Check if an update is available.
  ///
  /// Returns a map containing:
  /// - `updateAvailable`: Whether an update is available
  /// - `latestVersion`: The latest version from the server
  /// - `currentVersion`: The currently installed version
  /// - `downloadUrl`: The URL to download the update (Android APK or iOS App Store)
  /// - `isIOS`: Whether the current platform is iOS
  /// - `isAndroid`: Whether the current platform is Android
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      logger.info('Current app version: $currentVersion');
      logger.info('Platform: ${Platform.isIOS ? "iOS" : "Android"}');

      final response = await _dioClient.get('/app/version');

      if (response.statusCode == 200 && response.data != null) {
        final versionData = response.data as Map<String, dynamic>;
        final latestVersion = versionData['version'] as String?;
        final downloadUrl = versionData['downloadUrl'] as String?;

        if (latestVersion == null) {
          logger.warning('Server did not return a version string');
          return null;
        }

        logger.info('Latest version from server: $latestVersion');

        final updateAvailable = _isUpdateAvailable(currentVersion, latestVersion);

        // Return platform-appropriate download URL
        final effectiveDownloadUrl = Platform.isIOS
            ? _iosAppStoreUrl
            : (downloadUrl ?? 'https://lassi.cloud/downloads/trailer-manager.apk');

        return {
          'updateAvailable': updateAvailable,
          'latestVersion': latestVersion,
          'currentVersion': currentVersion,
          'downloadUrl': effectiveDownloadUrl,
          'isIOS': Platform.isIOS,
          'isAndroid': Platform.isAndroid,
        };
      } else {
        logger.warning('Failed to fetch version info: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.error('Error checking for update', e, stackTrace);
      return null;
    }
  }

  /// Download the APK file with progress callback (Android only).
  ///
  /// Returns the path to the downloaded file, or null if download failed.
  /// On iOS, this method is not applicable - use [openAppStore] instead.
  Future<String?> downloadUpdate(
    String downloadUrl, {
    required void Function(int received, int total) onProgress,
  }) async {
    // iOS doesn't support APK downloads
    if (Platform.isIOS) {
      logger.warning('downloadUpdate called on iOS - this is not supported');
      return null;
    }

    try {
      logger.info('Starting APK download from: $downloadUrl');

      // Get the downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        logger.error('Could not get external storage directory');
        return null;
      }

      final filePath = '${directory.path}/trailer-manager-update.apk';
      final file = File(filePath);

      // Delete old file if exists
      if (await file.exists()) {
        await file.delete();
      }

      // Download with progress
      await _dioClient.download(
        downloadUrl,
        filePath,
        onReceiveProgress: onProgress,
      );

      logger.info('APK downloaded to: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      logger.error('Error downloading APK', e, stackTrace);
      return null;
    }
  }

  /// Install the downloaded APK (Android only).
  ///
  /// Returns true if install intent was launched successfully.
  /// On iOS, this method is not applicable - use [openAppStore] instead.
  Future<bool> installApk(String filePath) async {
    // iOS doesn't support APK installation
    if (Platform.isIOS) {
      logger.warning('installApk called on iOS - this is not supported');
      return false;
    }

    try {
      logger.info('Installing APK from: $filePath');

      final result = await _installChannel.invokeMethod('installApk', {
        'filePath': filePath,
      });

      return result == true;
    } catch (e, stackTrace) {
      logger.error('Error installing APK', e, stackTrace);
      return false;
    }
  }

  /// Open the App Store for updating (iOS) or the download URL (Android).
  ///
  /// On iOS, opens the App Store page for Trailer Manager.
  /// On Android, opens the provided download URL in the browser.
  ///
  /// Returns true if the URL was launched successfully.
  Future<bool> openAppStore({String? androidDownloadUrl}) async {
    try {
      final url = Platform.isIOS
          ? _iosAppStoreUrl
          : (androidDownloadUrl ?? 'https://lassi.cloud/downloads/trailer-manager.apk');

      logger.info('Opening store/download URL: $url');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        logger.error('Could not launch URL: $url');
        return false;
      }
    } catch (e, stackTrace) {
      logger.error('Error opening store/download URL', e, stackTrace);
      return false;
    }
  }

  /// Get a user-friendly message about how to update on the current platform.
  String getUpdateMessage() {
    if (Platform.isIOS) {
      return 'Updates for iOS are available through the App Store. '
          'Please update the app from the App Store to get the latest version.';
    } else {
      return 'A new version is available. '
          'Download and install the update to get the latest features and fixes.';
    }
  }

  /// Compare two version strings to determine if an update is available.
  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }

      return false;
    } catch (e) {
      logger.warning('Error parsing version strings: $e');
      return false;
    }
  }

  /// Parse a version string into [major, minor, patch] components.
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    if (parts.length < 3) {
      throw FormatException('Invalid version format: $version');
    }

    return [
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ];
  }
}

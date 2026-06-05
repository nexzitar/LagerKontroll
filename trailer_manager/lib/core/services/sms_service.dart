import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for direct SMS sending.
///
/// **Android:** Sends SMS directly using Android's SmsManager API.
/// - Requires SEND_SMS permission
/// - Sends SMS in background without opening messaging app
/// - Automatically handles multipart messages (>160 characters)
/// - Permission is requested on first use
///
/// **iOS:** Opens the native SMS composer via url_launcher.
/// - Does not require special permissions
/// - Opens Messages app with pre-filled message
/// - User must manually tap Send
class SmsService {
  static const MethodChannel _channel =
      MethodChannel('com.lagerkontroll.trailer_manager/sms');

  /// Sends an SMS message to the given phone number.
  ///
  /// **Android:** Sends SMS directly using SmsManager. The first time this is called,
  /// Android will request SEND_SMS permission from the user. The SMS is sent
  /// immediately in the background without opening the messaging app.
  ///
  /// **iOS:** Opens the native Messages app with the message pre-filled. The user
  /// must manually tap Send.
  ///
  /// Parameters:
  /// - phoneNumber: The recipient's phone number (can include formatting)
  /// - message: The message text to send (automatically handles >160 chars on Android)
  ///
  /// Returns:
  /// - true if the SMS was sent (Android) or the Messages app was opened (iOS)
  /// - false if the operation failed
  ///
  /// Throws:
  /// - Exception with 'PERMISSION_DENIED' if user denies SMS permission (Android)
  /// - Exception if SMS sending fails
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    // Clean phone number (remove any formatting characters except +)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // On Android, use platform channel for direct SMS sending
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod('sendSms', {
          'phoneNumber': cleanPhone,
          'message': message,
        });
        return result as bool;
      } on PlatformException catch (e) {
        throw Exception('Failed to send SMS: ${e.message}');
      } catch (e) {
        throw Exception('Failed to send SMS: $e');
      }
    }

    // On iOS and other platforms, use url_launcher
    // Encode message for URL
    final encodedMessage = Uri.encodeComponent(message);

    // Create SMS URI
    final smsUri = Uri.parse('sms:$cleanPhone?body=$encodedMessage');

    try {
      // Check if we can launch the SMS URI
      if (await canLaunchUrl(smsUri)) {
        // Launch the SMS app
        final launched = await launchUrl(
          smsUri,
          mode: LaunchMode.platformDefault,
        );
        return launched;
      } else {
        // SMS URI cannot be launched (no SMS app available)
        throw Exception('Could not launch SMS app. No SMS handler found.');
      }
    } catch (e) {
      // Rethrow with more context
      throw Exception('Failed to open SMS composer: $e');
    }
  }

  /// Validates if a phone number is in a reasonable format.
  ///
  /// This is a basic validation - it just checks if the phone number
  /// contains at least some digits.
  ///
  /// Returns true if the phone number appears valid, false otherwise.
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.isNotEmpty && cleaned.length >= 7;
  }
}

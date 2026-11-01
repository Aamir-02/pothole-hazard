import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class SmsDispatchResult {
  final bool success;
  final bool openedInComposer;
  final String message;
  final List<String> recipients;

  const SmsDispatchResult({
    required this.success,
    required this.openedInComposer,
    required this.message,
    this.recipients = const [],
  });
}

class SmsService {
  /// Sanitize phone number to keep only leading '+' and digits,
  /// removing whitespace, dashes, brackets, and special characters.
  static String sanitizePhoneNumber(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return hasPlus ? '+$digits' : digits;
  }

  /// Format exact emergency SMS message required by specification:
  ///
  /// EMERGENCY ALERT!
  ///
  /// A possible vehicle accident has been detected.
  ///
  /// The user's current GPS location:
  /// Latitude: [actual latitude]
  /// Longitude: [actual longitude]
  ///
  /// Google Maps Location:
  /// https://www.google.com/maps?q=[latitude],[longitude]
  ///
  /// Please contact the user and provide emergency assistance.
  static String formatEmergencyMessage({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) {
    final bool hasValidGps = latitude != 0.0 && longitude != 0.0;

    if (hasValidGps) {
      final latStr = latitude.toStringAsFixed(6);
      final lngStr = longitude.toStringAsFixed(6);
      final mapsUrl = 'https://www.google.com/maps?q=$latStr,$lngStr';

      return 'EMERGENCY ALERT!\n\n'
          'A possible vehicle accident has been detected.\n\n'
          'The user\'s current GPS location:\n'
          'Latitude: $latStr\n'
          'Longitude: $lngStr\n\n'
          'Google Maps Location:\n'
          '$mapsUrl\n\n'
          'Please contact the user and provide emergency assistance.';
    } else {
      return 'EMERGENCY ALERT!\n\n'
          'A possible vehicle accident has been detected.\n\n'
          'The user\'s current GPS location:\n'
          'Location unavailable (GPS fix could not be acquired)\n\n'
          'Please contact the user and provide emergency assistance.';
    }
  }

  /// Launch the native Android SMS composer with pre-filled recipients and emergency message.
  static Future<SmsDispatchResult> sendEmergencyAlerts({
    required List<String> recipients,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    // 1. Sanitize all emergency recipient phone numbers
    final cleanRecipients = recipients
        .map(sanitizePhoneNumber)
        .where((phone) => phone.isNotEmpty)
        .toList();

    if (cleanRecipients.isEmpty) {
      return const SmsDispatchResult(
        success: false,
        openedInComposer: false,
        message: 'No emergency contacts found. Please add a contact in the Contacts screen.',
      );
    }

    // 2. Generate required emergency message body
    final message = formatEmergencyMessage(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );

    final primaryNumber = cleanRecipients.first;

    // 3. Launch via Android intent (avoiding ';' format which causes 'Could not start conversation')
    // Primary attempt: standard 'sms:' scheme with primary contact
    bool launched = await _tryLaunchSmsScheme('sms', primaryNumber, message);

    // Secondary attempt: 'smsto:' scheme
    if (!launched) {
      launched = await _tryLaunchSmsScheme('smsto', primaryNumber, message);
    }

    // Tertiary attempt: if multiple recipients, try with comma-separated list
    if (!launched && cleanRecipients.length > 1) {
      launched = await _tryLaunchSmsScheme('sms', cleanRecipients.join(','), message);
    }

    if (launched) {
      return SmsDispatchResult(
        success: true,
        openedInComposer: true,
        message: 'Emergency SMS composer opened for $primaryNumber. Review message and tap Send.',
        recipients: cleanRecipients,
      );
    } else {
      return SmsDispatchResult(
        success: false,
        openedInComposer: false,
        message: 'Could not open SMS application. Please check device messaging app or permissions.',
        recipients: cleanRecipients,
      );
    }
  }

  static Future<bool> _tryLaunchSmsScheme(String scheme, String recipient, String message) async {
    try {
      final Uri uri = Uri(
        scheme: scheme,
        path: recipient,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      // Attempt launch with LaunchMode.externalApplication
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Direct attempt in case canLaunchUrl was restricted by Android 11 package visibility
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
  }
}

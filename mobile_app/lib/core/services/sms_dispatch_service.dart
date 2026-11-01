import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SmsDispatchService {
  /// Format SMS body with exact specified structure
  static String generateEmergencyMessage({
    required String riderName,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) {
    final timeStr = DateFormat('hh:mm a, dd MMM yyyy').format(timestamp ?? DateTime.now());
    final mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';

    return '''🚨 EMERGENCY ALERT 🚨

Possible motorcycle accident detected.

Rider:
$riderName

Time:
$timeStr

Location:
$mapsUrl

Please check immediately.''';
  }

  /// Launch native SMS app or send SMS intent to emergency contacts
  static Future<bool> sendSmsToContacts({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final cleanList = phoneNumbers
        .map((p) => p.trim().replaceAll(RegExp(r'[^\d+]'), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    if (cleanList.isEmpty) return false;

    final primaryNumber = cleanList.first;
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: primaryNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('[SMS Dispatch Error] $e');
      return false;
    }
  }

  /// Make direct emergency call to 911 / 112 or emergency contact
  static Future<void> makeEmergencyPhoneCall(String phoneNumber) async {
    final clean = phoneNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

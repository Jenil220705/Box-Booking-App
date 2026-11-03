import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_config.dart';
import '../core/utils/formatters.dart';

/// Outcome of handing a message to another app.
///
/// [opened] only means the messaging app was launched with the text
/// pre-filled — the user still has to press send, and nothing here can tell
/// whether the message was actually sent or delivered.
enum MessagingResult { opened, unavailable, invalidNumber }

abstract class UrlOpener {
  Future<bool> canOpen(Uri uri);
  Future<bool> open(Uri uri);
}

class SystemUrlOpener implements UrlOpener {
  const SystemUrlOpener();

  @override
  Future<bool> canOpen(Uri uri) => canLaunchUrl(uri);

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class MessagingService {
  MessagingService({this._opener = const SystemUrlOpener()});

  final UrlOpener _opener;

  static String internationalNumber(String phone) =>
      '${AppConfig.countryCode}${cleanPhone(phone)}';

  /// Direct WhatsApp app link.
  static Uri whatsAppAppUri(String phone, String message) => Uri.parse(
    'whatsapp://send?phone=${internationalNumber(phone)}&text=${Uri.encodeComponent(message)}',
  );

  /// Universal link (opens WhatsApp if installed, otherwise WhatsApp Web).
  static Uri whatsAppWebUri(String phone, String message) => Uri.parse(
    'https://wa.me/${internationalNumber(phone)}?text=${Uri.encodeComponent(message)}',
  );

  static Uri smsUri(String phone, String message) => Uri.parse(
    'sms:${cleanPhone(phone)}?body=${Uri.encodeComponent(message)}',
  );

  Future<MessagingResult> openWhatsApp(String phone, String message) async {
    if (!isValidPhone(cleanPhone(phone))) return MessagingResult.invalidNumber;
    final app = whatsAppAppUri(phone, message);
    if (await _opener.canOpen(app) && await _opener.open(app)) {
      return MessagingResult.opened;
    }
    return await _opener.open(whatsAppWebUri(phone, message))
        ? MessagingResult.opened
        : MessagingResult.unavailable;
  }

  Future<MessagingResult> openSms(String phone, String message) async {
    if (!isValidPhone(cleanPhone(phone))) return MessagingResult.invalidNumber;
    return await _opener.open(smsUri(phone, message))
        ? MessagingResult.opened
        : MessagingResult.unavailable;
  }
}

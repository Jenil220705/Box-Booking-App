import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/services/messaging_service.dart';

class FakeOpener implements UrlOpener {
  FakeOpener({this.canOpenApp = true, this.openResults = const {}});

  final bool canOpenApp;

  /// scheme -> result of open(); unspecified schemes succeed.
  final Map<String, bool> openResults;
  final List<Uri> opened = [];

  @override
  Future<bool> canOpen(Uri uri) async => canOpenApp;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return openResults[uri.scheme] ?? true;
  }
}

void main() {
  group('URIs', () {
    test('WhatsApp app link adds the +91 prefix and encodes the text', () {
      final uri = MessagingService.whatsAppAppUri(
        '98765 43210',
        'Hello World\n*Bold*',
      );
      expect(
        uri.toString(),
        'whatsapp://send?phone=919876543210&text=Hello%20World%0A*Bold*',
      );
    });

    test('wa.me fallback link', () {
      expect(
        MessagingService.whatsAppWebUri('9876543210', 'Hi & bye').toString(),
        'https://wa.me/919876543210?text=Hi%20%26%20bye',
      );
    });

    test('SMS link uses %20 (not +) for spaces', () {
      expect(
        MessagingService.smsUri('9876543210', 'Hi there').toString(),
        'sms:9876543210?body=Hi%20there',
      );
    });
  });

  group('openWhatsApp', () {
    test('opens the WhatsApp app when it can be launched', () async {
      final opener = FakeOpener();
      final result = await MessagingService(opener: opener)
          .openWhatsApp('9876543210', 'hi');
      expect(result, MessagingResult.opened);
      expect(opener.opened.single.scheme, 'whatsapp');
    });

    test('falls back to wa.me when the app link cannot be handled', () async {
      final opener = FakeOpener(canOpenApp: false);
      final result = await MessagingService(opener: opener)
          .openWhatsApp('9876543210', 'hi');
      expect(result, MessagingResult.opened);
      expect(opener.opened.single.host, 'wa.me');
    });

    test('reports unavailable when nothing can open the link', () async {
      final opener = FakeOpener(
        canOpenApp: false,
        openResults: {'https': false},
      );
      expect(
        await MessagingService(opener: opener).openWhatsApp('9876543210', 'hi'),
        MessagingResult.unavailable,
      );
    });

    test('rejects invalid numbers without launching anything', () async {
      final opener = FakeOpener();
      expect(
        await MessagingService(opener: opener).openWhatsApp('123', 'hi'),
        MessagingResult.invalidNumber,
      );
      expect(opener.opened, isEmpty);
    });
  });

  group('openSms', () {
    test('opens the SMS composer', () async {
      final opener = FakeOpener();
      expect(
        await MessagingService(opener: opener).openSms('9876543210', 'hi'),
        MessagingResult.opened,
      );
      expect(opener.opened.single.scheme, 'sms');
    });

    test('reports unavailable when no SMS app handles the link', () async {
      final opener = FakeOpener(openResults: {'sms': false});
      expect(
        await MessagingService(opener: opener).openSms('9876543210', 'hi'),
        MessagingResult.unavailable,
      );
    });

    test('rejects invalid numbers', () async {
      final opener = FakeOpener();
      expect(
        await MessagingService(opener: opener).openSms('', 'hi'),
        MessagingResult.invalidNumber,
      );
      expect(opener.opened, isEmpty);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/message_templates.dart';
import 'package:hitzone_flutter/models/app_notification.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/providers/core_providers.dart';
import 'package:hitzone_flutter/providers/notifications_provider.dart';
import 'package:hitzone_flutter/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer containerWith(SharedPreferences prefs) {
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

Booking booking(
  String id, {
  String start = '10:00',
  String end = '11:00',
  String date = '2026-11-03',
}) => Booking(
  id: id,
  name: 'Amit',
  phone: '9',
  date: date,
  startTime: start,
  endTime: end,
  status: BookingStatus.confirmed,
  amount: 0,
  boxId: '1',
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('settings persist across restarts', () {
    test('defaults', () {
      final s = containerWith(prefs).read(settingsProvider);
      expect(s.darkMode, isFalse);
      expect(s.waTemplate, MessageTemplates.defaultWhatsApp);
      expect(s.smsTemplate, MessageTemplates.defaultSms);
      expect(s.recurringWaTemplate, MessageTemplates.defaultRecurringWhatsApp);
      expect(s.conflictDetection, isTrue);
      expect(s.whatsappAlerts, isTrue);
    });

    test('dark mode, templates, toggles and ground details survive a new container', () async {
      final first = containerWith(prefs);
      final n = first.read(settingsProvider.notifier);
      await n.setDarkMode(true);
      await n.saveWaTemplate('WA {name}');
      await n.saveSmsTemplate('SMS {name}');
      await n.saveRecurringTemplate('REC {weeks}');
      await n.setConflictDetection(false);
      await n.setWhatsappAlerts(false);
      await n.saveGround(
        name: 'My Ground',
        address: 'Addr',
        contact: '123',
        opens: '07:00',
        closes: '22:00',
      );

      // Same prefs, brand new container == app restart.
      final s = containerWith(prefs).read(settingsProvider);
      expect(s.darkMode, isTrue);
      expect(s.waTemplate, 'WA {name}');
      expect(s.smsTemplate, 'SMS {name}');
      expect(s.recurringWaTemplate, 'REC {weeks}');
      expect(s.conflictDetection, isFalse);
      expect(s.whatsappAlerts, isFalse);
      expect(
        (s.groundName, s.address, s.contact, s.opens, s.closes),
        ('My Ground', 'Addr', '123', '07:00', '22:00'),
      );
    });
  });

  group('notifications', () {
    test('add puts the newest first and counts unread', () {
      final c = containerWith(prefs);
      final n = c.read(notificationsProvider.notifier);
      n.add('First', 'a', NotificationType.booking);
      n.add('Second', 'b', NotificationType.conflict);
      expect(c.read(notificationsProvider).map((x) => x.title), [
        'Second',
        'First',
      ]);
      expect(c.read(unreadNotificationsProvider), 2);
    });

    test('mark one / all as read', () {
      final c = containerWith(prefs);
      final n = c.read(notificationsProvider.notifier);
      n.add('A', 'a', NotificationType.info, id: 'a');
      n.add('B', 'b', NotificationType.info, id: 'b');
      n.markRead('a');
      expect(c.read(unreadNotificationsProvider), 1);
      n.markAllRead();
      expect(c.read(unreadNotificationsProvider), 0);
    });

    test('notifications and read state persist', () {
      final first = containerWith(prefs);
      final n = first.read(notificationsProvider.notifier);
      n.add('A', 'a', NotificationType.success, id: 'a');
      n.add('B', 'b', NotificationType.info, id: 'b');
      n.markRead('a');

      final again = containerWith(prefs).read(notificationsProvider);
      expect(again.map((x) => x.id), ['b', 'a']);
      expect(again.firstWhere((x) => x.id == 'a').read, isTrue);
      expect(again.firstWhere((x) => x.id == 'b').read, isFalse);
    });

    test('the list is capped', () {
      final c = containerWith(prefs);
      final n = c.read(notificationsProvider.notifier);
      for (var i = 0; i < NotificationsNotifier.maxItems + 10; i++) {
        n.add('T$i', 'm', NotificationType.info);
      }
      expect(
        c.read(notificationsProvider),
        hasLength(NotificationsNotifier.maxItems),
      );
    });

    test(
      'reminders are raised once per booking, even when synced repeatedly',
      () {
        final c = containerWith(prefs);
        final n = c.read(notificationsProvider.notifier);
        final now = DateTime(2026, 11, 3, 9, 30);
        final list = [booking('1'), booking('2', start: '15:00', end: '16:00')];
        n.syncReminders(list, now);
        n.syncReminders(list, now.add(const Duration(minutes: 1)));
        final reminders = c
            .read(notificationsProvider)
            .where((x) => x.type == NotificationType.reminder)
            .toList();
        expect(reminders, hasLength(1));
        expect(reminders.single.message, contains('Amit'));
      },
    );
  });
}

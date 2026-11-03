import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/message_templates.dart';

void main() {
  group('fill', () {
    test('replaces every occurrence of a variable', () {
      expect(
        MessageTemplates.fill('Hi {name}, {name}!', {'name': 'Rahul'}),
        'Hi Rahul, Rahul!',
      );
    });

    test('leaves unknown placeholders untouched', () {
      expect(
        MessageTemplates.fill('Hi {name} {typo}', {'name': 'Rahul'}),
        'Hi Rahul {typo}',
      );
    });

    test('does not re-expand values that look like placeholders', () {
      expect(
        MessageTemplates.fill('{name} {from}', {
          'name': '{from}',
          'from': '7 AM',
        }),
        '{from} 7 AM',
      );
    });

    test('handles multi-line templates', () {
      expect(MessageTemplates.fill('A {x}\nB {x}', {'x': '1'}), 'A 1\nB 1');
    });
  });

  group('default templates', () {
    final vars = MessageTemplates.bookingVars(
      name: 'Rahul Shah',
      date: '2026-11-03',
      from: '19:00',
      to: '21:00',
    );

    test('WhatsApp template is fully filled', () {
      final msg = MessageTemplates.fill(MessageTemplates.defaultWhatsApp, vars);
      expect(msg, contains('Hello Rahul Shah'));
      expect(msg, contains('3 Nov 2026'));
      expect(msg, contains('7:00 PM – 9:00 PM'));
      expect(msg, isNot(contains('{')));
    });

    test('SMS template is fully filled', () {
      final msg = MessageTemplates.fill(MessageTemplates.defaultSms, vars);
      expect(msg, contains('Hi Rahul Shah'));
      expect(msg, contains('Time: 7:00 PM-9:00 PM'));
      expect(msg, isNot(contains('{')));
    });

    test('empty name falls back to "Customer"', () {
      final v = MessageTemplates.bookingVars(
        name: '',
        date: '2026-11-03',
        from: '07:00',
        to: '08:00',
      );
      expect(v['name'], 'Customer');
    });
  });

  group('recurring', () {
    final vars = MessageTemplates.recurringVars(
      name: 'Kiran',
      startDate: '2026-11-08',
      from: '19:00',
      to: '21:00',
      weeks: 4,
      days: [0, 3],
      dates: ['2026-11-08', '2026-11-11'],
    );

    test('variables', () {
      expect(vars['weeks'], '4');
      expect(vars['days'], 'Sun, Wed');
      expect(vars['dates'], '📅 8 Nov 2026\n📅 11 Nov 2026');
    });

    test('default recurring template is fully filled', () {
      final msg = MessageTemplates.fill(
        MessageTemplates.defaultRecurringWhatsApp,
        vars,
      );
      expect(msg, contains('Duration: 4 Weeks'));
      expect(msg, contains('Starting Date: 8 Nov 2026'));
      expect(msg, isNot(contains('{')));
    });

    test('custom template can use {days} and {dates}', () {
      final msg = MessageTemplates.fill('Days: {days}\n{dates}', vars);
      expect(msg, 'Days: Sun, Wed\n📅 8 Nov 2026\n📅 11 Nov 2026');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/formatters.dart';
import 'package:hitzone_flutter/models/booking.dart';

void main() {
  group('time helpers', () {
    test('t12 converts 24h to 12h', () {
      expect(t12('00:00'), '12:00 AM');
      expect(t12('07:00'), '7:00 AM');
      expect(t12('12:30'), '12:30 PM');
      expect(t12('19:05'), '7:05 PM');
      expect(t12('23:59'), '11:59 PM');
      expect(t12(''), '');
      expect(t12(null), '');
    });

    test('normalizeTime drops seconds from Postgres time values', () {
      expect(normalizeTime('07:00:00'), '07:00');
      expect(normalizeTime('7:5'), '07:05');
      expect(normalizeTime('19:30'), '19:30');
    });

    test('parseMinutes / minutesToTime round-trip', () {
      expect(parseMinutes('01:30'), 90);
      expect(minutesToTime(90), '01:30');
      expect(minutesToTime(parseMinutes('23:30') + 60), '00:30');
      expect(parseMinutes('garbage'), 0);
    });

    test('calcHours rounds to one decimal', () {
      expect(calcHours('07:00', '09:00'), 2);
      expect(calcHours('07:00', '09:30'), 2.5);
      expect(calcHours('07:00', '07:20'), 0.3);
      expect(calcHours('09:00', '07:00'), -2);
      expect(calcHours('', '07:00'), 0);
    });
  });

  group('dates', () {
    test('dateKey / parseDateKey round-trip', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(parseDateKey('2026-11-03'), DateTime(2026, 11, 3));
    });

    test('todayKey uses the local calendar date', () {
      expect(todayKey(DateTime(2026, 11, 3, 23, 59)), '2026-11-03');
      expect(todayKey(DateTime(2026, 11, 3, 0, 1)), '2026-11-03');
    });

    test('fmtDate', () {
      expect(fmtDate('2026-11-03'), '3 Nov 2026');
      expect(fmtDate(''), '');
      expect(fmtDate(null), '');
    });

    test('timeAgo', () {
      final now = DateTime(2026, 11, 3, 12);
      expect(
        timeAgo(now.subtract(const Duration(seconds: 20)), now),
        'Just now',
      );
      expect(
        timeAgo(now.subtract(const Duration(minutes: 45)), now),
        '45 min ago',
      );
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now), '3 hr ago');
      expect(
        timeAgo(now.subtract(const Duration(hours: 30)), now),
        'Yesterday',
      );
    });
  });

  group('text helpers', () {
    test('inr uses Indian digit grouping', () {
      expect(inr(0), '₹0');
      expect(inr(999), '₹999');
      expect(inr(1500), '₹1,500');
      expect(inr(1234567), '₹12,34,567');
      expect(inr(1499.6), '₹1,500');
    });

    test('initials', () {
      expect(initials('Rahul Shah'), 'RS');
      expect(initials('rahul'), 'R');
      expect(initials('Amit Kumar Patel'), 'AK');
      expect(initials(''), '?');
      expect(initials(null), '?');
    });

    test('cleanPhone keeps 10 digits and drops +91', () {
      expect(cleanPhone('98765 43210'), '9876543210');
      expect(cleanPhone('+91 98765 43210'), '9876543210');
      expect(cleanPhone('9876543210123'), '9876543210');
      expect(cleanPhone('abc'), '');
    });

    test('isValidPhone requires exactly 10 digits', () {
      expect(isValidPhone('9876543210'), isTrue);
      expect(isValidPhone('987654321'), isFalse);
      expect(isValidPhone('98765432101'), isFalse);
      expect(isValidPhone('98765x3210'), isFalse);
    });
  });

  group('bookingAmount', () {
    test('hours x rate', () {
      expect(bookingAmount('07:00', '09:00', 1500), 3000);
      expect(bookingAmount('07:00', '08:30', 1000), 1500);
    });

    test('handles non half-hour boundaries exactly', () {
      expect(bookingAmount('07:15', '08:45', 1000), 1500);
    });

    test('zero for empty or inverted ranges', () {
      expect(bookingAmount('09:00', '09:00', 1500), 0);
      expect(bookingAmount('10:00', '09:00', 1500), 0);
    });
  });
}

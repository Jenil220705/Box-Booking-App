import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/conflict_detector.dart';
import 'package:hitzone_flutter/core/utils/formatters.dart';
import 'package:hitzone_flutter/models/booking.dart';

Booking b(
  String id, {
  String date = '2026-11-10',
  String start = '10:00',
  String end = '12:00',
  String box = '1',
  BookingStatus status = BookingStatus.confirmed,
  String? group,
}) => Booking(
  id: id,
  name: 'N$id',
  phone: '9000000000',
  date: date,
  startTime: start,
  endTime: end,
  status: status,
  amount: 0,
  boxId: box,
  recurringGroupId: group,
);

Booking? check(
  List<Booking> existing,
  String start,
  String end, {
  String date = '2026-11-10',
  String box = '1',
  String? excludeId,
  String? excludeGroup,
}) => ConflictDetector.findConflict(
  existing: existing,
  date: date,
  boxId: box,
  startMinutes: parseMinutes(start),
  endMinutes: parseMinutes(end),
  excludeBookingId: excludeId,
  excludeGroupId: excludeGroup,
);

void main() {
  final existing = [b('1')]; // 10:00 - 12:00

  group('overlap rules', () {
    test('11:00-13:00 overlaps 10:00-12:00 (spec example)', () {
      expect(check(existing, '11:00', '13:00')?.id, '1');
    });

    test('12:00-14:00 is adjacent and allowed (spec example)', () {
      expect(check(existing, '12:00', '14:00'), isNull);
    });

    test('08:00-10:00 is adjacent before and allowed', () {
      expect(check(existing, '08:00', '10:00'), isNull);
    });

    test('contained, containing, identical and partial overlaps conflict', () {
      expect(check(existing, '10:30', '11:30'), isNotNull); // inside
      expect(check(existing, '09:00', '13:00'), isNotNull); // around
      expect(check(existing, '10:00', '12:00'), isNotNull); // identical
      expect(check(existing, '09:00', '10:30'), isNotNull); // starts before
      expect(check(existing, '11:59', '13:00'), isNotNull); // one minute
    });

    test('clearly separate slots do not conflict', () {
      expect(check(existing, '14:00', '16:00'), isNull);
      expect(check(existing, '06:00', '08:00'), isNull);
    });
  });

  group('scoping', () {
    test('a different box never conflicts', () {
      expect(check(existing, '11:00', '13:00', box: '2'), isNull);
    });

    test('a different date never conflicts', () {
      expect(check(existing, '11:00', '13:00', date: '2026-11-11'), isNull);
    });

    test('cancelled bookings do not block a slot', () {
      final cancelled = [b('1', status: BookingStatus.cancelled)];
      expect(check(cancelled, '10:00', '12:00'), isNull);
    });

    test('pending and completed bookings still block', () {
      expect(
        check([b('1', status: BookingStatus.pending)], '11:00', '12:00'),
        isNotNull,
      );
      expect(
        check([b('1', status: BookingStatus.completed)], '11:00', '12:00'),
        isNotNull,
      );
    });
  });

  group('exclusions', () {
    test('editing a booking ignores itself', () {
      expect(check(existing, '10:00', '12:00', excludeId: '1'), isNull);
    });

    test('editing still conflicts with other bookings', () {
      final two = [b('1'), b('2', start: '12:00', end: '14:00')];
      expect(check(two, '11:00', '13:00', excludeId: '1')?.id, '2');
    });

    test('a recurring group is ignored when it is being regenerated', () {
      final grouped = [b('1', group: 'g1')];
      expect(check(grouped, '10:00', '12:00', excludeGroup: 'g1'), isNull);
      expect(
        check(grouped, '10:00', '12:00', excludeGroup: 'other'),
        isNotNull,
      );
    });
  });

  group('conflictingDates', () {
    test('lists every date that clashes', () {
      final rows = [
        b('1', date: '2026-11-10'),
        b('2', date: '2026-11-17'),
        b('3', date: '2026-11-24', start: '14:00', end: '16:00'),
      ];
      final dates = ConflictDetector.conflictingDates(
        existing: rows,
        dates: ['2026-11-10', '2026-11-17', '2026-11-24'],
        boxId: '1',
        startMinutes: parseMinutes('11:00'),
        endMinutes: parseMinutes('13:00'),
      );
      expect(dates, ['2026-11-10', '2026-11-17']);
    });
  });
}

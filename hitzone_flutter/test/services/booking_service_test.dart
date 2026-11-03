import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/errors.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';
import 'package:hitzone_flutter/services/booking_service.dart';

import '../helpers/fakes.dart';

BookingDraft draft({
  String name = 'Rahul Shah',
  String phone = '9876543210',
  String date = '2026-11-10',
  String start = '10:00',
  String end = '12:00',
  String box = '1',
  double rate = 1500,
  BookingStatus status = BookingStatus.confirmed,
}) => BookingDraft(
  name: name,
  phone: phone,
  date: date,
  startTime: start,
  endTime: end,
  boxId: box,
  ratePerHour: rate,
  status: status,
);

RecurringDraft recur({
  String name = 'Kiran Dave',
  String phone = '9123456780',
  String box = '1',
  List<int> days = const [1, 3],
  String start = '19:00',
  String end = '21:00',
  int weeks = 2,
  double rate = 1200,
  String startDate = '2026-11-02', // a Monday
}) => RecurringDraft(
  name: name,
  phone: phone,
  boxId: box,
  days: days,
  startTime: start,
  endTime: end,
  weeks: weeks,
  ratePerHour: rate,
  startDate: startDate,
);

void main() {
  late FakeBookingRepository bookings;
  late FakeCustomerRepository customers;
  late FakeRecurringRepository recurring;
  late BookingService service;

  setUp(() {
    bookings = FakeBookingRepository();
    customers = FakeCustomerRepository();
    recurring = FakeRecurringRepository();
    service = BookingService(
      bookings: bookings,
      customers: customers,
      recurring: recurring,
      clock: () => DateTime(2026, 11, 3, 9),
    );
  });

  group('create booking', () {
    test('saves the booking with amount = hours x rate', () async {
      final out = await service.createBooking(draft());
      expect(bookings.rows, hasLength(1));
      expect(out.booking.amount, 3000);
      expect(out.booking.ratePerHour, 1500);
      expect(out.booking.status, BookingStatus.confirmed);
    });

    test('creates the customer on the first booking', () async {
      final out = await service.createBooking(draft());
      expect(out.newCustomer, isTrue);
      final c = customers.byPhone('9876543210')!;
      expect(c.name, 'Rahul Shah');
      expect(c.cnt, 1);
      expect(c.last, '3 Nov 2026');
    });

    test('increments the lifetime counter for a returning customer', () async {
      await service.createBooking(draft());
      final out = await service.createBooking(
        draft(start: '14:00', end: '15:00'),
      );
      expect(out.newCustomer, isFalse);
      expect(customers.rows, hasLength(1));
      expect(customers.byPhone('9876543210')!.cnt, 2);
    });

    test('rejects invalid input before touching the backend', () async {
      Future<void> expectInvalid(BookingDraft d, String message) async {
        await expectLater(
          service.createBooking(d),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              message,
            ),
          ),
        );
      }

      await expectInvalid(draft(name: '  '), 'Fill all required fields');
      await expectInvalid(draft(box: ''), 'Fill all required fields');
      await expectInvalid(
        draft(phone: '12345'),
        'Enter valid 10 digit mobile number',
      );
      await expectInvalid(
        draft(start: '12:00', end: '12:00'),
        'End time must be after start time',
      );
      await expectInvalid(
        draft(start: '14:00', end: '12:00'),
        'End time must be after start time',
      );
      expect(bookings.rows, isEmpty);
      expect(customers.rows, isEmpty);
    });
  });

  group('conflict detection', () {
    setUp(() => bookings.seed()); // 10:00-12:00 on 2026-11-10, box 1

    test('overlapping slot on the same box is rejected', () async {
      await expectLater(
        service.createBooking(draft(start: '11:00', end: '13:00')),
        throwsA(isA<SlotConflictException>()),
      );
      expect(bookings.rows, hasLength(1));
      expect(
        customers.rows,
        isEmpty,
        reason: 'a rejected booking must not touch customers',
      );
    });

    test('adjacent slot is allowed', () async {
      await service.createBooking(draft(start: '12:00', end: '14:00'));
      expect(bookings.rows, hasLength(2));
    });

    test('same time on another box or another date is allowed', () async {
      await service.createBooking(
        draft(box: '2', start: '10:00', end: '12:00'),
      );
      await service.createBooking(
        draft(date: '2026-11-11', start: '10:00', end: '12:00'),
      );
      expect(bookings.rows, hasLength(3));
    });

    test('a cancelled booking frees its slot', () async {
      bookings.rows.clear();
      bookings.seed(status: BookingStatus.cancelled);
      await service.createBooking(draft(start: '10:00', end: '12:00'));
      expect(bookings.rows, hasLength(2));
    });

    test('detection can be switched off', () async {
      await service.createBooking(
        draft(start: '11:00', end: '13:00'),
        detectConflicts: false,
      );
      expect(bookings.rows, hasLength(2));
    });

    test('the error names the clashing booking', () async {
      await expectLater(
        service.createBooking(draft(start: '11:00', end: '13:00')),
        throwsA(
          isA<SlotConflictException>().having(
            (e) => e.message,
            'message',
            contains('Seed'),
          ),
        ),
      );
    });
  });

  group('edit booking', () {
    test('can keep its own slot and change other fields', () async {
      final created = (await service.createBooking(draft())).booking;
      final out = await service.updateBooking(
        created,
        draft(name: 'Rahul S', rate: 2000),
      );
      expect(out.booking.name, 'Rahul S');
      expect(out.booking.amount, 4000);
      expect(bookings.rows, hasLength(1));
    });

    test('moving into another booking is rejected', () async {
      final a = (await service.createBooking(draft())).booking;
      await service.createBooking(
        draft(start: '12:00', end: '14:00', phone: '9000000001'),
      );
      await expectLater(
        service.updateBooking(a, draft(start: '11:00', end: '13:00')),
        throwsA(isA<SlotConflictException>()),
      );
      expect(bookings.rows.firstWhere((b) => b.id == a.id).startTime, '10:00');
    });

    test('changing the phone moves the customer counters', () async {
      final a = (await service.createBooking(draft())).booking;
      await service.updateBooking(a, draft(phone: '9000000002', name: 'Other'));
      expect(customers.byPhone('9876543210')!.cnt, 0);
      expect(customers.byPhone('9000000002')!.cnt, 1);
    });

    test('status can be changed', () async {
      final a = (await service.createBooking(draft())).booking;
      await service.changeStatus(a, BookingStatus.cancelled);
      expect(bookings.rows.single.status, BookingStatus.cancelled);
    });
  });

  group('delete booking', () {
    test('removes the booking and decrements the counter', () async {
      final a = (await service.createBooking(draft())).booking;
      await service.deleteBooking(a);
      expect(bookings.rows, isEmpty);
      expect(customers.byPhone('9876543210')!.cnt, 0);
    });

    test('the counter never goes below zero', () async {
      final seeded = bookings.seed(phone: '9111111111');
      customers.seed(phone: '9111111111', cnt: 0);
      await service.deleteBooking(seeded);
      expect(customers.byPhone('9111111111')!.cnt, 0);
    });

    test('a missing customer row is not an error', () async {
      final seeded = bookings.seed(phone: '9222222222');
      await service.deleteBooking(seeded);
      expect(bookings.rows, isEmpty);
    });
  });

  group('reduce by one hour', () {
    test('shortens the booking and re-prices it at its own rate', () async {
      final b = bookings.seed(start: '10:00', end: '13:00', rate: 2000);
      final updated = await service.reduceOneHour(b);
      expect(updated.endTime, '12:00');
      expect(updated.amount, 4000);
      expect(bookings.rows.single.endTime, '12:00');
    });

    test('refuses to go below one hour', () async {
      final b = bookings.seed(start: '10:00', end: '11:00');
      await expectLater(
        service.reduceOneHour(b),
        throwsA(isA<ValidationException>()),
      );
      expect(bookings.rows.single.endTime, '11:00');
    });

    test('uses the implied rate for old rows without rate_per_hour', () async {
      const old = Booking(
        id: '9',
        name: 'Old',
        phone: '9333333333',
        date: '2026-11-10',
        startTime: '10:00',
        endTime: '12:00',
        status: BookingStatus.confirmed,
        amount: 3000,
        boxId: '1',
      );
      bookings.rows.add(old);
      final updated = await service.reduceOneHour(old);
      expect(updated.amount, 1500);
    });
  });

  group('recurring bookings', () {
    test('generates one booking per day per week', () async {
      final out = await service.createRecurring(recur());
      // Mon+Wed for 2 weeks starting Mon 2 Nov 2026.
      expect(out.bookings.map((b) => b.date), [
        '2026-11-02',
        '2026-11-04',
        '2026-11-09',
        '2026-11-11',
      ]);
      expect(bookings.rows, hasLength(4));
      expect(recurring.rows, hasLength(1));
      expect(
        bookings.rows.every((b) => b.recurringGroupId == out.group.id),
        isTrue,
      );
      expect(
        bookings.rows.every((b) => b.amount == 2400 && b.ratePerHour == 1200),
        isTrue,
      );
      expect(
        bookings.rows.every((b) => b.status == BookingStatus.confirmed),
        isTrue,
      );
    });

    test('adds all generated bookings to the customer counter', () async {
      final out = await service.createRecurring(recur());
      expect(out.newCustomer, isTrue);
      expect(customers.byPhone('9123456780')!.cnt, 4);
    });

    test(
      'a conflict on any date aborts everything and lists the dates',
      () async {
        bookings.seed(date: '2026-11-04', start: '20:00', end: '22:00');
        bookings.seed(date: '2026-11-11', start: '18:00', end: '19:30');
        final before = bookings.rows.length;
        await expectLater(
          service.createRecurring(recur()),
          throwsA(
            isA<SlotConflictException>().having((e) => e.dates, 'dates', [
              '2026-11-04',
              '2026-11-11',
            ]),
          ),
        );
        expect(bookings.rows, hasLength(before));
        expect(recurring.rows, isEmpty, reason: 'no orphan group');
        expect(customers.rows, isEmpty);
      },
    );

    test('bookings on a different box do not conflict', () async {
      bookings.seed(date: '2026-11-04', start: '19:00', end: '21:00', box: '2');
      final out = await service.createRecurring(recur());
      expect(out.bookings, hasLength(4));
    });

    test('adjacent bookings do not conflict', () async {
      bookings.seed(date: '2026-11-04', start: '21:00', end: '22:00');
      expect((await service.createRecurring(recur())).bookings, hasLength(4));
    });

    test('rolls the group back if the bookings cannot be inserted', () async {
      bookings.failInsertMany = true;
      await expectLater(service.createRecurring(recur()), throwsA(anything));
      expect(recurring.rows, isEmpty);
      expect(bookings.rows, isEmpty);
    });

    test('validation: days, weeks, rate, phone, times', () async {
      Future<void> expectInvalid(RecurringDraft d) => expectLater(
        service.createRecurring(d),
        throwsA(isA<ValidationException>()),
      );
      await expectInvalid(recur(days: []));
      await expectInvalid(recur(weeks: 0));
      await expectInvalid(recur(weeks: 53));
      await expectInvalid(recur(rate: 0));
      await expectInvalid(recur(phone: '123'));
      await expectInvalid(recur(start: '21:00', end: '19:00'));
      expect(recurring.rows, isEmpty);
    });

    test(
      'duplicate weekday selections do not create duplicate bookings',
      () async {
        final out = await service.createRecurring(
          recur(days: [1, 1], weeks: 2),
        );
        expect(out.bookings, hasLength(2));
      },
    );

    group('edit', () {
      late RecurringGroup group;

      setUp(() async {
        group = (await service.createRecurring(recur())).group;
      });

      test('regenerates the bookings from the new pattern', () async {
        final out = await service.updateRecurring(
          group,
          recur(days: [5], weeks: 3, start: '18:00', end: '19:00'),
        );
        expect(out.bookings.map((b) => b.date), [
          '2026-11-06',
          '2026-11-13',
          '2026-11-20',
        ]);
        expect(bookings.rows, hasLength(3));
        expect(
          bookings.rows.every((b) => b.recurringGroupId == group.id),
          isTrue,
        );
        expect(recurring.rows.single.days, [5]);
        expect(recurring.rows.single.weeks, 3);
      });

      test('its own previous bookings never count as conflicts', () async {
        final out = await service.updateRecurring(group, recur());
        expect(out.bookings, hasLength(4));
      });

      test('still conflicts with other bookings and changes nothing', () async {
        bookings.seed(
          date: '2026-11-06',
          start: '19:30',
          end: '20:30',
          phone: '9444444444',
        );
        await expectLater(
          service.updateRecurring(group, recur(days: [5])),
          throwsA(
            isA<SlotConflictException>().having((e) => e.dates, 'dates', [
              '2026-11-06',
            ]),
          ),
        );
        expect(
          bookings.rows.where((b) => b.recurringGroupId == group.id),
          hasLength(4),
        );
        expect(recurring.rows.single.days, [1, 3]);
      });
    });

    test(
      'deleting a group removes its bookings and leaves others alone',
      () async {
        final group = (await service.createRecurring(recur())).group;
        final other = bookings.seed(date: '2026-12-01');
        await service.deleteRecurring(group);
        expect(recurring.rows, isEmpty);
        expect(bookings.rows.map((b) => b.id), [other.id]);
      },
    );
  });
}

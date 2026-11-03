import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/analytics.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/expense.dart';

Booking b(
  String id, {
  String date = '2026-11-10',
  String start = '10:00',
  String end = '12:00',
  double amount = 3000,
  BookingStatus status = BookingStatus.confirmed,
  String phone = '9000000000',
  String name = 'Cust',
}) => Booking(
  id: id,
  name: name,
  phone: phone,
  date: date,
  startTime: start,
  endTime: end,
  status: status,
  amount: amount,
  boxId: '1',
);

Expense e(
  String id,
  String date,
  double amount, [
  String category = 'Ground',
]) => Expense(
  id: id,
  title: 't',
  amount: amount,
  category: category,
  note: '',
  expenseDate: date,
);

void main() {
  group('revenue', () {
    test('sums non-cancelled bookings only', () {
      final list = [
        b('1', amount: 3000),
        b('2', amount: 1500, status: BookingStatus.pending),
        b('3', amount: 3000, status: BookingStatus.completed),
        b('4', amount: 9999, status: BookingStatus.cancelled),
      ];
      expect(Analytics.revenue(list), 7500);
      expect(Analytics.active(list), hasLength(3));
    });

    test('empty list is zero', () {
      expect(Analytics.revenue(const []), 0);
    });

    test('profit = revenue - expenses', () {
      final revenue = Analytics.revenue([b('1', amount: 3000)]);
      final spent = Analytics.totalExpenses([
        e('1', '2026-11-10', 1200),
        e('2', '2026-11-10', 300),
      ]);
      expect(spent, 1500);
      expect(revenue - spent, 1500);
    });
  });

  group('DateRange', () {
    test('month covers first to last day (incl. leap February)', () {
      final nov = DateRange.month(DateTime(2026, 11, 15));
      expect((nov.from, nov.to), ('2026-11-01', '2026-11-30'));
      final feb = DateRange.month(DateTime(2028, 2, 10));
      expect(feb.to, '2028-02-29');
      expect(feb.days, 29);
    });

    test('week is Sunday to Saturday', () {
      final tue = DateRange.week(DateTime(2026, 11, 3));
      expect((tue.from, tue.to), ('2026-11-01', '2026-11-07'));
      final sun = DateRange.week(DateTime(2026, 11, 1));
      expect((sun.from, sun.to), ('2026-11-01', '2026-11-07'));
      final sat = DateRange.week(DateTime(2026, 11, 7));
      expect((sat.from, sat.to), ('2026-11-01', '2026-11-07'));
    });

    test('contains is inclusive on both ends', () {
      const r = DateRange('2026-11-01', '2026-11-30');
      expect(r.contains('2026-11-01'), isTrue);
      expect(r.contains('2026-11-30'), isTrue);
      expect(r.contains('2026-10-31'), isFalse);
      expect(r.contains('2026-12-01'), isFalse);
    });

    test('inRange filters bookings, null range keeps everything', () {
      final list = [b('1', date: '2026-11-05'), b('2', date: '2026-12-05')];
      expect(
        Analytics.inRange(
          list,
          DateRange.month(DateTime(2026, 11, 1)),
        ).map((x) => x.id),
        ['1'],
      );
      expect(Analytics.inRange(list, null), hasLength(2));
    });
  });

  group('peak hour & occupancy', () {
    test('peak hour is the busiest start hour, earliest wins ties', () {
      final list = [
        b('1', start: '19:00', end: '20:00'),
        b('2', start: '19:30', end: '20:30'),
        b('3', start: '07:00', end: '08:00'),
        b('4', start: '07:30', end: '08:30'),
        b('5', start: '10:00', end: '11:00'),
      ];
      expect(Analytics.startHourCounts(list), {19: 2, 7: 2, 10: 1});
      expect(Analytics.peakHour(list), 7);
      expect(Analytics.peakHour(const []), isNull);
    });

    test('occupancy = booked hours / open hours', () {
      // 2 bookings x 2h in a 12h day on one box.
      final list = [b('1'), b('2', start: '14:00', end: '16:00')];
      final pct = Analytics.occupancyPercent(
        bookings: list,
        days: 1,
        openMinutesPerDay: 720,
        boxCount: 1,
      );
      expect(pct, closeTo(33.33, 0.01));
    });

    test(
      'occupancy scales with box count, ignores cancelled and clamps at 100',
      () {
        final list = [b('1'), b('2', status: BookingStatus.cancelled)];
        expect(
          Analytics.occupancyPercent(
            bookings: list,
            days: 1,
            openMinutesPerDay: 720,
            boxCount: 2,
          ),
          closeTo(8.33, 0.01),
        );
        final many = List.generate(20, (i) => b('$i'));
        expect(
          Analytics.occupancyPercent(
            bookings: many,
            days: 1,
            openMinutesPerDay: 720,
            boxCount: 1,
          ),
          100,
        );
        expect(
          Analytics.occupancyPercent(
            bookings: list,
            days: 0,
            openMinutesPerDay: 720,
            boxCount: 1,
          ),
          0,
        );
      },
    );
  });

  group('series & groupings', () {
    test('dailyRevenue zero-fills every day of the range', () {
      final list = [
        b('1', date: '2026-11-02', amount: 100),
        b('2', date: '2026-11-02', amount: 50),
        b('3', date: '2026-11-04', amount: 70),
        b(
          '4',
          date: '2026-11-04',
          amount: 999,
          status: BookingStatus.cancelled,
        ),
      ];
      final pts = Analytics.dailyRevenue(
        list,
        const DateRange('2026-11-01', '2026-11-05'),
      );
      expect(pts.map((p) => p.value), [0, 150, 0, 70, 0]);
      expect(pts.first.date, '2026-11-01');
    });

    test('statusCounts includes every status', () {
      final counts = Analytics.statusCounts([
        b('1'),
        b('2'),
        b('3', status: BookingStatus.cancelled),
      ]);
      expect(counts[BookingStatus.confirmed], 2);
      expect(counts[BookingStatus.cancelled], 1);
      expect(counts[BookingStatus.pending], 0);
    });

    test('customerTotals groups by phone and skips cancelled', () {
      final totals = Analytics.customerTotals([
        b('1', phone: '111', amount: 100, name: 'A'),
        b('2', phone: '111', amount: 200, name: 'A'),
        b('3', phone: '222', amount: 50, name: 'B'),
        b(
          '4',
          phone: '222',
          amount: 500,
          name: 'B',
          status: BookingStatus.cancelled,
        ),
      ]);
      expect(totals['111']!.bookings, 2);
      expect(totals['111']!.revenue, 300);
      expect(totals['222']!.revenue, 50);
    });

    test('expensesByCategory', () {
      final totals = Analytics.expensesByCategory([
        e('1', 'd', 10, 'Water'),
        e('2', 'd', 5, 'Water'),
        e('3', 'd', 7, 'Salary'),
      ]);
      expect(totals, {'Water': 15, 'Salary': 7});
    });
  });

  group('auto-completion rule', () {
    test('confirmed bookings that already ended are due for completion', () {
      final now = DateTime(2026, 11, 10, 13, 0);
      final list = [
        b('ended'), // 10-12 today
        b('running', start: '12:00', end: '14:00'),
        b('future', date: '2026-11-11'),
        b('past-day', date: '2026-11-09'),
        b('pending-ended', status: BookingStatus.pending),
        b('cancelled-ended', status: BookingStatus.cancelled),
      ];
      expect(BookingRules.elapsedConfirmed(list, now).map((x) => x.id), [
        'ended',
        'past-day',
      ]);
    });

    test('a booking ending exactly now is not yet elapsed', () {
      final now = DateTime(2026, 11, 10, 12, 0);
      expect(BookingRules.elapsedConfirmed([b('1')], now), isEmpty);
    });
  });
}

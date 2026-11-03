import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/csv_builder.dart';
import 'package:hitzone_flutter/core/utils/expense_filter.dart';
import 'package:hitzone_flutter/core/utils/reminders.dart';
import 'package:hitzone_flutter/models/app_notification.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/expense.dart';

Expense e(String id, String date, double amount, String category) => Expense(
  id: id,
  title: 'T$id',
  amount: amount,
  category: category,
  note: '',
  expenseDate: date,
);

Booking b(
  String id, {
  String name = 'Rahul, Shah',
  String date = '2026-11-03',
  String start = '10:00',
  String end = '11:00',
  BookingStatus status = BookingStatus.confirmed,
  double amount = 1500,
}) => Booking(
  id: id,
  name: name,
  phone: '9876543210',
  date: date,
  startTime: start,
  endTime: end,
  status: status,
  amount: amount,
  boxId: '1',
);

void main() {
  group('expense filter', () {
    // Tue 3 Nov 2026; week = 1..7 Nov; month = November.
    final now = DateTime(2026, 11, 3, 15);
    final all = [
      e('1', '2026-11-03', 100, 'Ground'), // today
      e('2', '2026-11-01', 200, 'Water'), // this week
      e('3', '2026-11-20', 300, 'Salary'), // this month, later
      e('4', '2026-10-31', 400, 'Ground'), // last month
    ];

    List<String> ids(List<Expense> l) => l.map((x) => x.id).toList();

    test('all', () {
      expect(
        filterExpenses(all, dateFilter: ExpenseDateFilter.all, now: now),
        hasLength(4),
      );
    });

    test('today / week / month', () {
      expect(
        ids(filterExpenses(all, dateFilter: ExpenseDateFilter.today, now: now)),
        ['1'],
      );
      expect(
        ids(filterExpenses(all, dateFilter: ExpenseDateFilter.week, now: now)),
        ['1', '2'],
      );
      expect(
        ids(filterExpenses(all, dateFilter: ExpenseDateFilter.month, now: now)),
        ['1', '2', '3'],
      );
    });

    test('custom range needs both ends and is inclusive', () {
      expect(
        ids(
          filterExpenses(
            all,
            dateFilter: ExpenseDateFilter.custom,
            now: now,
            from: '2026-10-31',
            to: '2026-11-01',
          ),
        ),
        ['2', '4'],
      );
      // Incomplete range -> no date filtering.
      expect(
        filterExpenses(
          all,
          dateFilter: ExpenseDateFilter.custom,
          now: now,
          from: '2026-11-01',
        ),
        hasLength(4),
      );
    });

    test('category filter combines with date filter', () {
      expect(
        ids(
          filterExpenses(
            all,
            dateFilter: ExpenseDateFilter.all,
            now: now,
            category: 'Ground',
          ),
        ),
        ['1', '4'],
      );
      expect(
        ids(
          filterExpenses(
            all,
            dateFilter: ExpenseDateFilter.month,
            now: now,
            category: 'Ground',
          ),
        ),
        ['1'],
      );
    });

    test('topCategory and categoryTotal', () {
      expect(topCategory(all), 'Ground'); // 100 + 400
      expect(topCategory(const []), isNull);
      expect(categoryTotal(all, 'Ground'), 500);
      expect(categoryTotal(all, 'Marketing'), 0);
    });
  });

  group('CSV', () {
    test('escape quotes fields with commas, quotes and newlines', () {
      expect(CsvBuilder.escape('plain'), 'plain');
      expect(CsvBuilder.escape('a,b'), '"a,b"');
      expect(CsvBuilder.escape('say "hi"'), '"say ""hi"""');
      expect(CsvBuilder.escape('a\nb'), '"a\nb"');
      expect(CsvBuilder.escape(null), '');
      expect(CsvBuilder.escape(42), '42');
    });

    test('bookings export has header and one row per booking', () {
      final csv = CsvBuilder.bookings([
        b('1'),
        b('2', status: BookingStatus.cancelled, amount: 0),
      ]);
      final lines = csv.split('\r\n');
      expect(lines.first, 'Name,Phone,Date,From,To,Hours,Amount,Status');
      expect(lines, hasLength(3));
      expect(
        lines[1],
        '"Rahul, Shah",9876543210,2026-11-03,10:00,11:00,1.0,1500,confirmed',
      );
      expect(lines[2], endsWith(',0,cancelled'));
    });

    test('box column is added when a resolver is given', () {
      final csv = CsvBuilder.bookings([b('1')], boxName: (id) => 'Box $id');
      final lines = csv.split('\r\n');
      expect(lines.first, endsWith(',Box'));
      expect(lines[1], endsWith(',Box 1'));
    });
  });

  group('reminders', () {
    final now = DateTime(2026, 11, 3, 9, 30);

    test('dueSoon returns bookings starting within the hour', () {
      final list = [
        b('soon', start: '10:00', end: '11:00'), // in 30 min
        b('edge', start: '10:30', end: '11:30'), // exactly 60 min
        b('later', start: '10:31', end: '11:30'), // 61 min
        b('started', start: '09:00', end: '10:00'), // already started
        b('tomorrow', date: '2026-11-04'),
        b('cancelled', start: '10:00', status: BookingStatus.cancelled),
        b('done', start: '10:00', status: BookingStatus.completed),
        b(
          'pending',
          start: '10:15',
          end: '11:00',
          status: BookingStatus.pending,
        ),
      ];
      expect(ReminderRules.dueSoon(list, now).map((x) => x.id), [
        'soon',
        'edge',
        'pending',
      ]);
    });

    test('reminder id is stable so it is only raised once', () {
      final booking = b('7');
      expect(
        ReminderRules.reminderId(booking),
        ReminderRules.reminderId(booking),
      );
    });

    test('built notification describes the booking', () {
      final n = ReminderRules.build(
        b('7', start: '10:00', end: '11:00', name: 'Amit'),
        now,
      );
      expect(n.type, NotificationType.reminder);
      expect(n.title, 'Upcoming in 30 min');
      expect(n.message, 'Amit · 10:00 AM – 11:00 AM');
    });
  });
}

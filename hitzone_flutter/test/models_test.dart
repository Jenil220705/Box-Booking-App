import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/models/app_notification.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/box.dart';
import 'package:hitzone_flutter/models/customer.dart';
import 'package:hitzone_flutter/models/expense.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';

void main() {
  group('Booking', () {
    test('fromMap normalises Postgres values', () {
      final b = Booking.fromMap({
        'id': 42,
        'customer_name': 'Rahul',
        'phone': '9876543210',
        'booking_date': '2026-11-03',
        'start_time': '07:00:00',
        'end_time': '09:30:00',
        'status': 'pending',
        'amount': '3750.5',
        'box_id': 3,
        'rate_per_hour': 1500,
        'recurring_group_id': 'abc',
      });
      expect(b.id, '42');
      expect(b.startTime, '07:00');
      expect(b.endTime, '09:30');
      expect(b.status, BookingStatus.pending);
      expect(b.amount, 3750.5);
      expect(b.boxId, '3');
      expect(b.ratePerHour, 1500);
      expect(b.hours, 2.5);
      expect(b.isRecurring, isTrue);
    });

    test('unknown status falls back to confirmed; missing rate is derived', () {
      final b = Booking.fromMap({
        'id': 1,
        'customer_name': 'A',
        'phone': '1',
        'booking_date': '2026-11-03',
        'start_time': '10:00',
        'end_time': '12:00',
        'status': 'weird',
        'amount': 3000,
        'box_id': 1,
      });
      expect(b.status, BookingStatus.confirmed);
      expect(b.ratePerHour, isNull);
      expect(b.effectiveRate, 1500);
      expect(b.isRecurring, isFalse);
    });

    test('draft serialises to the table columns', () {
      const d = BookingDraft(
        name: 'A',
        phone: '9876543210',
        date: '2026-11-03',
        startTime: '10:00',
        endTime: '12:00',
        boxId: '1',
        ratePerHour: 1500,
      );
      expect(d.amount, 3000);
      expect(d.toMap(), {
        'customer_name': 'A',
        'phone': '9876543210',
        'booking_date': '2026-11-03',
        'start_time': '10:00',
        'end_time': '12:00',
        'amount': 3000.0,
        'rate_per_hour': 1500.0,
        'status': 'confirmed',
        'box_id': '1',
      });
    });

    test('endsAt / startsAt combine date and time', () {
      final b = Booking.fromMap({
        'id': 1,
        'customer_name': 'A',
        'phone': '1',
        'booking_date': '2026-11-03',
        'start_time': '19:30',
        'end_time': '21:00',
        'status': 'confirmed',
        'amount': 0,
        'box_id': 1,
      });
      expect(b.startsAt, DateTime(2026, 11, 3, 19, 30));
      expect(b.endsAt, DateTime(2026, 11, 3, 21));
    });
  });

  test('Customer.fromMap tolerates nulls and flags VIPs', () {
    final c = Customer.fromMap({
      'id': 1,
      'name': 'A',
      'phone': '9',
      'notes': null,
      'cnt': null,
      'last': null,
    });
    expect(c.notes, '');
    expect(c.cnt, 0);
    expect(c.last, '-');
    expect(c.isVip, isFalse);
    expect(c.copyWith(cnt: 10).isVip, isTrue);
  });

  test('CricketBox.fromMap', () {
    final box = CricketBox.fromMap({'id': 2, 'name': 'Box B', 'active': true});
    expect((box.id, box.name, box.active), ('2', 'Box B', true));
    expect(
      CricketBox.fromMap({'id': 3, 'name': 'X', 'active': null}).active,
      isFalse,
    );
  });

  test('Expense.fromMap parses numeric strings', () {
    final e = Expense.fromMap({
      'id': 5,
      'title': 'Bulbs',
      'amount': '250.50',
      'category': 'Electricity',
      'note': null,
      'expense_date': '2026-11-03',
    });
    expect(e.amount, 250.5);
    expect(e.note, '');
  });

  group('RecurringGroup', () {
    test('fromMap reads the joined box name and weekday indexes', () {
      final g = RecurringGroup.fromMap({
        'id': 'g1',
        'customer_name': 'Kiran',
        'phone': '9',
        'box_id': 1,
        'boxes': {'name': 'Box A'},
        'days': [0, 3],
        'start_time': '19:00:00',
        'end_time': '21:00:00',
        'weeks': 4,
        'rate_per_hour': 1200,
        'created_at': '2026-11-01T10:00:00Z',
      });
      expect(g.boxName, 'Box A');
      expect(g.dayLabels, ['Sun', 'Wed']);
      expect(g.bookingCount, 8);
      expect(g.startTime, '19:00');
      expect(g.createdAt, isNotNull);
    });

    test('missing join falls back to "-"', () {
      final g = RecurringGroup.fromMap({
        'id': 1,
        'customer_name': 'A',
        'days': [],
        'weeks': 1,
      });
      expect(g.boxName, '-');
    });
  });

  test('AppNotification JSON round-trip', () {
    final n = AppNotification(
      id: 'x',
      title: 'T',
      message: 'M',
      type: NotificationType.conflict,
      createdAt: DateTime(2026, 11, 3, 10),
      read: true,
    );
    final back = AppNotification.fromJson(n.toJson());
    expect(
      (back.id, back.title, back.message, back.type, back.read),
      ('x', 'T', 'M', NotificationType.conflict, true),
    );
    expect(back.createdAt, n.createdAt);
  });
}

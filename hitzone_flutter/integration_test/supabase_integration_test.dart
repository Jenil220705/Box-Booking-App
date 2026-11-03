// Live Supabase integration tests.
//
// These talk to the REAL backend configured in AppConfig, so they are opt-in:
// they are skipped unless you pass credentials of a test/admin user:
//
//   flutter test integration_test/supabase_integration_test.dart \
//     --dart-define=TEST_EMAIL=you@example.com \
//     --dart-define=TEST_PASSWORD=secret \
//     -d <android-device-id>
//
// Everything the tests create is clearly named "ZZ-INTEGRATION-TEST", dated
// far in the future (2099) and deleted again at the end of each test.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/errors.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/expense.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';
import 'package:hitzone_flutter/repositories/booking_repository.dart';
import 'package:hitzone_flutter/repositories/box_repository.dart';
import 'package:hitzone_flutter/repositories/customer_repository.dart';
import 'package:hitzone_flutter/repositories/expense_repository.dart';
import 'package:hitzone_flutter/repositories/recurring_repository.dart';
import 'package:hitzone_flutter/services/auth_service.dart';
import 'package:hitzone_flutter/services/booking_service.dart';
import 'package:hitzone_flutter/services/realtime_service.dart';
import 'package:hitzone_flutter/services/supabase_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _testDate = '2099-01-05';
const _name = 'ZZ-INTEGRATION-TEST';
const _phone = '9000000099';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final hasCredentials = _email.isNotEmpty && _password.isNotEmpty;
  final skip = hasCredentials
      ? null
      : 'Pass --dart-define=TEST_EMAIL / TEST_PASSWORD to run live Supabase tests';

  late AuthService auth;
  late SupabaseBookingRepository bookings;
  late SupabaseCustomerRepository customers;
  late SupabaseBoxRepository boxes;
  late SupabaseExpenseRepository expenses;
  late SupabaseRecurringRepository recurring;
  late BookingService service;
  late String boxId;

  setUpAll(() async {
    if (!hasCredentials) return;
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.init();
    final db = SupabaseService.client;
    auth = AuthService(db);
    bookings = SupabaseBookingRepository(db);
    customers = SupabaseCustomerRepository(db);
    boxes = SupabaseBoxRepository(db);
    expenses = SupabaseExpenseRepository(db);
    recurring = SupabaseRecurringRepository(db);
    service = BookingService(
      bookings: bookings,
      customers: customers,
      recurring: recurring,
    );
    await auth.signIn(_email, _password);
    final all = await boxes.fetchAll();
    boxId = all.firstWhere((b) => b.active, orElse: () => all.first).id;
  });

  tearDownAll(() async {
    if (!hasCredentials) return;
    // Belt and braces: remove anything a failed test left behind.
    final leftovers = (await bookings.fetchAll()).where((b) => b.name == _name);
    for (final b in leftovers) {
      await bookings.delete(b.id);
    }
    final customer = await customers.findByPhone(_phone);
    if (customer != null) await customers.delete(customer.id);
  });

  group('auth & connectivity', () {
    test('signed in with a persisted session', () async {
      expect(auth.currentSession, isNotNull);
      expect(auth.currentUser?.email?.toLowerCase(), _email.toLowerCase());
    }, skip: skip);

    test('rejects a wrong password with a friendly message', () async {
      await expectLater(
        AuthService(SupabaseService.client)
            .signIn(_email, 'definitely-wrong-password'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password',
          ),
        ),
      );
      // Re-authenticate for the remaining tests.
      await auth.signIn(_email, _password);
    }, skip: skip);

    test('boxes load', () async {
      final all = await boxes.fetchAll();
      expect(all, isNotEmpty);
      expect(all.any((b) => b.active), isTrue);
    }, skip: skip);
  });

  group('bookings', () {
    test('create, read, edit, status change and delete', () async {
      final draft = BookingDraft(
        name: _name,
        phone: _phone,
        date: _testDate,
        startTime: '10:00',
        endTime: '12:00',
        boxId: boxId,
        ratePerHour: 100,
      );
      final created = (await service.createBooking(draft)).booking;
      addTearDown(() => bookings.delete(created.id).catchError((_) {}));

      expect(
        (await bookings.fetchAll()).any((b) => b.id == created.id),
        isTrue,
      );
      expect(created.amount, 200);

      final edited = (await service.updateBooking(
        created,
        BookingDraft(
          name: _name,
          phone: _phone,
          date: _testDate,
          startTime: '10:00',
          endTime: '13:00',
          boxId: boxId,
          ratePerHour: 100,
        ),
      )).booking;
      expect(edited.amount, 300);

      await service.changeStatus(edited, BookingStatus.cancelled);
      final refreshed = (await bookings.fetchAll()).firstWhere(
        (b) => b.id == created.id,
      );
      expect(refreshed.status, BookingStatus.cancelled);

      await service.deleteBooking(refreshed);
      expect(
        (await bookings.fetchAll()).any((b) => b.id == created.id),
        isFalse,
      );
    }, skip: skip);

    test(
      'overlapping booking on the same box is rejected, adjacent one allowed',
      () async {
        BookingDraft slot(String s, String e) => BookingDraft(
          name: _name,
          phone: _phone,
          date: _testDate,
          startTime: s,
          endTime: e,
          boxId: boxId,
          ratePerHour: 100,
        );
        final first = (await service.createBooking(slot('10:00', '12:00')))
            .booking;
        addTearDown(() => bookings.delete(first.id).catchError((_) {}));

        await expectLater(
          service.createBooking(slot('11:00', '13:00')),
          throwsA(isA<SlotConflictException>()),
        );
        final adjacent = (await service.createBooking(slot('12:00', '14:00')))
            .booking;
        addTearDown(() => bookings.delete(adjacent.id).catchError((_) {}));
        expect(adjacent.startTime, '12:00');
      },
      skip: skip,
    );
  });

  group('recurring', () {
    test('create generates bookings, delete removes them', () async {
      final outcome = await service.createRecurring(
        RecurringDraft(
          name: _name,
          phone: _phone,
          boxId: boxId,
          days: const [1, 3],
          startTime: '08:00',
          endTime: '09:00',
          weeks: 2,
          ratePerHour: 100,
          startDate: _testDate,
        ),
      );
      addTearDown(
        () => service.deleteRecurring(outcome.group).catchError((_) {}),
      );
      expect(outcome.bookings, hasLength(4));
      expect(
        (await recurring.fetchAll()).any((g) => g.id == outcome.group.id),
        isTrue,
      );

      await service.deleteRecurring(outcome.group);
      expect(
        (await recurring.fetchAll()).any((g) => g.id == outcome.group.id),
        isFalse,
      );
      expect(
        (await bookings.fetchAll()).where(
          (b) => b.recurringGroupId == outcome.group.id,
        ),
        isEmpty,
      );
    }, skip: skip);
  });

  group('customers & expenses', () {
    test('customer CRUD', () async {
      final created = await customers.insert(
        name: _name,
        phone: _phone,
        notes: 'temp',
      );
      addTearDown(() => customers.delete(created.id).catchError((_) {}));
      expect((await customers.findByPhone(_phone))?.id, created.id);
      await customers.update(
        created.id,
        name: '$_name 2',
        phone: _phone,
        notes: 'edited',
      );
      expect((await customers.findByPhone(_phone))?.name, '$_name 2');
      await customers.delete(created.id);
      expect(await customers.findByPhone(_phone), isNull);
    }, skip: skip);

    test('expense CRUD', () async {
      const draft = ExpenseDraft(
        title: _name,
        amount: 1,
        category: 'Other',
        note: 'temp',
      );
      final created = await expenses.insert(draft, _testDate);
      addTearDown(() => expenses.delete(created.id).catchError((_) {}));
      expect(
        (await expenses.fetchAll()).any((e) => e.id == created.id),
        isTrue,
      );
      await expenses.update(
        created.id,
        const ExpenseDraft(
          title: _name,
          amount: 2,
          category: 'Water',
          note: 'edited',
        ),
      );
      final updated = (await expenses.fetchAll()).firstWhere(
        (e) => e.id == created.id,
      );
      expect((updated.amount, updated.category), (2.0, 'Water'));
      await expenses.delete(created.id);
      expect(
        (await expenses.fetchAll()).any((e) => e.id == created.id),
        isFalse,
      );
    }, skip: skip);
  });

  group('realtime', () {
    test('a booking insert triggers the subscription callback', () async {
      final realtime = RealtimeService(SupabaseService.client);
      final gotEvent = Completer<void>();
      final subscribed = Completer<void>();
      realtime.start(
        onBookingsChanged: () {
          if (!gotEvent.isCompleted) gotEvent.complete();
        },
        onRecurringChanged: () {},
        onStatus: (s) {
          if (s.name == 'subscribed' && !subscribed.isCompleted) {
            subscribed.complete();
          }
        },
      );
      addTearDown(realtime.stop);
      await subscribed.future.timeout(const Duration(seconds: 15));

      final created = await bookings.insert(
        BookingDraft(
          name: _name,
          phone: _phone,
          date: _testDate,
          startTime: '20:00',
          endTime: '21:00',
          boxId: boxId,
          ratePerHour: 1,
        ),
      );
      addTearDown(() => bookings.delete(created.id).catchError((_) {}));
      await gotEvent.future.timeout(const Duration(seconds: 15));
    }, skip: skip);
  });
}

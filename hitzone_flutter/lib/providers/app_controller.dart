import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/errors.dart';
import '../core/utils/formatters.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/recurring_group.dart';
import '../services/booking_service.dart';
import 'core_providers.dart';
import 'data_providers.dart';
import 'notifications_provider.dart';
import 'settings_provider.dart';

/// Single entry point for every write operation. It runs the service call,
/// refreshes the affected providers (so the UI never shows stale data) and
/// raises the matching in-app notifications.
class AppController {
  AppController(this._ref);

  final Ref _ref;

  NotificationsNotifier get _notify =>
      _ref.read(notificationsProvider.notifier);
  bool get _detectConflicts => _ref.read(settingsProvider).conflictDetection;

  Future<void> _refreshBookingData() => Future.wait([
    _ref.read(bookingsProvider.notifier).refresh(silent: true),
    _ref.read(customersProvider.notifier).refresh(silent: true),
  ]);

  Future<T> _reportConflicts<T>(
    Future<T> Function() action, {
    required String what,
  }) async {
    try {
      return await action();
    } on SlotConflictException catch (e) {
      _notify.add(
        '⚠️ Conflict Detected',
        '$what: ${e.message}',
        NotificationType.conflict,
      );
      rethrow;
    }
  }

  // ------------------------------------------------------------------ bookings

  Future<BookingOutcome> createBooking(BookingDraft draft) async {
    final outcome = await _reportConflicts(
      () => _ref
          .read(bookingServiceProvider)
          .createBooking(draft, detectConflicts: _detectConflicts),
      what: draft.name,
    );
    _notify.add(
      'New Booking – ${draft.name}',
      '${fmtDate(draft.date)} ${t12(draft.startTime)}–${t12(draft.endTime)}',
      NotificationType.booking,
    );
    if (outcome.newCustomer) {
      _notify.add(
        'New Customer',
        '${draft.name} added',
        NotificationType.success,
      );
    }
    await _refreshBookingData();
    return outcome;
  }

  Future<BookingOutcome> updateBooking(
    Booking original,
    BookingDraft draft,
  ) async {
    final outcome = await _reportConflicts(
      () => _ref
          .read(bookingServiceProvider)
          .updateBooking(original, draft, detectConflicts: _detectConflicts),
      what: draft.name,
    );
    if (outcome.newCustomer) {
      _notify.add(
        'New Customer',
        '${draft.name} added',
        NotificationType.success,
      );
    }
    await _refreshBookingData();
    return outcome;
  }

  Future<void> deleteBooking(Booking booking) async {
    await _ref.read(bookingServiceProvider).deleteBooking(booking);
    await _refreshBookingData();
  }

  Future<void> changeStatus(Booking booking, BookingStatus status) async {
    await _ref.read(bookingServiceProvider).changeStatus(booking, status);
    await _refreshBookingData();
  }

  Future<Booking> reduceOneHour(Booking booking) async {
    final updated = await _ref
        .read(bookingServiceProvider)
        .reduceOneHour(booking);
    await _refreshBookingData();
    return updated;
  }

  // ----------------------------------------------------------------- recurring

  Future<RecurringOutcome> createRecurring(RecurringDraft draft) async {
    final outcome = await _reportConflicts(
      () => _ref
          .read(bookingServiceProvider)
          .createRecurring(draft, detectConflicts: _detectConflicts),
      what: '${draft.name} (recurring)',
    );
    final days = draft.days.map((d) => kDayNames[d % 7]).join('+');
    _notify.add(
      'Recurring Created',
      '${draft.name} · $days · ${draft.weeks} weeks · ${outcome.bookings.length} bookings',
      NotificationType.info,
    );
    if (outcome.newCustomer) {
      _notify.add(
        'New Customer',
        '${draft.name} added',
        NotificationType.success,
      );
    }
    await Future.wait([
      _ref.read(recurringProvider.notifier).refresh(silent: true),
      _refreshBookingData(),
    ]);
    return outcome;
  }

  Future<RecurringOutcome> updateRecurring(
    RecurringGroup group,
    RecurringDraft draft,
  ) async {
    final outcome = await _reportConflicts(
      () => _ref
          .read(bookingServiceProvider)
          .updateRecurring(group, draft, detectConflicts: _detectConflicts),
      what: '${draft.name} (recurring)',
    );
    await Future.wait([
      _ref.read(recurringProvider.notifier).refresh(silent: true),
      _refreshBookingData(),
    ]);
    return outcome;
  }

  Future<void> deleteRecurring(RecurringGroup group) async {
    await _ref.read(bookingServiceProvider).deleteRecurring(group);
    await Future.wait([
      _ref.read(recurringProvider.notifier).refresh(silent: true),
      _refreshBookingData(),
    ]);
  }

  // ----------------------------------------------------------------- customers

  Future<void> addCustomer({
    required String name,
    required String phone,
    String notes = '',
  }) async {
    await _ref
        .read(customerServiceProvider)
        .add(name: name, phone: phone, notes: notes);
    _notify.add('New Customer', '$name added', NotificationType.success);
    await _ref.read(customersProvider.notifier).refresh(silent: true);
  }

  Future<void> updateCustomer(
    Customer customer, {
    required String name,
    required String phone,
    String notes = '',
  }) async {
    await _ref
        .read(customerServiceProvider)
        .update(customer, name: name, phone: phone, notes: notes);
    await _ref.read(customersProvider.notifier).refresh(silent: true);
  }

  Future<void> deleteCustomer(Customer customer) async {
    await _ref.read(customerServiceProvider).delete(customer);
    await _ref.read(customersProvider.notifier).refresh(silent: true);
  }

  // ------------------------------------------------------------------ expenses

  static ExpenseDraft _validatedExpense(
    String title,
    String amountText,
    String category,
    String note,
  ) {
    final amount = double.tryParse(amountText.trim());
    if (title.trim().isEmpty || amount == null) {
      throw const ValidationException('Enter an expense name and amount');
    }
    if (amount <= 0) {
      throw const ValidationException('Amount must be greater than zero');
    }
    return ExpenseDraft(
      title: title.trim(),
      amount: amount,
      category: category,
      note: note.trim(),
    );
  }

  Future<void> addExpense({
    required String title,
    required String amount,
    required String category,
    String note = '',
  }) async {
    final draft = _validatedExpense(title, amount, category, note);
    await _ref.read(expenseRepositoryProvider).insert(draft, todayKey());
    await _ref.read(expensesProvider.notifier).refresh(silent: true);
  }

  Future<void> updateExpense(
    String id, {
    required String title,
    required String amount,
    required String category,
    String note = '',
  }) async {
    final draft = _validatedExpense(title, amount, category, note);
    await _ref.read(expenseRepositoryProvider).update(id, draft);
    await _ref.read(expensesProvider.notifier).refresh(silent: true);
  }

  Future<void> deleteExpense(Expense expense) async {
    await _ref.read(expenseRepositoryProvider).delete(expense.id);
    await _ref.read(expensesProvider.notifier).refresh(silent: true);
  }

  // --------------------------------------------------------------------- boxes

  /// Brings the number of active boxes to [target]: re-enables inactive boxes
  /// first, creates new ones if needed, or disables the last active boxes.
  /// Returns a short description of what changed.
  Future<String> setActiveBoxCount(int target) async {
    if (target < 1) {
      throw const ValidationException('At least one box is required');
    }
    final repo = _ref.read(boxRepositoryProvider);
    final all = await repo.fetchAll();
    final active = all.where((b) => b.active).toList();

    if (target == active.length) {
      throw const ValidationException('No changes detected');
    }

    String message;
    if (target > active.length) {
      final need = target - active.length;
      final revive = all.where((b) => !b.active).take(need).toList();
      if (revive.isNotEmpty) {
        await repo.setActive(revive.map((b) => b.id).toList(), true);
      }
      final toCreate = need - revive.length;
      if (toCreate > 0) {
        await repo.insertActive([
          for (var i = 0; i < toCreate; i++) 'Box ${all.length + i + 1}',
        ]);
      }
      message = '$need box${need == 1 ? '' : 'es'} enabled';
    } else {
      final extra = active.sublist(target);
      await repo.setActive(extra.map((b) => b.id).toList(), false);
      message = '${extra.length} box${extra.length == 1 ? '' : 'es'} disabled';
    }
    await _ref.read(boxesProvider.notifier).refresh(silent: true);
    return message;
  }

  Future<void> setBoxActive(String id, bool active) async {
    await _ref.read(boxRepositoryProvider).setActive([id], active);
    await _ref.read(boxesProvider.notifier).refresh(silent: true);
  }

  Future<void> addBox(String name) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Box name cannot be empty');
    }
    await _ref.read(boxRepositoryProvider).insertActive([name.trim()]);
    await _ref.read(boxesProvider.notifier).refresh(silent: true);
  }

  Future<void> renameBox(String id, String name) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Box name cannot be empty');
    }
    await _ref.read(boxRepositoryProvider).rename(id, name.trim());
    await _ref.read(boxesProvider.notifier).refresh(silent: true);
  }
}

final appControllerProvider = Provider<AppController>(
  (ref) => AppController(ref),
);

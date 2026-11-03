import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/analytics.dart';
import '../models/booking.dart';
import '../models/box.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/recurring_group.dart';
import 'core_providers.dart';

/// Base for list-backed async state with a "silent" refresh that keeps the old
/// data on screen while reloading (used by realtime updates).
abstract class ListNotifier<T> extends AsyncNotifier<List<T>> {
  Future<List<T>> load();

  @override
  Future<List<T>> build() => load();

  /// Reloads from Supabase. With [silent] a failure keeps the previous data;
  /// otherwise the error is rethrown so pull-to-refresh can show it.
  Future<void> refresh({bool silent = false}) async {
    final next = await AsyncValue.guard(load);
    if (!ref.mounted) return;
    if (next.hasError && state.hasValue) {
      if (silent) return;
      Error.throwWithStackTrace(next.error!, next.stackTrace!);
    }
    state = next;
  }
}

class BookingsNotifier extends ListNotifier<Booking> {
  @override
  Future<List<Booking>> load() async {
    final repo = ref.read(bookingRepositoryProvider);
    var list = await repo.fetchAll();

    // Confirmed bookings whose end time has passed become "completed".
    final elapsed = BookingRules.elapsedConfirmed(list, DateTime.now());
    if (elapsed.isNotEmpty) {
      try {
        await repo.markCompleted(elapsed.map((b) => b.id).toList());
        final ids = elapsed.map((b) => b.id).toSet();
        list = [
          for (final b in list)
            ids.contains(b.id)
                ? b.copyWith(status: BookingStatus.completed)
                : b,
        ];
      } catch (e) {
        debugPrint('Auto-complete failed: $e');
      }
    }
    return list;
  }
}

class CustomersNotifier extends ListNotifier<Customer> {
  @override
  Future<List<Customer>> load() =>
      ref.read(customerRepositoryProvider).fetchAll();
}

class BoxesNotifier extends ListNotifier<CricketBox> {
  @override
  Future<List<CricketBox>> load() => ref.read(boxRepositoryProvider).fetchAll();
}

class ExpensesNotifier extends ListNotifier<Expense> {
  @override
  Future<List<Expense>> load() =>
      ref.read(expenseRepositoryProvider).fetchAll();
}

class RecurringNotifier extends ListNotifier<RecurringGroup> {
  @override
  Future<List<RecurringGroup>> load() =>
      ref.read(recurringRepositoryProvider).fetchAll();
}

final bookingsProvider = AsyncNotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
      CustomersNotifier.new,
    );
final boxesProvider = AsyncNotifierProvider<BoxesNotifier, List<CricketBox>>(
  BoxesNotifier.new,
);
final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);
final recurringProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringGroup>>(
      RecurringNotifier.new,
    );

/// Boxes that can currently be booked.
final activeBoxesProvider = Provider<List<CricketBox>>((ref) {
  final boxes = ref.watch(boxesProvider).value ?? const <CricketBox>[];
  return boxes.where((b) => b.active).toList();
});

/// Resolves a box id to its name ("-" when unknown).
final boxNameResolverProvider = Provider<String Function(String)>((ref) {
  final boxes = ref.watch(boxesProvider).value ?? const <CricketBox>[];
  return (id) {
    for (final b in boxes) {
      if (b.id == id) return b.name;
    }
    return '-';
  };
});

/// Customers with `activeCount` derived from the bookings in the database.
final customersWithStatsProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customers = ref.watch(customersProvider);
  final bookings = ref.watch(bookingsProvider).value ?? const <Booking>[];
  return customers.whenData((list) {
    final counts = <String, int>{};
    for (final b in bookings) {
      counts[b.phone] = (counts[b.phone] ?? 0) + 1;
    }
    return [
      for (final c in list) c.copyWith(activeCount: counts[c.phone] ?? 0),
    ];
  });
});

/// Reload everything (pull-to-refresh on the dashboard, retry buttons).
Future<void> refreshAllData(WidgetRef ref) async {
  await Future.wait([
    ref.read(bookingsProvider.notifier).refresh(),
    ref.read(customersProvider.notifier).refresh(),
    ref.read(boxesProvider.notifier).refresh(),
    ref.read(expensesProvider.notifier).refresh(),
    ref.read(recurringProvider.notifier).refresh(),
  ]);
}

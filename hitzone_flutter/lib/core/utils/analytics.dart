import '../../models/booking.dart';
import '../../models/expense.dart';
import 'formatters.dart';

/// Inclusive date range of `yyyy-MM-dd` keys (lexicographic compare is safe).
class DateRange {
  const DateRange(this.from, this.to);

  final String from;
  final String to;

  bool contains(String date) =>
      date.compareTo(from) >= 0 && date.compareTo(to) <= 0;

  int get days => parseDateKey(to).difference(parseDateKey(from)).inDays + 1;

  static DateRange month(DateTime now) => DateRange(
    dateKey(DateTime(now.year, now.month, 1)),
    dateKey(DateTime(now.year, now.month + 1, 0)),
  );

  /// Sunday to Saturday week containing [now].
  static DateRange week(DateTime now) {
    final sunday = DateTime(now.year, now.month, now.day - (now.weekday % 7));
    return DateRange(
      dateKey(sunday),
      dateKey(DateTime(sunday.year, sunday.month, sunday.day + 6)),
    );
  }

  static DateRange today(DateTime now) => DateRange(dateKey(now), dateKey(now));
}

class DailyPoint {
  const DailyPoint(this.date, this.value);
  final String date;
  final double value;
}

class Analytics {
  const Analytics._();

  static List<Booking> active(Iterable<Booking> bookings) =>
      bookings.where((b) => !b.isCancelled).toList();

  static double revenue(Iterable<Booking> bookings) =>
      bookings.where((b) => !b.isCancelled).fold(0.0, (s, b) => s + b.amount);

  static double totalExpenses(Iterable<Expense> expenses) =>
      expenses.fold(0.0, (s, e) => s + e.amount);

  static List<Booking> inRange(Iterable<Booking> bookings, DateRange? range) =>
      range == null
      ? bookings.toList()
      : bookings.where((b) => range.contains(b.date)).toList();

  static List<Expense> expensesInRange(
    Iterable<Expense> expenses,
    DateRange range,
  ) => expenses.where((e) => range.contains(e.expenseDate)).toList();

  /// Start hour -> number of bookings starting in that hour.
  static Map<int, int> startHourCounts(Iterable<Booking> bookings) {
    final counts = <int, int>{};
    for (final b in bookings) {
      final h = b.startMinutes ~/ 60;
      counts[h] = (counts[h] ?? 0) + 1;
    }
    return counts;
  }

  /// Busiest start hour, or `null` when there are no bookings.
  static int? peakHour(Iterable<Booking> bookings) {
    final counts = startHourCounts(bookings);
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    return entries.first.key;
  }

  /// Booked hours as a share of the hours the grounds are open.
  static double occupancyPercent({
    required Iterable<Booking> bookings,
    required int days,
    required int openMinutesPerDay,
    required int boxCount,
  }) {
    final capacity =
        days * (openMinutesPerDay / 60) * (boxCount < 1 ? 1 : boxCount);
    if (capacity <= 0) return 0;
    final booked = bookings
        .where((b) => !b.isCancelled)
        .fold(0.0, (s, b) => s + (b.endMinutes - b.startMinutes) / 60);
    return (booked / capacity * 100).clamp(0, 100).toDouble();
  }

  /// One point per day of [range] (zero when nothing was booked).
  static List<DailyPoint> dailyRevenue(
    Iterable<Booking> bookings,
    DateRange range,
  ) {
    final byDate = <String, double>{};
    for (final b in bookings) {
      if (b.isCancelled || !range.contains(b.date)) continue;
      byDate[b.date] = (byDate[b.date] ?? 0) + b.amount;
    }
    final start = parseDateKey(range.from);
    return List.generate(range.days, (i) {
      final key = dateKey(DateTime(start.year, start.month, start.day + i));
      return DailyPoint(key, byDate[key] ?? 0);
    });
  }

  static Map<BookingStatus, int> statusCounts(Iterable<Booking> bookings) {
    final counts = {for (final s in BookingStatus.values) s: 0};
    for (final b in bookings) {
      counts[b.status] = counts[b.status]! + 1;
    }
    return counts;
  }

  /// Phone -> (bookings, revenue) for non-cancelled bookings.
  static Map<String, ({int bookings, double revenue, String name})>
  customerTotals(Iterable<Booking> bookings) {
    final totals = <String, ({int bookings, double revenue, String name})>{};
    for (final b in bookings) {
      if (b.isCancelled) continue;
      final prev = totals[b.phone];
      totals[b.phone] = (
        bookings: (prev?.bookings ?? 0) + 1,
        revenue: (prev?.revenue ?? 0) + b.amount,
        name: b.name,
      );
    }
    return totals;
  }

  static Map<String, double> expensesByCategory(Iterable<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  /// `HH:mm` -> `"HH:mm"` window label for [hour] and the following [span] hours.
  static String hourWindowLabel(int hour, {int span = 2}) =>
      '${t12('${hour.toString().padLeft(2, '0')}:00')} – ${t12('${((hour + span) % 24).toString().padLeft(2, '0')}:00')}';
}

/// Rules that decide when stored bookings change state on their own.
class BookingRules {
  const BookingRules._();

  /// Confirmed bookings that already ended -> should be marked completed.
  static List<Booking> elapsedConfirmed(
    Iterable<Booking> bookings,
    DateTime now,
  ) => bookings
      .where(
        (b) => b.status == BookingStatus.confirmed && b.endsAt.isBefore(now),
      )
      .toList();
}

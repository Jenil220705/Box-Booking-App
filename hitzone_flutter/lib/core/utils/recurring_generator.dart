import 'formatters.dart';

/// Generates the booking dates of a weekly recurring group.
///
/// Same rules as the web app: for each week `w` (0-based) and each selected
/// weekday, the date is the first occurrence of that weekday on/after
/// [startDate], plus `w * 7` days. Order is week-major, then the order in
/// which the weekdays were selected. Weekdays use 0 = Sunday.
class RecurringGenerator {
  const RecurringGenerator._();

  static List<String> generate({
    required String startDate,
    required List<int> days,
    required int weeks,
  }) {
    final start = parseDateKey(startDate);
    final startWeekday = start.weekday % 7; // Mon=1..Sun=7 -> Sun=0
    final uniqueDays = <int>[];
    for (final d in days) {
      if (!uniqueDays.contains(d)) uniqueDays.add(d);
    }

    final dates = <String>[];
    for (var w = 0; w < weeks; w++) {
      for (final day in uniqueDays) {
        final diff = (day - startWeekday + 7) % 7;
        // DateTime normalises overflowing days, and avoids UTC conversions.
        dates.add(
          dateKey(DateTime(start.year, start.month, start.day + diff + w * 7)),
        );
      }
    }
    return dates;
  }
}

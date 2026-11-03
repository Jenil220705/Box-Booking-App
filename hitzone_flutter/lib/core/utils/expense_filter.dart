import '../../models/expense.dart';
import 'analytics.dart';
import 'formatters.dart';

enum ExpenseDateFilter {
  all('All'),
  today('Today'),
  week('This Week'),
  month('This Month'),
  custom('Custom Range');

  const ExpenseDateFilter(this.label);
  final String label;
}

/// Date + category filtering for the expense list.
///
/// A custom range only applies once both ends are chosen. (The web app's
/// if/else chain skipped the week and month filters whenever "custom" had been
/// evaluated first; each filter is independent here.)
List<Expense> filterExpenses(
  Iterable<Expense> expenses, {
  required ExpenseDateFilter dateFilter,
  required DateTime now,
  String from = '',
  String to = '',
  String? category,
}) {
  final DateRange? range = switch (dateFilter) {
    ExpenseDateFilter.all => null,
    ExpenseDateFilter.today => DateRange.today(now),
    ExpenseDateFilter.week => DateRange.week(now),
    ExpenseDateFilter.month => DateRange.month(now),
    ExpenseDateFilter.custom =>
      (from.isNotEmpty && to.isNotEmpty) ? DateRange(from, to) : null,
  };

  return expenses.where((e) {
    if (range != null && !range.contains(e.expenseDate)) return false;
    if (category != null && e.category != category) return false;
    return true;
  }).toList();
}

double categoryTotal(Iterable<Expense> expenses, String category) => expenses
    .where((e) => e.category == category)
    .fold(0.0, (s, e) => s + e.amount);

/// Category with the highest total, or `null` when there are no expenses.
String? topCategory(Iterable<Expense> expenses) {
  final totals = Analytics.expensesByCategory(expenses);
  if (totals.isEmpty) return null;
  return (totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;
}

String formatAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String expenseDateLabel(Expense e) => fmtDate(e.expenseDate);

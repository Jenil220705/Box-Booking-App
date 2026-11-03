import '../core/utils/formatters.dart';

/// A row of the Supabase `expenses` table.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.note,
    required this.expenseDate,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final String note;

  /// `yyyy-MM-dd`
  final String expenseDate;

  factory Expense.fromMap(Map<String, dynamic> m) {
    return Expense(
      id: m['id'].toString(),
      title: (m['title'] ?? '') as String,
      amount: toDouble(m['amount']),
      category: (m['category'] ?? 'Other') as String,
      note: (m['note'] ?? '') as String,
      expenseDate: (m['expense_date'] ?? '').toString(),
    );
  }
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    required this.category,
    this.note = '',
  });

  final String title;
  final double amount;
  final String category;
  final String note;

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'category': category,
    'note': note,
  };
}

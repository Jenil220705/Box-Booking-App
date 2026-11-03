import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';
import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> fetchAll();
  Future<Expense> insert(ExpenseDraft draft, String expenseDate);
  Future<void> update(String id, ExpenseDraft draft);
  Future<void> delete(String id);
}

class SupabaseExpenseRepository implements ExpenseRepository {
  SupabaseExpenseRepository(this._db);

  final SupabaseClient _db;
  static const _table = 'expenses';

  @override
  Future<List<Expense>> fetchAll() => guardSupabase(() async {
    final rows = await _db.from(_table).select().order('id', ascending: true);
    return rows.map(Expense.fromMap).toList();
  });

  @override
  Future<Expense> insert(ExpenseDraft draft, String expenseDate) =>
      guardSupabase(() async {
        final row = await _db
            .from(_table)
            .insert({...draft.toMap(), 'expense_date': expenseDate})
            .select()
            .single();
        return Expense.fromMap(row);
      });

  @override
  Future<void> update(String id, ExpenseDraft draft) => guardSupabase(() async {
    final rows = await _db
        .from(_table)
        .update(draft.toMap())
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      throw const AppException(
        'Expense not found or you do not have permission to edit it.',
      );
    }
  });

  @override
  Future<void> delete(String id) => guardSupabase(() async {
    final rows = await _db.from(_table).delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException(
        'Expense not found or you do not have permission to delete it.',
      );
    }
  });
}

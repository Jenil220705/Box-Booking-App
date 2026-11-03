import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';
import '../models/recurring_group.dart';

abstract class RecurringRepository {
  Future<List<RecurringGroup>> fetchAll();
  Future<RecurringGroup> insert(RecurringDraft draft);
  Future<void> update(String id, RecurringDraft draft);
  Future<void> delete(String id);
}

class SupabaseRecurringRepository implements RecurringRepository {
  SupabaseRecurringRepository(this._db);

  final SupabaseClient _db;
  static const _table = 'recurring_groups';

  @override
  Future<List<RecurringGroup>> fetchAll() => guardSupabase(() async {
    final rows = await _db.from(_table).select('*, boxes(name)');
    return rows.map(RecurringGroup.fromMap).toList();
  });

  @override
  Future<RecurringGroup> insert(RecurringDraft draft) =>
      guardSupabase(() async {
        final row = await _db
            .from(_table)
            .insert(draft.toGroupMap())
            .select('*, boxes(name)')
            .single();
        return RecurringGroup.fromMap(row);
      });

  @override
  Future<void> update(String id, RecurringDraft draft) => guardSupabase(
    () async {
      final rows = await _db
          .from(_table)
          .update(draft.toGroupMap())
          .eq('id', id)
          .select();
      if (rows.isEmpty) {
        throw const AppException(
          'Recurring group not found or you do not have permission to edit it.',
        );
      }
    },
  );

  @override
  Future<void> delete(String id) => guardSupabase(() async {
    final rows = await _db.from(_table).delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException(
        'Recurring group not found or you do not have permission to delete it.',
      );
    }
  });
}

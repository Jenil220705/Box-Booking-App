import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';
import '../models/box.dart';

abstract class BoxRepository {
  Future<List<CricketBox>> fetchAll();
  Future<void> setActive(List<String> ids, bool active);
  Future<void> insertActive(List<String> names);
  Future<void> rename(String id, String name);
}

class SupabaseBoxRepository implements BoxRepository {
  SupabaseBoxRepository(this._db);

  final SupabaseClient _db;
  static const _table = 'boxes';

  @override
  Future<List<CricketBox>> fetchAll() => guardSupabase(() async {
    final rows = await _db.from(_table).select().order('id', ascending: true);
    return rows.map(CricketBox.fromMap).toList();
  });

  @override
  Future<void> setActive(List<String> ids, bool active) =>
      guardSupabase(() async {
        if (ids.isEmpty) return;
        final rows = await _db
            .from(_table)
            .update({'active': active})
            .inFilter('id', ids)
            .select();
        if (rows.isEmpty) {
          throw const AppException(
            'Boxes could not be updated (permission denied?).',
          );
        }
      });

  @override
  Future<void> insertActive(List<String> names) => guardSupabase(() async {
    if (names.isEmpty) return;
    await _db.from(_table).insert([
      for (final n in names) {'name': n, 'active': true},
    ]);
  });

  @override
  Future<void> rename(String id, String name) => guardSupabase(() async {
    final rows = await _db
        .from(_table)
        .update({'name': name})
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      throw const AppException(
        'Box could not be renamed (permission denied?).',
      );
    }
  });
}

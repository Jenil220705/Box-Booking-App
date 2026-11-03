import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';
import '../models/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> fetchAll();
  Future<Customer?> findByPhone(String phone);
  Future<Customer> insert({
    required String name,
    required String phone,
    String notes = '',
    int cnt = 0,
    String last = '-',
  });
  Future<void> update(
    String id, {
    required String name,
    required String phone,
    required String notes,
  });
  Future<void> updateCounter(String id, {required int cnt, String? last});
  Future<void> delete(String id);
}

class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this._db);

  final SupabaseClient _db;
  static const _table = 'customers';

  @override
  Future<List<Customer>> fetchAll() => guardSupabase(() async {
    final rows = await _db.from(_table).select();
    return rows.map(Customer.fromMap).toList();
  });

  @override
  Future<Customer?> findByPhone(String phone) => guardSupabase(() async {
    final row = await _db
        .from(_table)
        .select()
        .eq('phone', phone)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Customer.fromMap(row);
  });

  @override
  Future<Customer> insert({
    required String name,
    required String phone,
    String notes = '',
    int cnt = 0,
    String last = '-',
  }) => guardSupabase(() async {
    final row = await _db
        .from(_table)
        .insert({
          'name': name,
          'phone': phone,
          'notes': notes,
          'cnt': cnt,
          'last': last,
        })
        .select()
        .single();
    return Customer.fromMap(row);
  });

  @override
  Future<void> update(
    String id, {
    required String name,
    required String phone,
    required String notes,
  }) => guardSupabase(() async {
    final rows = await _db
        .from(_table)
        .update({'name': name, 'phone': phone, 'notes': notes})
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      throw const AppException(
        'Customer not found or you do not have permission to edit it.',
      );
    }
  });

  @override
  Future<void> updateCounter(String id, {required int cnt, String? last}) =>
      guardSupabase(() async {
        await _db.from(_table).update({'cnt': cnt, 'last': ?last}).eq('id', id);
      });

  @override
  Future<void> delete(String id) => guardSupabase(() async {
    final rows = await _db.from(_table).delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException(
        'Customer not found or you do not have permission to delete it.',
      );
    }
  });
}

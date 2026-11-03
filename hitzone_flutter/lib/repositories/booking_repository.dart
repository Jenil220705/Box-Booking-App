import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';
import '../models/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> fetchAll();

  /// Fresh (non-cached) bookings of one box on the given dates – used for the
  /// authoritative conflict check right before writing.
  Future<List<Booking>> fetchForBoxOnDates(String boxId, List<String> dates);

  Future<Booking> insert(BookingDraft draft);
  Future<List<Booking>> insertMany(List<BookingDraft> drafts);
  Future<Booking> update(String id, BookingDraft draft);
  Future<void> updateStatus(String id, BookingStatus status);
  Future<void> updateEndTime(String id, String endTime, double amount);
  Future<void> markCompleted(List<String> ids);
  Future<void> delete(String id);
  Future<void> deleteByGroup(String groupId);
  Future<int> countByPhone(String phone);
}

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this._db);

  final SupabaseClient _db;
  static const _table = 'bookings';

  @override
  Future<List<Booking>> fetchAll() => guardSupabase(() async {
    final rows = await _db.from(_table).select();
    return rows.map(Booking.fromMap).toList();
  });

  @override
  Future<List<Booking>> fetchForBoxOnDates(String boxId, List<String> dates) =>
      guardSupabase(() async {
        if (dates.isEmpty) return <Booking>[];
        final rows = await _db
            .from(_table)
            .select()
            .eq('box_id', boxId)
            .inFilter('booking_date', dates);
        return rows.map(Booking.fromMap).toList();
      });

  @override
  Future<Booking> insert(BookingDraft draft) => guardSupabase(() async {
    final row = await _db.from(_table).insert(draft.toMap()).select().single();
    return Booking.fromMap(row);
  });

  @override
  Future<List<Booking>> insertMany(List<BookingDraft> drafts) =>
      guardSupabase(() async {
        final rows = await _db
            .from(_table)
            .insert(drafts.map((d) => d.toMap()).toList())
            .select();
        return rows.map(Booking.fromMap).toList();
      });

  @override
  Future<Booking> update(String id, BookingDraft draft) =>
      guardSupabase(() async {
        final rows = await _db
            .from(_table)
            .update(draft.toMap())
            .eq('id', id)
            .select();
        if (rows.isEmpty) {
          throw const AppException(
            'Booking not found or you do not have permission to edit it.',
          );
        }
        return Booking.fromMap(rows.first);
      });

  @override
  Future<void> updateStatus(String id, BookingStatus status) =>
      guardSupabase(() async {
        final rows = await _db
            .from(_table)
            .update({'status': status.name})
            .eq('id', id)
            .select();
        if (rows.isEmpty) {
          throw const AppException(
            'Booking not found or you do not have permission to edit it.',
          );
        }
      });

  @override
  Future<void> updateEndTime(String id, String endTime, double amount) =>
      guardSupabase(() async {
        final rows = await _db
            .from(_table)
            .update({'end_time': endTime, 'amount': amount})
            .eq('id', id)
            .select();
        if (rows.isEmpty) {
          throw const AppException(
            'Booking not found or you do not have permission to edit it.',
          );
        }
      });

  @override
  Future<void> markCompleted(List<String> ids) => guardSupabase(() async {
    if (ids.isEmpty) return;
    await _db
        .from(_table)
        .update({'status': BookingStatus.completed.name})
        .inFilter('id', ids);
  });

  @override
  Future<void> delete(String id) => guardSupabase(() async {
    final rows = await _db.from(_table).delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException(
        'Booking not found or you do not have permission to delete it.',
      );
    }
  });

  @override
  Future<void> deleteByGroup(String groupId) => guardSupabase(() async {
    await _db.from(_table).delete().eq('recurring_group_id', groupId);
  });

  @override
  Future<int> countByPhone(String phone) => guardSupabase(() async {
    final rows = await _db.from(_table).select('id').eq('phone', phone);
    return rows.length;
  });
}

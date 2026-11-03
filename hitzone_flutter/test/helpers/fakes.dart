import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/customer.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';
import 'package:hitzone_flutter/repositories/booking_repository.dart';
import 'package:hitzone_flutter/repositories/customer_repository.dart';
import 'package:hitzone_flutter/repositories/recurring_repository.dart';

/// In-memory stand-ins for the Supabase repositories.
class FakeBookingRepository implements BookingRepository {
  final List<Booking> rows = [];
  int _nextId = 1;
  bool failInsertMany = false;

  Booking _fromDraft(BookingDraft d, {String? id}) => Booking(
    id: id ?? '${_nextId++}',
    name: d.name,
    phone: d.phone,
    date: d.date,
    startTime: d.startTime,
    endTime: d.endTime,
    status: d.status,
    amount: d.amount,
    boxId: d.boxId,
    ratePerHour: d.ratePerHour,
    recurringGroupId: d.recurringGroupId,
  );

  /// Seeds an existing booking directly (bypassing the service).
  Booking seed({
    String name = 'Seed',
    String phone = '9000000000',
    String date = '2026-11-10',
    String start = '10:00',
    String end = '12:00',
    String box = '1',
    BookingStatus status = BookingStatus.confirmed,
    double rate = 1500,
    String? groupId,
  }) {
    final b = _fromDraft(
      BookingDraft(
        name: name,
        phone: phone,
        date: date,
        startTime: start,
        endTime: end,
        boxId: box,
        ratePerHour: rate,
        status: status,
        recurringGroupId: groupId,
      ),
    );
    rows.add(b);
    return b;
  }

  @override
  Future<List<Booking>> fetchAll() async => List.of(rows);

  @override
  Future<List<Booking>> fetchForBoxOnDates(
    String boxId,
    List<String> dates,
  ) async =>
      rows.where((b) => b.boxId == boxId && dates.contains(b.date)).toList();

  @override
  Future<Booking> insert(BookingDraft draft) async {
    final b = _fromDraft(draft);
    rows.add(b);
    return b;
  }

  @override
  Future<List<Booking>> insertMany(List<BookingDraft> drafts) async {
    if (failInsertMany) throw Exception('insert rejected');
    final created = drafts.map(_fromDraft).toList();
    rows.addAll(created);
    return created;
  }

  @override
  Future<Booking> update(String id, BookingDraft draft) async {
    final i = rows.indexWhere((b) => b.id == id);
    final updated = _fromDraft(draft, id: id);
    rows[i] = updated;
    return updated;
  }

  @override
  Future<void> updateStatus(String id, BookingStatus status) async {
    final i = rows.indexWhere((b) => b.id == id);
    rows[i] = rows[i].copyWith(status: status);
  }

  @override
  Future<void> updateEndTime(String id, String endTime, double amount) async {
    final i = rows.indexWhere((b) => b.id == id);
    rows[i] = rows[i].copyWith(endTime: endTime, amount: amount);
  }

  @override
  Future<void> markCompleted(List<String> ids) async {
    for (final id in ids) {
      await updateStatus(id, BookingStatus.completed);
    }
  }

  @override
  Future<void> delete(String id) async => rows.removeWhere((b) => b.id == id);

  @override
  Future<void> deleteByGroup(String groupId) async =>
      rows.removeWhere((b) => b.recurringGroupId == groupId);

  @override
  Future<int> countByPhone(String phone) async =>
      rows.where((b) => b.phone == phone).length;
}

class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> rows = [];
  int _nextId = 1;

  Customer seed({
    String name = 'Seed',
    String phone = '9000000000',
    int cnt = 0,
  }) {
    final c = Customer(id: '${_nextId++}', name: name, phone: phone, cnt: cnt);
    rows.add(c);
    return c;
  }

  Customer? byPhone(String phone) {
    for (final c in rows) {
      if (c.phone == phone) return c;
    }
    return null;
  }

  @override
  Future<List<Customer>> fetchAll() async => List.of(rows);

  @override
  Future<Customer?> findByPhone(String phone) async => byPhone(phone);

  @override
  Future<Customer> insert({
    required String name,
    required String phone,
    String notes = '',
    int cnt = 0,
    String last = '-',
  }) async {
    final c = Customer(
      id: '${_nextId++}',
      name: name,
      phone: phone,
      notes: notes,
      cnt: cnt,
      last: last,
    );
    rows.add(c);
    return c;
  }

  @override
  Future<void> update(
    String id, {
    required String name,
    required String phone,
    required String notes,
  }) async {
    final i = rows.indexWhere((c) => c.id == id);
    rows[i] = rows[i].copyWith(name: name, phone: phone, notes: notes);
  }

  @override
  Future<void> updateCounter(
    String id, {
    required int cnt,
    String? last,
  }) async {
    final i = rows.indexWhere((c) => c.id == id);
    rows[i] = rows[i].copyWith(cnt: cnt, last: last);
  }

  @override
  Future<void> delete(String id) async => rows.removeWhere((c) => c.id == id);
}

class FakeRecurringRepository implements RecurringRepository {
  final List<RecurringGroup> rows = [];
  int _nextId = 1;

  RecurringGroup _fromDraft(RecurringDraft d, String id) => RecurringGroup(
    id: id,
    name: d.name,
    phone: d.phone,
    boxId: d.boxId,
    boxName: 'Box ${d.boxId}',
    days: d.days,
    startTime: d.startTime,
    endTime: d.endTime,
    weeks: d.weeks,
    ratePerHour: d.ratePerHour,
  );

  @override
  Future<List<RecurringGroup>> fetchAll() async => List.of(rows);

  @override
  Future<RecurringGroup> insert(RecurringDraft draft) async {
    final g = _fromDraft(draft, 'g${_nextId++}');
    rows.add(g);
    return g;
  }

  @override
  Future<void> update(String id, RecurringDraft draft) async {
    final i = rows.indexWhere((g) => g.id == id);
    rows[i] = _fromDraft(draft, id);
  }

  @override
  Future<void> delete(String id) async => rows.removeWhere((g) => g.id == id);
}

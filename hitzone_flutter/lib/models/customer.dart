import '../core/utils/formatters.dart';

/// A row of the Supabase `customers` table.
///
/// [cnt] is the lifetime booking counter stored in the table; [activeCount]
/// is derived on the client from the bookings currently in the database (as
/// the web app did).
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.notes = '',
    this.cnt = 0,
    this.last = '-',
    this.activeCount = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String notes;
  final int cnt;
  final String last;
  final int activeCount;

  factory Customer.fromMap(Map<String, dynamic> m) {
    return Customer(
      id: m['id'].toString(),
      name: (m['name'] ?? '') as String,
      phone: (m['phone'] ?? '').toString(),
      notes: (m['notes'] ?? '') as String,
      cnt: toInt(m['cnt']),
      last: (m['last'] ?? '-').toString(),
    );
  }

  bool get isVip => cnt >= 10;

  Customer copyWith({
    String? name,
    String? phone,
    String? notes,
    int? cnt,
    String? last,
    int? activeCount,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      cnt: cnt ?? this.cnt,
      last: last ?? this.last,
      activeCount: activeCount ?? this.activeCount,
    );
  }
}
